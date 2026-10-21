import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { taskProgressionService } from '../services/taskProgressionService';
import { ledgerService, InsufficientBalanceError } from '../services/ledgerService';
import { affiliateService } from '../services/affiliateService';
import { sendUserLiveCommand } from '../utils/supabase';

const router = Router();

/**
 * GET /api/tasks/levels
 * Lists all 10 levels with user completion progress
 */
router.get('/levels', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const [levels, userProgress, userLevelProgressList, approvedSubmissions] = await Promise.all([
      prisma.level.findMany({ orderBy: { levelNumber: 'asc' } }),
      prisma.userTaskProgress.findMany({
        where: { userId, status: 'APPROVED' },
        select: { task: { select: { levelId: true, id: true } } },
      }),
      prisma.userLevelProgress.findMany({
        where: { userId },
      }),
      prisma.taskSubmission.findMany({
        where: { userId, status: 'APPROVED' },
        select: { task: { select: { levelId: true, id: true } } },
      }),
    ]);

    const approvedTasksByLevel = new Map<string, Set<string>>();
    for (const p of userProgress) {
      if (p.task?.levelId && p.task?.id) {
        if (!approvedTasksByLevel.has(p.task.levelId)) {
          approvedTasksByLevel.set(p.task.levelId, new Set());
        }
        approvedTasksByLevel.get(p.task.levelId)!.add(p.task.id);
      }
    }
    for (const s of approvedSubmissions) {
      if (s.task?.levelId && s.task?.id) {
        if (!approvedTasksByLevel.has(s.task.levelId)) {
          approvedTasksByLevel.set(s.task.levelId, new Set());
        }
        approvedTasksByLevel.get(s.task.levelId)!.add(s.task.id);
      }
    }

    const levelProgressMap = new Map<string, any>();
    for (const lp of userLevelProgressList) {
      levelProgressMap.set(lp.levelId, lp);
    }

    const levelsWithProgress = [];
    let previousLevelCompleted = true;

    for (const lvl of levels) {
      const taskSet = approvedTasksByLevel.get(lvl.id);
      const lp = levelProgressMap.get(lvl.id);
      const approvedCount = Math.max(taskSet ? taskSet.size : 0, lp?.approvedTaskCount || 0);

      const isCompleted = approvedCount >= (lvl.requiredTaskCount || 10) || lp?.completionStatus === 'COMPLETED';
      const isUnlocked = lvl.levelNumber === 1 || previousLevelCompleted;

      levelsWithProgress.push({
        id: lvl.id,
        levelNumber: lvl.levelNumber,
        title: lvl.title,
        description: lvl.description,
        status: lvl.status,
        requiredTaskCount: lvl.requiredTaskCount,
        completionReward: lvl.completionReward,
        totalCreditPoints: (lvl as any).totalCreditPoints ?? 100,
        approvedTaskCount: approvedCount,
        isCompleted,
        isUnlocked,
      });

      previousLevelCompleted = isCompleted;
    }

    res.json({ levels: levelsWithProgress });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/tasks/levels/:levelNumber
 * Returns evaluated tasks for a specific level with sequential prerequisite logic
 */
router.get('/levels/:levelNumber', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const levelNumber = parseInt(req.params.levelNumber as string, 10);

    if (isNaN(levelNumber) || levelNumber < 1 || levelNumber > 10) {
      return res.status(400).json({ error: 'Valid standard level number between 1 and 10 is required' });
    }

    const result = await taskProgressionService.getLevelTasksForUser(userId, levelNumber);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

async function findTaskByIdOrSynthetic(taskId: string) {
  // 1. Direct ID match
  let task: any = await prisma.task.findUnique({
    where: { id: taskId },
    include: { level: true },
  });
  if (task) return task;

  // 2. Synthetic or formatted ID match (e.g. "completed-lvl-2-task-10", "locked-lvl-2-task-10", "task-2-10", "task_2_10")
  const match =
    taskId.match(/(?:lvl|level)[-_](\d+)[-_]task[-_](\d+)/i) ||
    taskId.match(/^task[-_](\d+)[-_](\d+)$/i);
  if (match) {
    const levelNumber = parseInt(match[1], 10);
    const taskNumber = parseInt(match[2], 10);
    const level = await prisma.level.findUnique({ where: { levelNumber } });
    if (level) {
      task = await prisma.task.findUnique({
        where: {
          levelId_taskNumber: {
            levelId: level.id,
            taskNumber,
          },
        },
        include: { level: true },
      });
      if (task) return task;
    }
  }

  return null;
}

/**
 * GET /api/tasks/:taskId
 * Single task details
 */
router.get('/:taskId', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const taskId = req.params.taskId as string;

    const task: any = await findTaskByIdOrSynthetic(taskId);

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);

    const evaluatedTask = tasks.find((t) => t.id === task.id || t.id === taskId || t.taskNumber === task.taskNumber);
    if (!evaluatedTask) {
      return res.status(404).json({ error: 'Task evaluation failed' });
    }

    // Past submissions
    const submissions = await prisma.taskSubmission.findMany({
      where: { userId, taskId: task.id },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      task: evaluatedTask,
      level: task.level,
      isLevelUnlocked,
      submissions,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * Helper to auto-complete and approve a task for a user
 */
async function completeAndApproveTask(userId: string, task: any, submissionNotes: string, proofEvidence?: string | null) {
  const isPrepaid = Boolean(
    task.isPaid ||
    (task.unlockFee && task.unlockFee > 0) ||
    task.taskNumber === 5 ||
    task.taskNumber === 10 ||
    task.taskNumber === 15 ||
    task.taskNumber === 20 ||
    task.taskType?.toLowerCase().includes('prepaid')
  );

  const taskCPs = isPrepaid
    ? (task.creditPoints > 5 ? task.creditPoints : 30)
    : (task.creditPoints > 0 ? task.creditPoints : 5);
  const rewardAmount = task.rewardAmount || 0;

  const result = await prisma.$transaction(async (tx) => {
    // 1. Task unlock transaction if prepaid
    if (task.isPaid) {
      await tx.taskUnlockTransaction.create({
        data: {
          userId,
          taskId: task.id,
          unlockFee: 0,
          transactionId: `tx_unlock_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
          status: 'COMPLETED',
        },
      });
    }

    // 2. Submission record saved directly as APPROVED
    const sub = await tx.taskSubmission.create({
      data: {
        userId,
        taskId: task.id,
        submissionNotes: submissionNotes || (isPrepaid ? 'Prepaid task completed' : 'Task completed'),
        proofEvidence: proofEvidence || null,
        status: 'APPROVED',
        reviewerName: 'System (Verified)',
        reviewNotes: 'Task completed and verified automatically',
      },
    });

    // 3. User task progress updated to APPROVED
    const now = new Date();
    await tx.userTaskProgress.upsert({
      where: { userId_taskId: { userId, taskId: task.id } },
      update: {
        status: 'APPROVED',
        isPaidUnlocked: task.isPaid ? true : undefined,
        submissionAt: now,
        completedAt: now,
        approvedAt: now,
        reviewerId: 'system',
      },
      create: {
        userId,
        taskId: task.id,
        status: 'APPROVED',
        isPaidUnlocked: task.isPaid ? true : false,
        submissionAt: now,
        completedAt: now,
        approvedAt: now,
        reviewerId: 'system',
      },
    });

    // 4. Credit reward & CPs to user wallet
    const updatedWallet = await tx.wallet.update({
      where: { userId },
      data: {
        availableBalance: { increment: rewardAmount },
        totalEarned: { increment: rewardAmount },
        creditPoints: { increment: taskCPs },
      },
    });

    // 5. Create WalletTransaction record for reward
    if (rewardAmount > 0) {
      await tx.walletTransaction.create({
        data: {
          userId,
          transactionType: 'TASK_REWARD',
          amount: rewardAmount,
          currency: 'PKR',
          status: 'COMPLETED',
          reason: `Reward for Level ${task.level.levelNumber} Task #${task.taskNumber}: ${task.title}`,
          relatedEntityId: task.id,
          actorId: 'system',
          actorName: 'System',
        },
      });
    }

    // 6. Check and update Level Progress
    const approvedCount = await tx.userTaskProgress.count({
      where: {
        userId,
        task: { levelId: task.levelId },
        status: 'APPROVED',
      },
    });

    const requiredCount = task.level.requiredTaskCount || 10;
    const isLevelComplete = approvedCount >= requiredCount;
    let levelReward = 0;

    if (isLevelComplete) {
      levelReward = task.level.completionReward || (task.level.levelNumber === 1 ? 500 : 0);
      if (levelReward > 0) {
        await tx.wallet.update({
          where: { userId },
          data: {
            availableBalance: { increment: levelReward },
            totalEarned: { increment: levelReward },
          },
        });
        await tx.walletTransaction.create({
          data: {
            userId,
            transactionType: 'LEVEL_REWARD',
            amount: levelReward,
            currency: 'PKR',
            status: 'COMPLETED',
            reason: `Level ${task.level.levelNumber} completion bonus!`,
            relatedEntityId: task.level.id,
            actorId: 'system',
            actorName: 'System',
          },
        });
      }
    }

    await tx.userLevelProgress.upsert({
      where: { userId_levelId: { userId, levelId: task.levelId } },
      update: {
        approvedTaskCount: approvedCount,
        completionStatus: isLevelComplete ? 'COMPLETED' : 'IN_PROGRESS',
        completedAt: isLevelComplete ? new Date() : undefined,
      },
      create: {
        userId,
        levelId: task.levelId,
        approvedTaskCount: approvedCount,
        completionStatus: isLevelComplete ? 'COMPLETED' : 'IN_PROGRESS',
        completedAt: isLevelComplete ? new Date() : null,
      },
    });

    // 7. Create notification
    await tx.notification.create({
      data: {
        userId,
        title: `Task #${task.taskNumber} Completed! 🎉`,
        message: `You completed Task #${task.taskNumber} (${task.title}). +PKR ${rewardAmount.toLocaleString()} reward and +${taskCPs} Credit Points credited!${isLevelComplete ? ` Level ${task.level.levelNumber} Completed! +PKR ${levelReward.toLocaleString()} Level Bonus added!` : ''}`,
        notificationType: 'TASK_STATUS',
      },
    });

    return { sub, updatedWallet, isLevelComplete, levelReward };
  });

  // Find next task in level
  const nextTask = await prisma.task.findUnique({
    where: {
      levelId_taskNumber: {
        levelId: task.levelId,
        taskNumber: task.taskNumber + 1,
      },
    },
  });

  // Emit live events
  sendUserLiveCommand(userId, 'task', { taskId: task.id, taskNumber: task.taskNumber, status: 'APPROVED' });
  sendUserLiveCommand(userId, 'wallet', { balance: result.updatedWallet.availableBalance, creditPoints: result.updatedWallet.creditPoints });
  sendUserLiveCommand(userId, 'refresh', { type: 'TASK_APPROVED' });

  return {
    message: `Task completed! +PKR ${rewardAmount.toLocaleString()} reward and +${taskCPs} Credit Points credited to your account!`,
    submission: result.sub,
    userStatus: 'APPROVED',
    rewardAmount,
    creditPoints: taskCPs,
    nextTaskId: nextTask?.id || null,
    nextTaskNumber: nextTask?.taskNumber || null,
    isLevelComplete: result.isLevelComplete,
  };
}

/**
 * POST /api/tasks/:taskId/unlock
 * Paid task unlocking workflow
 */
router.post('/:taskId/unlock', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const taskId = req.params.taskId as string;

    const task: any = await findTaskByIdOrSynthetic(taskId);

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    if (!task.isPaid || task.unlockFee <= 0) {
      return res.status(400).json({ error: 'This task is free and does not require an unlock fee' });
    }

    // Validate level and prerequisite task
    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);
    if (!isLevelUnlocked) {
      return res.status(403).json({ error: `Level ${task.level.levelNumber} is locked. Complete all tasks in the previous level first.` });
    }

    const evaluated = tasks.find((t) => t.id === task.id || t.id === taskId || t.taskNumber === task.taskNumber);
    if (!evaluated) {
      return res.status(404).json({ error: 'Task evaluation error' });
    }

    if (evaluated.userStatus === 'APPROVED') {
      return res.status(400).json({ error: 'This task is already completed and approved' });
    }

    if (evaluated.userStatus === 'LOCKED') {
      return res.status(403).json({ error: evaluated.lockMessage || 'Prerequisite tasks must be approved before unlocking this task' });
    }

    // Validate user wallet balance
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    if (!wallet || wallet.availableBalance < task.unlockFee) {
      const currentBal = wallet?.availableBalance || 0;
      const remainingNeeded = Math.max(0, task.unlockFee - currentBal);
      return res.status(400).json({
        error: `Insufficient account balance. This prepaid task requires an account balance of PKR ${task.unlockFee.toLocaleString()} to submit for approval (Available: PKR ${currentBal.toLocaleString()}). Please deposit PKR ${remainingNeeded.toLocaleString()} to complete the required balance.`,
        requiredAmount: task.unlockFee,
        availableBalance: currentBal,
        remainingNeeded,
        redirectToDeposit: true,
      });
    }

    // Balance requirement verified! Auto-complete and approve prepaid task!
    const completionResult = await completeAndApproveTask(
      userId,
      task,
      `Prepaid task completed (Account balance requirement of PKR ${task.unlockFee.toLocaleString()} verified)`
    );

    res.json({
      ...completionResult,
      task: {
        id: task.id,
        title: task.title,
        instructions: task.instructions,
        protectedUrl: task.protectedUrl,
        userStatus: 'APPROVED',
        isPaidUnlocked: true,
      },
    });
  } catch (err) {
    if (err instanceof InsufficientBalanceError) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});

/**
 * POST /api/tasks/:taskId/submit
 * User completes task - automatically verifies, approves, and credits reward
 */
router.post('/:taskId/submit', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const taskId = req.params.taskId as string;

    const schema = z.object({
      submissionNotes: z.string().max(1000).optional().default('Task completed'),
      proofEvidence: z.string().optional().nullable(),
    });
    const validated = schema.parse(req.body || {});

    const task: any = await findTaskByIdOrSynthetic(taskId);

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);
    if (!isLevelUnlocked) {
      return res.status(403).json({ error: 'This level is locked' });
    }

    const evaluated = tasks.find((t) => t.id === task.id || t.id === taskId || t.taskNumber === task.taskNumber);
    if (!evaluated) {
      return res.status(404).json({ error: 'Task evaluation error' });
    }

    if (evaluated.userStatus === 'APPROVED') {
      return res.status(400).json({ error: 'This task has already been completed and approved' });
    }

    if (evaluated.userStatus === 'LOCKED') {
      return res.status(403).json({ error: evaluated.lockMessage || 'This task is locked' });
    }

    // If it's a prepaid task, client must be at the required account balance upon completing
    if (task.isPaid) {
      const wallet = await prisma.wallet.findUnique({ where: { userId } });
      const currentBal = wallet?.availableBalance || 0;
      if (currentBal < task.unlockFee) {
        const remainingNeeded = Math.max(0, task.unlockFee - currentBal);
        return res.status(400).json({
          error: `Insufficient account balance. This prepaid task requires an account balance of PKR ${task.unlockFee.toLocaleString()} to complete (Available: PKR ${currentBal.toLocaleString()}). Please deposit PKR ${remainingNeeded.toLocaleString()} to complete the required balance.`,
          requiredAmount: task.unlockFee,
          availableBalance: currentBal,
          remainingNeeded,
          redirectToDeposit: true,
        });
      }
    }

    // Auto-approve, credit PKR reward and CPs, and advance progression
    const result = await completeAndApproveTask(
      userId,
      task,
      validated.submissionNotes || (task.isPaid ? 'Prepaid task completed' : 'Task completed'),
      validated.proofEvidence
    );

    res.status(200).json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
