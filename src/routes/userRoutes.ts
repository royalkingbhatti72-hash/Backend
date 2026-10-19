import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * GET /api/user/dashboard
 * Aggregates complete dashboard data calculated strictly from database records
 */
router.get('/dashboard', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;

    // Fetch user with wallet
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        wallet: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Determine current active level for user
    // A level is completed if all 10 tasks are approved.
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: 'asc' },
    });

    let currentLevelNumber = 1;
    let currentLevelApprovedTasks = 0;
    let isAllLevelsCompleted = false;
    let completedLevelsCount = 0;
    let foundActiveLevel = false;

    for (const lvl of levels) {
      const approvedCount = await prisma.userTaskProgress.count({
        where: {
          userId,
          task: { levelId: lvl.id },
          status: 'APPROVED',
        },
      });

      if (approvedCount >= 10) {
        completedLevelsCount++;
      } else if (!foundActiveLevel) {
        currentLevelNumber = lvl.levelNumber;
        currentLevelApprovedTasks = approvedCount;
        foundActiveLevel = true;
      }
    }

    if (!foundActiveLevel && completedLevelsCount >= 10) {
      currentLevelNumber = 10;
      currentLevelApprovedTasks = 10;
      isAllLevelsCompleted = true;
    }

    const currentLevel = levels.find((l) => l.levelNumber === currentLevelNumber) || levels[0];

    // Global task counters
    const totalApprovedTasksCount = await prisma.userTaskProgress.count({
      where: { userId, status: 'APPROVED' },
    });
    const remainingTasksCount = Math.max(0, 100 - totalApprovedTasksCount);

    // Sum of approved task rewards
    const taskRewardTransactions = await prisma.walletTransaction.aggregate({
      where: {
        userId,
        transactionType: 'TASK_REWARD',
        status: 'COMPLETED',
      },
      _sum: { amount: true },
    });
    const totalTaskRewardsApproved = taskRewardTransactions._sum.amount || 0;

    // Referral count
    const referralCount = await prisma.referral.count({
      where: { referrerId: userId },
    });

    // Spin eligibility
    const entitlement = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        isEligible: true,
        remainingSpins: { gt: 0 },
      },
    });
    const spinEligibility = {
      canSpin: !!entitlement,
      remainingSpins: entitlement?.remainingSpins || 0,
    };

    // Unread notifications count
    const unreadNotificationsCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    // Recent transactions (last 5)
    const recentTransactions = await prisma.walletTransaction.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 5,
    });

    // Recent activity (latest submissions, notifications, spins)
    const recentSubmissions = await prisma.taskSubmission.findMany({
      where: { userId },
      include: {
        task: {
          select: { title: true, taskNumber: true, rewardAmount: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 5,
    });

    // Credit points can ONLY and ONLY be earned from approved task completions:
    // Standard tasks = 5 credit points each, Prepaid tasks = 30 credit points each (e.g., Level 1: 8 x 5 + 2 x 30 = 100 points).
    // Any other source is removed, and wallet credit points are strictly synchronized to approved tasks.
    const approvedSubmissions = await prisma.taskSubmission.findMany({
      where: { userId, status: 'APPROVED' },
      include: {
        task: {
          select: { isPaid: true, unlockFee: true, taskType: true, creditPoints: true },
        },
      },
    });

    const calculatedCreditPoints = approvedSubmissions.reduce((sum, sub) => {
      const task = sub.task;
      if (!task) return sum;
      const isPrepaid = Boolean(task.isPaid || (task.unlockFee && task.unlockFee > 0) || task.taskType?.toLowerCase().includes('prepaid'));
      const points = isPrepaid
        ? (task.creditPoints && task.creditPoints > 5 ? task.creditPoints : 30)
        : (task.creditPoints && task.creditPoints > 0 ? task.creditPoints : 5);
      return sum + points;
    }, 0);

    let creditPoints = calculatedCreditPoints;
    if (user.wallet && user.wallet.creditPoints !== calculatedCreditPoints) {
      await prisma.wallet.update({
        where: { userId },
        data: { creditPoints: calculatedCreditPoints },
      });
      user.wallet.creditPoints = calculatedCreditPoints;
    }

    const eligiblePercent = Math.min(100, completedLevelsCount * 10);
    const availableBalance = user.wallet?.availableBalance || 0;
    const maxWithdrawableAmount = Math.floor((availableBalance * eligiblePercent) / 100);

    res.json({
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        referralCode: user.referralCode,
        accountStatus: user.accountStatus,
        createdAt: user.createdAt,
      },
      wallet: user.wallet
        ? {
            ...user.wallet,
            creditPoints,
          }
        : {
            availableBalance: 0,
            pendingBalance: 0,
            totalEarned: 0,
            totalDeposited: 0,
            totalWithdrawn: 0,
            creditPoints: 0,
          },
      withdrawalEligibility: {
        completedLevelsCount,
        eligiblePercent,
        maxWithdrawableAmount,
        availableBalance,
      },
      levelProgress: {
        currentLevelNumber,
        levelTitle: currentLevel.title,
        levelDescription: currentLevel.description,
        approvedTasksCount: currentLevelApprovedTasks,
        totalLevelTasks: 10,
        isAllLevelsCompleted,
        completedLevelsCount,
      },
      taskStats: {
        totalApprovedTasks: totalApprovedTasksCount,
        totalTasks: 100,
        remainingTasks: remainingTasksCount,
        totalTaskRewards: totalTaskRewardsApproved,
        totalCreditPoints: creditPoints,
      },
      referralCount,
      spinEligibility,
      unreadNotificationsCount,
      recentTransactions,
      recentSubmissions,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/user/profile
 */
router.get('/profile', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      include: {
        wallet: true,
        referredBy: {
          select: { name: true, phone: true },
        },
      },
    });
    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({ user });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/user/profile/password
 */
router.put('/profile/password', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const schema = z.object({
      currentPassword: z.string().min(1, 'Current password is required'),
      newPassword: z.string().min(6, 'New password must be at least 6 characters'),
    });
    const validated = schema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const isValid = await bcrypt.compare(validated.currentPassword, user.passwordHash);
    if (!isValid) {
      return res.status(400).json({ error: 'Incorrect current password' });
    }

    const newHash = await bcrypt.hash(validated.newPassword, 10);
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: newHash, mustChangePassword: false },
    });

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    next(err);
  }
});

export default router;
