import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { taskProgressionService } from '../services/taskProgressionService';
import { ledgerService, InsufficientBalanceError } from '../services/ledgerService';
import { affiliateService } from '../services/affiliateService';

const router = Router();

/**
 * GET /api/tasks/levels
 * Lists all 10 levels with user completion progress
 */
router.get('/levels', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: 'asc' },
    });

    const levelsWithProgress = [];
    let previousLevelCompleted = true;

    for (const lvl of levels) {
      const approvedCount = await prisma.userTaskProgress.count({
        where: {
          userId,
          task: { levelId: lvl.id },
          status: 'APPROVED',
        },
      });

      const isCompleted = approvedCount >= (lvl.requiredTaskCount || 10);
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

/**
 * GET /api/tasks/:taskId
 * Single task details
 */
router.get('/:taskId', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const taskId = req.params.taskId as string;

    const task: any = await prisma.task.findUnique({
      where: { id: taskId },
      include: { level: true },
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);
    const evaluatedTask = tasks.find((t) => t.id === taskId);

    if (!evaluatedTask) {
      return res.status(404).json({ error: 'Task evaluation failed' });
    }

    // Past submissions
    const submissions = await prisma.taskSubmission.findMany({
      where: { userId, taskId },
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
 * POST /api/tasks/:taskId/unlock
 * Paid task unlocking workflow
 */
router.post('/:taskId/unlock', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const taskId = req.params.taskId as string;

    const task: any = await prisma.task.findUnique({
      where: { id: taskId },
      include: { level: true },
    });

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

    const evaluated = tasks.find((t) => t.id === taskId);
    if (!evaluated) {
      return res.status(404).json({ error: 'Task evaluation error' });
    }

    if (evaluated.userStatus === 'APPROVED') {
      return res.status(400).json({ error: 'This task is already completed and approved' });
    }

    if (evaluated.isPaidUnlocked) {
      return res.status(400).json({ error: 'This task is already unlocked' });
    }

    if (evaluated.userStatus === 'LOCKED') {
      return res.status(403).json({ error: evaluated.lockMessage || 'Prerequisite tasks must be approved before unlocking this task' });
    }

    // Validate user wallet balance
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    if (!wallet || wallet.availableBalance < task.unlockFee) {
      return res.status(400).json({
        error: `Insufficient wallet balance. Required: PKR ${task.unlockFee.toLocaleString()}, Available: PKR ${wallet?.availableBalance.toLocaleString() || 0}. Please deposit funds to proceed.`,
        requiredAmount: task.unlockFee,
        availableBalance: wallet?.availableBalance || 0,
      });
    }

    // Perform atomic transaction: deduct balance, create unlock record, update task progress
    const result = await prisma.$transaction(async (tx) => {
      // 1. Debit wallet
      await tx.wallet.update({
        where: { userId },
        data: {
          availableBalance: { decrement: task.unlockFee },
          totalUnlockFees: { increment: task.unlockFee },
        },
      });

      // 2. Ledger transaction
      const transaction = await tx.walletTransaction.create({
        data: {
          userId,
          transactionType: 'TASK_UNLOCK_FEE',
          amount: -task.unlockFee,
          currency: 'PKR',
          status: 'COMPLETED',
          relatedEntityId: task.id,
          reason: `Unlock fee for Level ${task.level.levelNumber} Task ${task.taskNumber}: ${task.title}`,
        },
      });

      // 3. Task unlock transaction
      const unlockTx = await tx.taskUnlockTransaction.create({
        data: {
          userId,
          taskId: task.id,
          unlockFee: task.unlockFee,
          transactionId: transaction.id,
          status: 'COMPLETED',
        },
      });

      // 4. Update or create UserTaskProgress
      const progress = await tx.userTaskProgress.upsert({
        where: { userId_taskId: { userId, taskId: task.id } },
        update: {
          status: 'UNLOCKED',
          isPaidUnlocked: true,
          unlockedAt: new Date(),
        },
        create: {
          userId,
          taskId: task.id,
          status: 'UNLOCKED',
          isPaidUnlocked: true,
          unlockedAt: new Date(),
        },
      });

      // 5. Notify user
      await tx.notification.create({
        data: {
          userId,
          title: `Task Unlocked: ${task.title} 🔓`,
          message: `Unlock fee of PKR ${task.unlockFee.toLocaleString()} paid. Protected instructions and link are now active.`,
          notificationType: 'TASK_STATUS',
        },
      });

      return { progress, unlockTx, transaction };
    });

    res.json({
      message: `Task successfully unlocked! PKR ${task.unlockFee.toLocaleString()} deducted from your wallet.`,
      task: {
        id: task.id,
        title: task.title,
        instructions: task.instructions,
        protectedUrl: task.protectedUrl,
        userStatus: 'UNLOCKED',
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
 * User submits confirmation reference or screenshot notes for admin review
 */
router.post('/:taskId/submit', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const taskId = req.params.taskId as string;

    const schema = z.object({
      submissionNotes: z.string().max(1000).optional().default('Task completed - submitted for review'),
      proofEvidence: z.string().optional().nullable(),
    });
    const validated = schema.parse(req.body || {});

    const task: any = await prisma.task.findUnique({
      where: { id: taskId },
      include: { level: true },
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    const { tasks, isLevelUnlocked } = await taskProgressionService.getLevelTasksForUser(userId, task.level.levelNumber);
    if (!isLevelUnlocked) {
      return res.status(403).json({ error: 'This level is locked' });
    }

    const evaluated = tasks.find((t) => t.id === taskId);
    if (!evaluated) {
      return res.status(404).json({ error: 'Task evaluation error' });
    }

    if (evaluated.userStatus === 'APPROVED') {
      return res.status(400).json({ error: 'This task has already been completed and approved' });
    }

    if (evaluated.userStatus === 'PENDING_VERIFICATION') {
      return res.status(400).json({ error: 'A submission for this task is already awaiting admin verification' });
    }

    if (evaluated.userStatus === 'LOCKED') {
      return res.status(403).json({ error: evaluated.lockMessage || 'This task is locked' });
    }

    if (evaluated.userStatus === 'AWAITING_PAYMENT') {
      return res.status(403).json({ error: `Please pay the unlock fee of PKR ${task.unlockFee.toLocaleString()} first before submitting proof.` });
    }

    // If task is a Prepaid/Paid task, it does NOT require manual admin review!
    // Auto-approve instantly upon submission and award credit points immediately.
    if (task.isPaid) {
      const creditPointsToAdd = task.creditPoints || 30;

      const submission = await prisma.$transaction(async (tx) => {
        const sub = await tx.taskSubmission.create({
          data: {
            userId,
            taskId: task.id,
            submissionNotes: validated.submissionNotes,
            proofEvidence: validated.proofEvidence || null,
            status: 'APPROVED',
            reviewerName: 'System (Auto-Verified Prepaid)',
            reviewNotes: 'Prepaid assignment verified and instantly approved without manual review.',
          },
        });

        await tx.userTaskProgress.upsert({
          where: { userId_taskId: { userId, taskId: task.id } },
          update: {
            status: 'APPROVED',
            approvedAt: new Date(),
            submissionAt: new Date(),
          },
          create: {
            userId,
            taskId: task.id,
            status: 'APPROVED',
            approvedAt: new Date(),
            submissionAt: new Date(),
          },
        });

        // Credit points immediately
        await tx.wallet.update({
          where: { userId },
          data: {
            creditPoints: { increment: creditPointsToAdd },
          },
        });

        // Notify user
        await tx.notification.create({
          data: {
            userId,
            title: `Prepaid Task Approved! +${creditPointsToAdd} Points 🎉`,
            message: `Your prepaid task "${task.title}" has been automatically verified and approved! You earned +${creditPointsToAdd} credit points, and the next sequential task is now unlocked.`,
            notificationType: 'TASK_STATUS',
          },
        });

        // Task 3 and Task 7 Milestone Spin
        if (task.taskNumber === 3 || task.taskNumber === 7) {
          const milestoneReason = `Level ${task.level.levelNumber} Task ${task.taskNumber} Milestone Free Spin`;
          const existingEntitlement = await tx.userSpinEntitlement.findFirst({
            where: {
              userId,
              levelNumber: task.level.levelNumber,
              taskNumber: task.taskNumber,
            },
          });

          if (!existingEntitlement) {
            await tx.userSpinEntitlement.create({
              data: {
                userId,
                levelNumber: task.level.levelNumber,
                taskNumber: task.taskNumber,
                triggerReason: milestoneReason,
                totalSpins: 1,
                remainingSpins: 1,
                isEligible: false,
                requiresAdminReview: true,
                adminReviewed: false,
                assignedPrizeId: null,
              },
            });

            await tx.notification.create({
              data: {
                userId,
                title: `Task ${task.taskNumber} Milestone Spin Earned! 🎡`,
                message: `Congratulations! Completing Task ${task.taskNumber} in Level ${task.level.levelNumber} earned you a Free Royal Spin!`,
                notificationType: 'SPIN_REWARD',
              },
            });
          }
        }

        return sub;
      });

      // Recalculate level completion (which awards level cash reward if all 10 tasks are approved)
      await taskProgressionService.updateLevelProgress(userId, task.levelId);

      // Check referral qualification for referrer
      await affiliateService.checkAndQualifyReferral(userId, 'TASK_APPROVED');

      return res.status(200).json({
        message: `Prepaid task completed and instantly approved! +${creditPointsToAdd} Credit Points added. The next task is now available.`,
        submission,
        userStatus: 'APPROVED',
      });
    }

    // Standard free tasks: Record submission and queue for manual admin verification
    const submission = await prisma.$transaction(async (tx) => {
      const sub = await tx.taskSubmission.create({
        data: {
          userId,
          taskId: task.id,
          submissionNotes: validated.submissionNotes,
          proofEvidence: validated.proofEvidence || null,
          status: 'PENDING',
        },
      });

      await tx.userTaskProgress.upsert({
        where: { userId_taskId: { userId, taskId: task.id } },
        update: {
          status: 'PENDING_VERIFICATION',
          submissionAt: new Date(),
        },
        create: {
          userId,
          taskId: task.id,
          status: 'PENDING_VERIFICATION',
          submissionAt: new Date(),
        },
      });

      await tx.notification.create({
        data: {
          userId,
          title: `Task Submitted: ${task.title} ⏳`,
          message: 'Your submission has been queued for manual admin verification. You will be notified once reviewed.',
          notificationType: 'TASK_STATUS',
        },
      });

      return sub;
    });

    res.status(201).json({
      message: 'Task submitted for review! Once approved by admin, the task will be completed and the next task will open.',
      submission,
      userStatus: 'PENDING_VERIFICATION',
    });
  } catch (err) {
    next(err);
  }
});

export default router;
