import { prisma } from '../prisma';
import { affiliateService } from './affiliateService';

export interface EvaluatedTask {
  id: string;
  levelId: string;
  taskNumber: number;
  title: string;
  description: string;
  taskType: string;
  rewardAmount: number;
  creditPoints: number;
  isPaid: boolean;
  unlockFee: number;
  requiresAdminApproval: boolean;
  status: string; // Task entity status (ACTIVE, DISABLED)
  // Progression fields computed for this user:
  userStatus: 'LOCKED' | 'AVAILABLE' | 'AWAITING_PAYMENT' | 'UNLOCKED' | 'IN_PROGRESS' | 'PENDING_VERIFICATION' | 'APPROVED' | 'REJECTED' | 'DISABLED';
  isPaidUnlocked: boolean;
  lockMessage: string;
  instructions: string | null;
  protectedUrl: string | null;
  submissionInstructions: string | null;
  externalContact: string | null;
  submission?: any | null;
}

export const taskProgressionService = {
  /**
   * Evaluates sequential task progression for a user in a specific level
   */
  async getLevelTasksForUser(userId: string, levelNumber: number): Promise<{ level: any; tasks: EvaluatedTask[]; isLevelUnlocked: boolean }> {
    const level = await prisma.level.findUnique({
      where: { levelNumber },
      include: {
        tasks: {
          orderBy: { taskNumber: 'asc' },
        },
      },
    });

    if (!level) {
      throw new Error(`Level ${levelNumber} not found`);
    }

    // Check if level itself is unlocked for this user
    let isLevelUnlocked = false;
    if (levelNumber === 1) {
      isLevelUnlocked = true;
    } else {
      // Check previous level completion (or if user has any progress in this level)
      const prevLevel = await prisma.level.findUnique({
        where: { levelNumber: levelNumber - 1 },
      });
      if (prevLevel) {
        const [prevUserProgressCount, prevSubmissionsCount, prevLevelProgress] = await Promise.all([
          prisma.userTaskProgress.count({
            where: {
              userId,
              task: { levelId: prevLevel.id },
              status: 'APPROVED',
            },
          }),
          prisma.taskSubmission.count({
            where: {
              userId,
              task: { levelId: prevLevel.id },
              status: 'APPROVED',
            },
          }),
          prisma.userLevelProgress.findUnique({
            where: { userId_levelId: { userId, levelId: prevLevel.id } },
          }),
        ]);

        const approvedCount = Math.max(
          prevUserProgressCount,
          prevSubmissionsCount,
          prevLevelProgress?.approvedTaskCount || 0
        );

        isLevelUnlocked =
          approvedCount >= (prevLevel.requiredTaskCount || 10) ||
          prevLevelProgress?.completionStatus === 'COMPLETED';
      }
    }

    // If level is locked, return tasks with locked status and real IDs
    if (!isLevelUnlocked) {
      const lockedTasks: EvaluatedTask[] = level.tasks.map((task) => {
        const isPrepaidTask = Boolean(
          task.isPaid ||
          (task.unlockFee && task.unlockFee > 0) ||
          task.taskNumber === 5 ||
          task.taskNumber === 10 ||
          task.taskNumber === 15 ||
          task.taskNumber === 20 ||
          task.taskType?.toLowerCase().includes('prepaid')
        );
        return {
          id: task.id,
          levelId: task.levelId,
          taskNumber: task.taskNumber,
          title: `Task #${task.taskNumber}`,
          description: `Locked assignment. Complete Level ${level.levelNumber - 1} to unlock.`,
          taskType: 'Task',
          rewardAmount: task.rewardAmount,
          creditPoints: isPrepaidTask ? 30 : 5,
          isPaid: false,
          unlockFee: 0,
          requiresAdminApproval: task.requiresAdminApproval,
          status: task.status,
          userStatus: 'LOCKED',
          isPaidUnlocked: false,
          lockMessage: `Level ${level.levelNumber} is locked. Complete all tasks in Level ${level.levelNumber - 1} first.`,
          instructions: null,
          protectedUrl: null,
          submissionInstructions: null,
          externalContact: null,
          submission: null,
        };
      });

      return {
        level,
        tasks: lockedTasks,
        isLevelUnlocked: false,
      };
    }

    // Fetch wallet, task progress records, and submissions in parallel (single roundtrip)
    const [wallet, userProgressRecords, submissions] = await Promise.all([
      prisma.wallet.findUnique({
        where: { userId },
        select: { availableBalance: true },
      }),
      prisma.userTaskProgress.findMany({
        where: {
          userId,
          task: { levelId: level.id },
        },
      }),
      prisma.taskSubmission.findMany({
        where: {
          userId,
          task: { levelId: level.id },
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);
    const userBalance = wallet?.availableBalance || 0;
    const progressMap = new Map(userProgressRecords.map((p) => [p.taskId, p]));
    // Keep the latest submission per task
    const submissionMap = new Map<string, any>();
    for (const s of submissions) {
      if (!submissionMap.has(s.taskId)) {
        submissionMap.set(s.taskId, s);
      }
    }

    const evaluatedTasks: EvaluatedTask[] = [];
    let previousTaskApproved: boolean = isLevelUnlocked;

    for (const task of level.tasks) {
      const progress = progressMap.get(task.id);
      const submission = submissionMap.get(task.id);

      let userStatus: EvaluatedTask['userStatus'] = 'LOCKED';
      let isPaidUnlocked = progress?.isPaidUnlocked || false;

      // A task is approved if UserTaskProgress is APPROVED or TaskSubmission is APPROVED
      const isApproved = progress?.status === 'APPROVED' || submission?.status === 'APPROVED';

      // Check whether prerequisite task (taskNumber - 1) is satisfied
      const prevTask = level.tasks.find((t) => t.taskNumber === task.taskNumber - 1);
      const prevProgress = prevTask ? progressMap.get(prevTask.id) : null;
      const prevSubmission = prevTask ? submissionMap.get(prevTask.id) : null;
      const isPrecedingTaskApproved =
        task.taskNumber === 1
          ? isLevelUnlocked
          : (!prevTask || prevProgress?.status === 'APPROVED' || prevSubmission?.status === 'APPROVED' || previousTaskApproved);

      if (task.status === 'DISABLED') {
        userStatus = 'DISABLED';
      } else if (!isLevelUnlocked) {
        userStatus = 'LOCKED';
      } else if (isApproved) {
        userStatus = 'APPROVED';
      } else if (submission?.status === 'PENDING' || progress?.status === 'PENDING_VERIFICATION') {
        userStatus = 'PENDING_VERIFICATION';
      } else if (progress?.status === 'REJECTED' || submission?.status === 'REJECTED') {
        userStatus = 'REJECTED';
      } else if (isPrecedingTaskApproved) {
        // Prerequisite is satisfied! Task is open to be worked on / submitted
        userStatus = 'AVAILABLE';
        if (task.isPaid && isPaidUnlocked) {
          isPaidUnlocked = true;
        }
      } else {
        userStatus = 'LOCKED';
      }

      // Track approved status for next sequential task
      previousTaskApproved = isApproved;

      // Mask sensitive content if user has not reached the task
      const hasAccessToProtectedContent = ['UNLOCKED', 'AVAILABLE', 'IN_PROGRESS', 'PENDING_VERIFICATION', 'APPROVED', 'REJECTED', 'AWAITING_PAYMENT'].includes(userStatus);

      const isLocked = userStatus === 'LOCKED';

      const isPrepaidTask = Boolean(
        task.isPaid ||
        (task.unlockFee && task.unlockFee > 0) ||
        task.taskNumber === 5 ||
        task.taskNumber === 10 ||
        task.taskNumber === 15 ||
        task.taskNumber === 20 ||
        task.taskType?.toLowerCase().includes('prepaid')
      );

      evaluatedTasks.push({
        id: task.id,
        levelId: task.levelId,
        taskNumber: task.taskNumber,
        title: isLocked ? `Task #${task.taskNumber}` : task.title,
        description: isLocked ? 'Complete previous task to unlock details.' : task.description,
        taskType: isLocked ? 'Task' : task.taskType,
        rewardAmount: task.rewardAmount,
        creditPoints: isPrepaidTask
          ? ((task as any).creditPoints && (task as any).creditPoints > 5 ? (task as any).creditPoints : 30)
          : ((task as any).creditPoints && (task as any).creditPoints > 0 ? (task as any).creditPoints : 5),
        isPaid: isLocked ? false : task.isPaid,
        unlockFee: isLocked ? 0 : task.unlockFee,
        requiresAdminApproval: task.requiresAdminApproval,
        status: task.status,
        userStatus,
        isPaidUnlocked,
        lockMessage: isLocked ? (task.lockMessage || `Task #${task.taskNumber} is locked. Complete Task #${task.taskNumber - 1} first.`) : '',
        instructions: hasAccessToProtectedContent && !isLocked ? task.instructions : null,
        protectedUrl: hasAccessToProtectedContent && !isLocked ? task.protectedUrl : null,
        submissionInstructions: hasAccessToProtectedContent && !isLocked ? task.submissionInstructions : null,
        externalContact: hasAccessToProtectedContent && !isLocked ? task.externalContact : null,
        submission: submission || null,
      });
    }

    return {
      level,
      tasks: evaluatedTasks,
      isLevelUnlocked,
    };
  },

  /**
   * Recalculates and updates level progression for a user
   */
  async updateLevelProgress(userId: string, levelId: string) {
    const level = await prisma.level.findUnique({
      where: { id: levelId },
      include: { tasks: true },
    });
    if (!level) return null;

    const [userProgressCount, submissionsCount, userLevelProgress] = await Promise.all([
      prisma.userTaskProgress.count({
        where: {
          userId,
          task: { levelId },
          status: 'APPROVED',
        },
      }),
      prisma.taskSubmission.count({
        where: {
          userId,
          task: { levelId },
          status: 'APPROVED',
        },
      }),
      prisma.userLevelProgress.findUnique({
        where: { userId_levelId: { userId, levelId } },
      }),
    ]);

    const approvedCount = Math.max(
      userProgressCount,
      submissionsCount,
      userLevelProgress?.approvedTaskCount || 0
    );

    const isCompleted = approvedCount >= (level.requiredTaskCount || 10);

    const progress = await prisma.userLevelProgress.upsert({
      where: {
        userId_levelId: { userId, levelId },
      },
      update: {
        approvedTaskCount: approvedCount,
        completionStatus: isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
        completedAt: isCompleted ? new Date() : undefined,
      },
      create: {
        userId,
        levelId,
        approvedTaskCount: approvedCount,
        completionStatus: isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
        completedAt: isCompleted ? new Date() : null,
      },
    });

    // If level completed and has completion reward, credit if not already credited
    if (isCompleted && level.completionReward > 0) {
      const rewardKey = `LEVEL_REWARD_${level.id}_${userId}`;
      const existing = await prisma.walletTransaction.findUnique({
        where: { idempotencyKey: rewardKey },
      });
      if (!existing) {
        await prisma.$transaction(async (tx) => {
          await tx.wallet.update({
            where: { userId },
            data: {
              availableBalance: { increment: level.completionReward },
              totalEarned: { increment: level.completionReward },
            },
          });
          await tx.walletTransaction.create({
            data: {
              userId,
              transactionType: 'LEVEL_REWARD',
              amount: level.completionReward,
              currency: 'PKR',
              status: 'COMPLETED',
              idempotencyKey: rewardKey,
              relatedEntityId: level.id,
              reason: `Completion bonus for Level ${level.levelNumber}: ${level.title}`,
            },
          });
          await tx.notification.create({
            data: {
              userId,
              title: `Level ${level.levelNumber} Completed! 🏆`,
              message: `Congratulations! You completed all 10 tasks in Level ${level.levelNumber} and earned PKR ${level.completionReward.toLocaleString()}!`,
              notificationType: 'LEVEL_STATUS',
            },
          });
        });
      }
    }

    // If referee completed Level 1, evaluate referral qualification
    if (isCompleted && level.levelNumber === 1) {
      await affiliateService.checkAndQualifyReferral(userId, 'LEVEL_1_COMPLETED');
    }

    // Award 1 Free Spin entitlement upon completing the 10th task (level completion)
    if (isCompleted) {
      const existingLevelSpin = await prisma.userSpinEntitlement.findFirst({
        where: {
          userId,
          levelNumber: level.levelNumber,
        },
      });

      if (!existingLevelSpin) {
        await prisma.userSpinEntitlement.create({
          data: {
            userId,
            levelNumber: level.levelNumber,
            taskNumber: level.requiredTaskCount || 10,
            triggerReason: `Level ${level.levelNumber} Completion Free Spin`,
            totalSpins: 1,
            remainingSpins: 1,
            isEligible: false,
            requiresAdminReview: true,
            adminReviewed: false,
            assignedPrizeId: null,
          },
        });

        await prisma.notification.create({
          data: {
            userId,
            title: `Level ${level.levelNumber} Completed! Free Spin Earned! 🎡`,
            message: `Congratulations! Completing Level ${level.levelNumber} earned you a Free Royal Spin! Your entitlement has been submitted to administration.`,
            notificationType: 'SPIN_REWARD',
          },
        });
      }
    }

    return progress;
  },
};
