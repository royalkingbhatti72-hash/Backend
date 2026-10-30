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

    // Single parallel query roundtrip for all level progression & current level data
    const [
      allLevels,
      userTaskProgressList,
      userLevelProgressList,
      userSubmissionsList,
      wallet,
      currentLevelProgressRecords,
      currentLevelSubmissions,
    ] = await Promise.all([
      prisma.level.findMany({
        select: { id: true, levelNumber: true, requiredTaskCount: true },
        orderBy: { levelNumber: 'asc' },
      }),
      prisma.userTaskProgress.findMany({
        where: { userId, status: 'APPROVED' },
        select: { task: { select: { levelId: true, id: true } } },
      }),
      prisma.userLevelProgress.findMany({
        where: { userId },
        select: { levelId: true, approvedTaskCount: true, completionStatus: true },
      }),
      prisma.taskSubmission.findMany({
        where: { userId, status: 'APPROVED' },
        select: { task: { select: { levelId: true, id: true } } },
      }),
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

    // Compute approved tasks count per level
    const approvedTasksByLevelId = new Map<string, Set<string>>();
    for (const p of userTaskProgressList) {
      if (p.task?.levelId && p.task?.id) {
        if (!approvedTasksByLevelId.has(p.task.levelId)) {
          approvedTasksByLevelId.set(p.task.levelId, new Set());
        }
        approvedTasksByLevelId.get(p.task.levelId)!.add(p.task.id);
      }
    }
    for (const s of userSubmissionsList) {
      if (s.task?.levelId && s.task?.id) {
        if (!approvedTasksByLevelId.has(s.task.levelId)) {
          approvedTasksByLevelId.set(s.task.levelId, new Set());
        }
        approvedTasksByLevelId.get(s.task.levelId)!.add(s.task.id);
      }
    }

    const levelProgressByLevelId = new Map<string, any>();
    for (const lp of userLevelProgressList) {
      levelProgressByLevelId.set(lp.levelId, lp);
    }

    const levelStatsByNumber = new Map<number, { approvedCount: number; isCompleted: boolean }>();
    for (const lvl of allLevels) {
      const taskSet = approvedTasksByLevelId.get(lvl.id);
      const lp = levelProgressByLevelId.get(lvl.id);
      const approvedCount = Math.max(taskSet ? taskSet.size : 0, lp?.approvedTaskCount || 0);
      const isCompleted = approvedCount >= (lvl.requiredTaskCount || 10) || lp?.completionStatus === 'COMPLETED';
      levelStatsByNumber.set(lvl.levelNumber, { approvedCount, isCompleted });
    }

    const l1Completed = levelStatsByNumber.get(1)?.isCompleted || false;
    const l2Completed = l1Completed && (levelStatsByNumber.get(2)?.isCompleted || false);
    const l3Completed = l2Completed && (levelStatsByNumber.get(3)?.isCompleted || false);
    const isLevel4Unlocked = l3Completed;

    // Check if current level is unlocked
    let isLevelUnlocked = false;
    if (levelNumber === 1) {
      isLevelUnlocked = true;
    } else if (levelNumber === 2) {
      isLevelUnlocked = l1Completed;
    } else if (levelNumber === 3) {
      isLevelUnlocked = l2Completed;
    } else {
      // In Level 4, when it gets unlocked every next level (5 to 10) is unlocked!
      isLevelUnlocked = isLevel4Unlocked;
    }

    // Determine prerequisite eligibility for Task 1 of this level
    let isTask1Eligible = false;
    let task1LockMessage = '';

    if (!isLevelUnlocked) {
      isTask1Eligible = false;
      task1LockMessage = `Level ${levelNumber} is locked. Complete all tasks in Level ${levelNumber - 1} first.`;
    } else if (levelNumber === 1) {
      isTask1Eligible = true;
    } else if (levelNumber === 2) {
      isTask1Eligible = l1Completed;
      if (!isTask1Eligible) {
        task1LockMessage = 'Complete all tasks in Level 1 first to unlock Level 2 tasks.';
      }
    } else if (levelNumber === 3) {
      isTask1Eligible = l2Completed;
      if (!isTask1Eligible) {
        task1LockMessage = 'Complete all tasks in Level 2 first to unlock Level 3 tasks.';
      }
    } else if (levelNumber === 4) {
      isTask1Eligible = l3Completed;
      if (!isTask1Eligible) {
        task1LockMessage = 'Complete all tasks in Level 3 first to unlock Level 4 tasks.';
      }
    } else if (levelNumber === 5) {
      // In Level 4, client needs only 1 task completed to be able to complete Level 5 tasks!
      const l4ApprovedCount = levelStatsByNumber.get(4)?.approvedCount || 0;
      isTask1Eligible = l4ApprovedCount >= 1;
      if (!isTask1Eligible) {
        task1LockMessage = 'Complete Task 1 in Level 4 first to be able to complete Level 5 tasks.';
      }
    } else {
      // For Levels 6 to 10: requires previous level completed
      const prevStats = levelStatsByNumber.get(levelNumber - 1);
      isTask1Eligible = prevStats?.isCompleted || false;
      if (!isTask1Eligible) {
        task1LockMessage = `Complete all tasks in Level ${levelNumber - 1} first to start Level ${levelNumber} tasks.`;
      }
    }

    // If level itself is locked, all tasks are appearable with real names/rewards, but userStatus is LOCKED
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
          title: task.title,
          description: task.description,
          taskType: task.taskType || (isPrepaidTask ? 'Prepaid Task' : 'Task'),
          rewardAmount: task.rewardAmount,
          creditPoints: 0,
          isPaid: Boolean(task.isPaid),
          unlockFee: task.unlockFee || 0,
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

    // Level is unlocked! Map user progress and submissions
    const progressMap = new Map(currentLevelProgressRecords.map((p) => [p.taskId, p]));
    const submissionMap = new Map<string, any>();
    for (const s of currentLevelSubmissions) {
      if (!submissionMap.has(s.taskId)) {
        submissionMap.set(s.taskId, s);
      }
    }

    const evaluatedTasks: EvaluatedTask[] = [];
    let previousTaskApproved: boolean = isTask1Eligible;

    for (const task of level.tasks) {
      const progress = progressMap.get(task.id);
      const submission = submissionMap.get(task.id);

      let userStatus: EvaluatedTask['userStatus'] = 'LOCKED';
      let isPaidUnlocked = progress?.isPaidUnlocked || false;

      // A task is approved if UserTaskProgress is APPROVED or TaskSubmission is APPROVED
      const isApproved = progress?.status === 'APPROVED' || submission?.status === 'APPROVED';

      // Check whether prerequisite task is satisfied:
      // For Task 1: must satisfy isTask1Eligible
      // For Task > 1: previous task (taskNumber - 1) in THIS level must be APPROVED
      let isPrerequisiteSatisfied = false;
      let taskLockMessage = '';

      if (task.taskNumber === 1) {
        isPrerequisiteSatisfied = isTask1Eligible;
        if (!isPrerequisiteSatisfied) {
          taskLockMessage = task1LockMessage;
        }
      } else {
        const prevTask = level.tasks.find((t) => t.taskNumber === task.taskNumber - 1);
        const prevProgress = prevTask ? progressMap.get(prevTask.id) : null;
        const prevSubmission = prevTask ? submissionMap.get(prevTask.id) : null;
        const isPrevApproved =
          prevProgress?.status === 'APPROVED' ||
          prevSubmission?.status === 'APPROVED' ||
          previousTaskApproved;

        isPrerequisiteSatisfied = isPrevApproved;
        if (!isPrerequisiteSatisfied) {
          taskLockMessage = `Task #${task.taskNumber} is locked. Complete Task #${task.taskNumber - 1} first in proper sequence.`;
        }
      }

      if (task.status === 'DISABLED') {
        userStatus = 'DISABLED';
      } else if (isApproved) {
        userStatus = 'APPROVED';
      } else if (submission?.status === 'PENDING' || progress?.status === 'PENDING_VERIFICATION') {
        userStatus = 'PENDING_VERIFICATION';
      } else if (progress?.status === 'REJECTED' || submission?.status === 'REJECTED') {
        userStatus = 'REJECTED';
      } else if (isPrerequisiteSatisfied) {
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

      // Sensitive operational links only accessible when active/approved
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
        title: task.title, // Appearable! Real task title
        description: task.description, // Appearable! Real description
        taskType: task.taskType || (isPrepaidTask ? 'Prepaid Task' : 'Task'),
        rewardAmount: task.rewardAmount,
        creditPoints: 0,
        isPaid: Boolean(task.isPaid),
        unlockFee: task.unlockFee || 0,
        requiresAdminApproval: task.requiresAdminApproval,
        status: task.status,
        userStatus,
        isPaidUnlocked,
        lockMessage: isLocked ? (taskLockMessage || task.lockMessage || `Task #${task.taskNumber} is locked. Complete Task #${task.taskNumber - 1} first in proper sequence.`) : '',
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
