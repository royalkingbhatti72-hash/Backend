import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { prisma } from '../prisma';
import { config } from '../config';
import { requireAdmin, AdminAuthRequest } from '../middleware/adminAuth';
import { logAdminAction } from '../services/auditService';
import { taskProgressionService } from '../services/taskProgressionService';
import { affiliateService } from '../services/affiliateService';
import { sendUserLiveCommand } from '../utils/supabase';
import { ensureOfficialSpinPrizes } from '../services/spinPrizeService';

const router = Router();

// ==========================================
// 1. ADMIN AUTHENTICATION
// ==========================================

const adminLoginSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
});

router.post('/login', async (req, res, next) => {
  try {
    const { username, password } = adminLoginSchema.parse(req.body);

    const admin = await prisma.adminUser.findUnique({
      where: { username },
    });

    if (!admin || admin.status !== 'ACTIVE') {
      return res.status(401).json({ error: 'Invalid administrator credentials' });
    }

    const isValid = await bcrypt.compare(password, admin.passwordHash);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid administrator credentials' });
    }

    const token = jwt.sign(
      { adminId: admin.id, role: admin.role, username: admin.username },
      config.adminSecret,
      { expiresIn: '24h' }
    );

    await logAdminAction({
      adminId: admin.id,
      adminUsername: admin.username,
      action: 'ADMIN_LOGIN',
      entityType: 'AdminUser',
      entityId: admin.id,
      ipAddress: req.ip,
    });

    res.json({
      message: 'Admin authentication successful',
      token,
      admin: {
        id: admin.id,
        username: admin.username,
        role: admin.role,
      },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/me', requireAdmin, (req: AdminAuthRequest, res: Response) => {
  res.json({ admin: req.admin });
});

// ==========================================
// 1.5 NOTIFICATIONS & PENDING QUANTITY COUNTS
// ==========================================

router.get(['/notifications/counts', '/pending-counts'], requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const [
      pendingTasks,
      pendingSpinsHistory,
      pendingSpinsEntitlement,
      pendingDeposits,
      pendingWithdrawals,
    ] = await Promise.all([
      prisma.taskSubmission.count({ where: { status: 'PENDING' } }),
      prisma.spinHistory.count({ where: { rewardStatus: 'PENDING' } }),
      prisma.userSpinEntitlement.count({ where: { requiresAdminReview: true, adminReviewed: false } }),
      prisma.depositRequest.count({ where: { status: 'PENDING' } }),
      prisma.withdrawalRequest.count({ where: { approvalStatus: 'PENDING' } }),
    ]);

    const pendingSpins = pendingSpinsHistory + pendingSpinsEntitlement;
    const total = pendingTasks + pendingSpins + pendingDeposits + pendingWithdrawals;

    res.json({
      success: true,
      counts: {
        total,
        tasks: pendingTasks,
        submissions: pendingTasks,
        spins: pendingSpins,
        deposits: pendingDeposits,
        withdrawals: pendingWithdrawals,
      },
    });
  } catch (error) {
    next(error);
  }
});

// ==========================================
// 2. ADMIN DASHBOARD & SUMMARY
// ==========================================

router.get('/dashboard', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const [
      totalUsers,
      activeUsers,
      totalTasks,
      pendingSubmissions,
      pendingDeposits,
      pendingWithdrawals,
      approvedDepositsSum,
      paidWithdrawalsSum,
      approvedRewardsSum,
      totalReferrals,
      recentActivity,
      recentTransactions,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { accountStatus: 'ACTIVE' } }),
      prisma.task.count(),
      prisma.taskSubmission.count({ where: { status: 'PENDING' } }),
      prisma.depositRequest.count({ where: { status: 'PENDING' } }),
      prisma.withdrawalRequest.count({ where: { approvalStatus: 'PENDING' } }),
      prisma.depositRequest.aggregate({
        where: { status: 'APPROVED' },
        _sum: { amount: true },
      }),
      prisma.withdrawalRequest.aggregate({
        where: { paymentStatus: 'PAID' },
        _sum: { amount: true },
      }),
      prisma.walletTransaction.aggregate({
        where: {
          transactionType: { in: ['TASK_REWARD', 'LEVEL_REWARD', 'REFERRAL_REWARD', 'SPIN_REWARD'] },
          status: 'COMPLETED',
        },
        _sum: { amount: true },
      }),
      prisma.referral.count(),
      prisma.adminAuditLog.findMany({
        orderBy: { createdAt: 'desc' },
        take: 8,
      }),
      prisma.walletTransaction.findMany({
        include: { user: { select: { name: true, phone: true } } },
        orderBy: { createdAt: 'desc' },
        take: 8,
      }),
    ]);

    res.json({
      metrics: {
        totalUsers,
        activeUsers,
        totalTasks,
        pendingSubmissions,
        pendingDeposits,
        pendingWithdrawals,
        totalDepositsAmount: approvedDepositsSum._sum.amount || 0,
        totalPaidWithdrawalsAmount: paidWithdrawalsSum._sum.amount || 0,
        totalApprovedRewardsAmount: approvedRewardsSum._sum.amount || 0,
        totalReferrals,
      },
      recentActivity,
      recentTransactions,
    });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 3. 10x10 TASK STATUS OVERVIEW GRID
// ==========================================

router.get('/tasks/grid', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: 'asc' },
      include: {
        tasks: {
          orderBy: { taskNumber: 'asc' },
          include: {
            submissions: {
              where: { status: 'PENDING' },
              select: { id: true },
            },
          },
        },
      },
    });

    const grid = levels.map((lvl) => {
      const tasksMap: any = {};
      for (let t = 1; t <= 10; t++) {
        const task = lvl.tasks.find((taskItem) => taskItem.taskNumber === t);
        if (task) {
          tasksMap[`task${t}`] = {
            id: task.id,
            taskNumber: t,
            title: task.title,
            rewardAmount: task.rewardAmount,
            isPaid: task.isPaid,
            unlockFee: task.unlockFee,
            status: task.status,
            pendingSubmissionsCount: task.submissions.length,
          };
        } else {
          tasksMap[`task${t}`] = {
            taskNumber: t,
            title: `Unconfigured Task ${t}`,
            status: 'UNCONFIGURED',
            pendingSubmissionsCount: 0,
          };
        }
      }

      return {
        levelId: lvl.id,
        levelNumber: lvl.levelNumber,
        levelTitle: lvl.title,
        levelStatus: lvl.status,
        tasks: tasksMap,
      };
    });

    res.json({ grid });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 4. USER MANAGEMENT
// ==========================================

router.get('/users', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const search = (req.query.search as string || '').trim();
    const status = (req.query.status as string || '').trim();
    const page = parseInt(req.query.page as string || '1', 10);
    const limit = parseInt(req.query.limit as string || '20', 10);
    const skip = (page - 1) * limit;

    const where: any = {};
    if (status) {
      where.accountStatus = status;
    }
    if (search) {
      where.OR = [
        { name: { contains: search } },
        { phone: { contains: search } },
        { referralCode: { contains: search } },
        { id: { contains: search } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        include: {
          wallet: true,
          _count: {
            select: {
              taskProgress: { where: { status: 'APPROVED' } },
              referrals: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.user.count({ where }),
    ]);

    const formattedUsers = users.map((u) => ({
      id: u.id,
      name: u.name,
      phone: u.phone,
      referralCode: u.referralCode,
      referredById: u.referredById,
      accountStatus: u.accountStatus,
      createdAt: u.createdAt,
      walletBalance: u.wallet?.availableBalance || 0,
      creditPoints: u.wallet?.creditPoints ?? 0,
      approvedTasksCount: u._count.taskProgress,
      referralsCount: u._count.referrals,
    }));

    res.json({
      users: formattedUsers,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/users/:userId', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const userId = req.params.userId as string;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        wallet: true,
        referredBy: { select: { id: true, name: true, phone: true } },
        levelProgress: { include: { level: true } },
        taskProgress: {
          include: { task: { include: { level: true } } },
          orderBy: { createdAt: 'desc' },
        },
        depositRequests: { orderBy: { createdAt: 'desc' }, take: 50 },
        withdrawalRequests: { orderBy: { createdAt: 'desc' }, take: 50 },
        transactions: { orderBy: { createdAt: 'desc' }, take: 50 },
        spinEntitlements: { include: { assignedPrize: true } },
        spinHistories: { include: { prize: true }, orderBy: { createdAt: 'desc' }, take: 50 },
        submissions: { include: { task: true }, orderBy: { createdAt: 'desc' }, take: 20 },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user });
  } catch (err) {
    next(err);
  }
});

router.put('/users/:userId/status', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const userId = req.params.userId as string;
    const { status, reason } = z.object({
      status: z.enum(['ACTIVE', 'SUSPENDED']),
      reason: z.string().optional(),
    }).parse(req.body);

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const updated = await prisma.user.update({
      where: { id: userId },
      data: { accountStatus: status },
      select: {
        id: true,
        name: true,
        phone: true,
        referralCode: true,
        accountStatus: true,
        updatedAt: true,
      },
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: status === 'ACTIVE' ? 'USER_REACTIVATED' : 'USER_SUSPENDED',
      entityType: 'User',
      entityId: user.id,
      previousState: { accountStatus: user.accountStatus },
      newState: { accountStatus: status },
      reason,
      ipAddress: req.ip,
    });

    // Notify user's active session without page reload
    sendUserLiveCommand(userId, 'user_updated', { accountStatus: status });

    res.json({ message: `User status updated to ${status}`, user: updated });
  } catch (err) {
    next(err);
  }
});

// Update specific fields of a single user (only modified fields are sent and updated)
router.patch('/users/:userId', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const userId = req.params.userId as string;
    const schema = z.object({
      name: z.string().trim().min(2, 'Name must be at least 2 characters').optional(),
      phone: z.string().trim().min(5, 'Phone must be at least 5 characters').optional(),
      accountStatus: z.enum(['ACTIVE', 'SUSPENDED']).optional(),
      reason: z.string().optional(),
    });
    const parsed = schema.parse(req.body);
    const { reason, ...fieldsToUpdate } = parsed;

    if (Object.keys(fieldsToUpdate).length === 0) {
      return res.status(400).json({ error: 'No fields provided to update' });
    }

    const existingUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, name: true, phone: true, accountStatus: true, referralCode: true },
    });
    if (!existingUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Only include actually changed fields in the Prisma/database update
    const updateData: Record<string, any> = {};
    const changedFields: Record<string, any> = {};
    const previousFields: Record<string, any> = {};

    for (const [key, val] of Object.entries(fieldsToUpdate)) {
      if (val !== undefined && (existingUser as any)[key] !== val) {
        updateData[key] = val;
        changedFields[key] = val;
        previousFields[key] = (existingUser as any)[key];
      }
    }

    if (Object.keys(updateData).length === 0) {
      return res.json({
        message: 'No changes detected. User profile is already up to date.',
        user: existingUser,
      });
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData,
      select: {
        id: true,
        name: true,
        phone: true,
        referralCode: true,
        accountStatus: true,
        updatedAt: true,
      },
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'ADMIN_UPDATE_USER_FIELDS',
      entityType: 'User',
      entityId: userId,
      previousState: previousFields,
      newState: changedFields,
      reason: reason || 'Admin updated user profile fields',
      ipAddress: req.ip,
    });

    // Notify user's active session without page reload
    sendUserLiveCommand(userId, 'user_updated', changedFields);

    res.json({
      message: 'User updated successfully',
      user: updatedUser,
    });
  } catch (err) {
    next(err);
  }
});

// Fetch summary for a single user entity without reloading all users or unrelated data
router.get('/users/:userId/summary', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const userId = req.params.userId as string;
    const u = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        phone: true,
        referralCode: true,
        referredById: true,
        accountStatus: true,
        createdAt: true,
        wallet: {
          select: {
            availableBalance: true,
            creditPoints: true,
          },
        },
        _count: {
          select: {
            taskProgress: { where: { status: 'APPROVED' } },
            referrals: true,
          },
        },
      },
    });

    if (!u) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      user: {
        id: u.id,
        name: u.name,
        phone: u.phone,
        referralCode: u.referralCode,
        referredById: u.referredById,
        accountStatus: u.accountStatus,
        createdAt: u.createdAt,
        walletBalance: u.wallet?.availableBalance || 0,
        creditPoints: u.wallet?.creditPoints ?? 0,
        approvedTasksCount: u._count.taskProgress,
        referralsCount: u._count.referrals,
      },
    });
  } catch (err) {
    next(err);
  }
});

router.post('/users/:userId/reset-password', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const userId = req.params.userId as string;
    const { temporaryPassword, requireChangeOnLogin, reason } = z.object({
      temporaryPassword: z.string().min(6, 'Temporary password must be at least 6 characters'),
      requireChangeOnLogin: z.boolean().default(true),
      reason: z.string().min(2, 'Reason for reset is required'),
    }).parse(req.body);

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const passwordHash = await bcrypt.hash(temporaryPassword, 10);
    await prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash,
        mustChangePassword: requireChangeOnLogin,
      },
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'ADMIN_RESET_USER_PASSWORD',
      entityType: 'User',
      entityId: user.id,
      reason,
      ipAddress: req.ip,
    });

    await prisma.notification.create({
      data: {
        userId: user.id,
        title: 'Security Notice: Password Reset by Admin 🔐',
        message: 'Your account password has been reset by an administrator. Please log in with your temporary credentials.',
        notificationType: 'PASSWORD_RESET',
      },
    });

    res.json({ message: 'User password reset successfully.' });
  } catch (err) {
    next(err);
  }
});

router.post('/users/:userId/adjust-balance', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const userId = req.params.userId as string;
    const { amount, actionType, reason, notes } = z.object({
      amount: z.number().positive('Adjustment amount must be positive'),
      actionType: z.enum(['CREDIT', 'DEBIT']),
      reason: z
        .string()
        .optional()
        .transform((v) => (v && v.trim() ? v.trim() : 'Admin Balance Adjustment')),
      notes: z.string().optional(),
    }).parse(req.body);

    const user: any = await prisma.user.findUnique({
      where: { id: userId },
      include: { wallet: true },
    });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const currentBalance = user.wallet?.availableBalance || 0;
    if (actionType === 'DEBIT' && currentBalance < amount) {
      return res.status(400).json({
        error: `Cannot debit PKR ${amount.toLocaleString()}. Current balance is only PKR ${currentBalance.toLocaleString()}. Negative balance is not allowed.`,
      });
    }

    const finalAmount = actionType === 'CREDIT' ? amount : -amount;
    const newBalance = currentBalance + finalAmount;

    const result = await prisma.$transaction(async (tx) => {
      const updatedWallet = await tx.wallet.update({
        where: { userId },
        data: {
          availableBalance: newBalance,
        },
      });

      const transaction = await tx.walletTransaction.create({
        data: {
          userId,
          transactionType: actionType === 'CREDIT' ? 'ADMIN_CREDIT' : 'ADMIN_DEBIT',
          amount: finalAmount,
          currency: 'PKR',
          status: 'COMPLETED',
          actorId: req.admin!.id,
          actorName: req.admin!.username,
          reason,
          notes,
        },
      });

      await tx.notification.create({
        data: {
          userId,
          title: `Account Balance Adjusted: ${actionType === 'CREDIT' ? '+' : '-'}PKR ${amount.toLocaleString()} 💰`,
          message: `Your balance was adjusted by administration. Reason: ${reason}`,
          notificationType: 'SYSTEM',
        },
      });

      return { wallet: updatedWallet, transaction };
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: actionType === 'CREDIT' ? 'ADMIN_BALANCE_CREDIT' : 'ADMIN_BALANCE_DEBIT',
      entityType: 'Wallet',
      entityId: result.wallet.id,
      previousState: { availableBalance: currentBalance },
      newState: { availableBalance: newBalance, adjustment: finalAmount },
      reason,
      ipAddress: req.ip,
    });

    // Notify user's active session without page reload
    sendUserLiveCommand(userId, 'wallet', { availableBalance: newBalance });

    res.json({
      message: `Successfully adjusted balance by ${actionType === 'CREDIT' ? '+' : '-'}PKR ${amount.toLocaleString()}`,
      wallet: {
        id: result.wallet.id,
        userId: result.wallet.userId,
        availableBalance: result.wallet.availableBalance,
        creditPoints: result.wallet.creditPoints,
      },
      transaction: result.transaction,
    });
  } catch (err) {
    next(err);
  }
});

router.post('/users/:userId/adjust-credit-points', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const userId = req.params.userId as string;
    const { points, actionType, reason, notes } = z.object({
      points: z.number().int().positive('Adjustment points must be a positive integer'),
      actionType: z.enum(['ADD', 'DEDUCT']),
      reason: z
        .string()
        .optional()
        .transform((v) => (v && v.trim() ? v.trim() : 'Admin Credit Points Adjustment')),
      notes: z.string().optional(),
    }).parse(req.body);

    const user: any = await prisma.user.findUnique({
      where: { id: userId },
      include: { wallet: true },
    });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const currentPoints = user.wallet?.creditPoints || 0;
    if (actionType === 'DEDUCT' && currentPoints < points) {
      return res.status(400).json({
        error: `Cannot deduct ${points} credit points. Current balance is only ${currentPoints} CPs. Negative credit points are not allowed.`,
      });
    }

    const finalPointsDelta = actionType === 'ADD' ? points : -points;
    const newPoints = currentPoints + finalPointsDelta;

    const result = await prisma.$transaction(async (tx) => {
      const updatedWallet = await tx.wallet.update({
        where: { userId },
        data: {
          creditPoints: newPoints,
        },
      });

      await tx.notification.create({
        data: {
          userId,
          title: `Credit Points Adjusted: ${actionType === 'ADD' ? '+' : '-'}${points} CPs 🎯`,
          message: `Your credit points balance was adjusted by administration. Reason: ${reason}. New balance: ${newPoints} CPs.`,
          notificationType: 'SYSTEM',
        },
      });

      return { wallet: updatedWallet };
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: actionType === 'ADD' ? 'ADMIN_CREDIT_POINTS_ADD' : 'ADMIN_CREDIT_POINTS_DEDUCT',
      entityType: 'Wallet',
      entityId: result.wallet.id,
      previousState: { creditPoints: currentPoints },
      newState: { creditPoints: newPoints, adjustment: finalPointsDelta },
      reason,
      ipAddress: req.ip,
    });

    // Notify user's active session without page reload
    sendUserLiveCommand(userId, 'wallet', { creditPoints: newPoints });

    res.json({
      message: `Successfully ${actionType === 'ADD' ? 'added' : 'deducted'} ${points} credit points. New balance: ${newPoints} CPs.`,
      creditPoints: newPoints,
      wallet: {
        id: result.wallet.id,
        userId: result.wallet.userId,
        creditPoints: result.wallet.creditPoints,
        availableBalance: result.wallet.availableBalance,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 5. TASK MANAGEMENT & EDITING MODAL
// ==========================================

router.get('/tasks', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const levelNumber = req.query.level ? parseInt(req.query.level as string, 10) : undefined;
    const search = (req.query.search as string || '').trim();

    const where: any = {};
    if (levelNumber) {
      where.level = { levelNumber };
    }
    if (search) {
      where.OR = [
        { title: { contains: search } },
        { taskType: { contains: search } },
        { description: { contains: search } },
      ];
    }

    const tasks = await prisma.task.findMany({
      where,
      include: {
        level: true,
        _count: {
          select: {
            submissions: { where: { status: 'PENDING' } },
          },
        },
      },
      orderBy: [
        { level: { levelNumber: 'asc' } },
        { taskNumber: 'asc' },
      ],
    });

    res.json({ tasks });
  } catch (err) {
    next(err);
  }
});

router.put('/tasks/:taskId', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const taskId = req.params.taskId as string;
    const schema = z.object({
      title: z.string().min(2, 'Task title is required'),
      description: z.string().min(5, 'Task description is required'),
      taskType: z.string().min(2, 'Task type is required'),
      rewardAmount: z.number().nonnegative('Reward must be 0 or positive'),
      isPaid: z.boolean(),
      unlockFee: z.number().nonnegative('Unlock fee cannot be negative'),
      protectedUrl: z.string().optional().nullable(),
      instructions: z.string().min(5, 'Instructions are required'),
      lockMessage: z.string().min(5, 'Lock message is required'),
      submissionInstructions: z.string().min(5, 'Submission instructions are required'),
      externalContact: z.string().optional().nullable(),
      requiresAdminApproval: z.boolean(),
      status: z.enum(['ACTIVE', 'DISABLED']),
    });

    const validated = schema.parse(req.body);

    const existingTask = await prisma.task.findUnique({ where: { id: taskId } });
    if (!existingTask) return res.status(404).json({ error: 'Task not found' });

    const updatedTask = await prisma.task.update({
      where: { id: taskId },
      data: {
        ...validated,
        unlockFee: validated.isPaid ? validated.unlockFee : 0,
      },
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'TASK_UPDATED',
      entityType: 'Task',
      entityId: taskId,
      previousState: existingTask,
      newState: updatedTask,
      ipAddress: req.ip,
    });

    res.json({ message: 'Task configuration updated successfully', task: updatedTask });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 6. LEVEL MANAGEMENT
// ==========================================

router.get('/levels', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: 'asc' },
      include: {
        tasks: { orderBy: { taskNumber: 'asc' } },
        _count: { select: { userProgress: true } },
      },
    });

    res.json({ levels });
  } catch (err) {
    next(err);
  }
});

router.put('/levels/:levelId', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const levelId = req.params.levelId as string;
    const schema = z.object({
      title: z.string().min(2),
      description: z.string().min(5),
      completionReward: z.number().nonnegative(),
      status: z.enum(['ACTIVE', 'DISABLED']),
    });

    const validated = schema.parse(req.body);
    const existing = await prisma.level.findUnique({ where: { id: levelId } });
    if (!existing) return res.status(404).json({ error: 'Level not found' });

    const updated = await prisma.level.update({
      where: { id: levelId },
      data: validated,
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'LEVEL_UPDATED',
      entityType: 'Level',
      entityId: levelId,
      previousState: existing,
      newState: updated,
      ipAddress: req.ip,
    });

    res.json({ message: 'Level updated successfully', level: updated });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 7. TASK SUBMISSION VERIFICATION
// ==========================================

router.get('/submissions', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const status = (req.query.status as string || '').trim();
    const levelNumber = req.query.level ? parseInt(req.query.level as string, 10) : undefined;
    const page = parseInt(req.query.page as string || '1', 10);
    const limit = parseInt(req.query.limit as string || '20', 10);
    const skip = (page - 1) * limit;

    const where: any = {};
    if (status) where.status = status;
    if (levelNumber) where.task = { level: { levelNumber } };

    const [submissions, total] = await Promise.all([
      prisma.taskSubmission.findMany({
        where,
        include: {
          user: { select: { id: true, name: true, phone: true } },
          task: { include: { level: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.taskSubmission.count({ where }),
    ]);

    res.json({
      submissions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
});

router.put('/submissions/:submissionId/review', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const submissionId = req.params.submissionId as string;
    const { action, reviewNotes, rejectionReason } = z.object({
      action: z.enum(['APPROVE', 'REJECT']),
      reviewNotes: z.string().optional(),
      rejectionReason: z.string().optional(),
    }).parse(req.body);

    const submission: any = await prisma.taskSubmission.findUnique({
      where: { id: submissionId },
      include: {
        task: { include: { level: true } },
        user: true,
      },
    });

    if (!submission) return res.status(404).json({ error: 'Submission not found' });
    if (submission.status !== 'PENDING') {
      return res.status(400).json({ error: `This submission has already been reviewed (Status: ${submission.status})` });
    }

    const { user, task } = submission;

    if (action === 'APPROVE') {
      // 1. Credit reward to wallet exactly once
      // 2. Mark submission APPROVED
      // 3. Mark UserTaskProgress APPROVED
      // 4. Update Level Progress
      // 5. Notify user
      const isPrepaidTask = Boolean(
        task.isPaid ||
        (task.unlockFee && task.unlockFee > 0) ||
        task.taskType?.toLowerCase().includes('prepaid') ||
        task.taskNumber === 5 ||
        task.taskNumber === 10 ||
        task.taskNumber === 15 ||
        task.taskNumber === 20
      );
      const creditPointsToAdd = isPrepaidTask
        ? (task.creditPoints && task.creditPoints > 5 ? Number(task.creditPoints) : 30)
        : (task.creditPoints && task.creditPoints > 0 ? Number(task.creditPoints) : 5);
      const taskRewardToAdd = Number(task.rewardAmount || 0);

      const result = await prisma.$transaction(async (tx) => {
        // Update submission
        const updatedSub = await tx.taskSubmission.update({
          where: { id: submissionId },
          data: {
            status: 'APPROVED',
            reviewerId: req.admin!.id,
            reviewerName: req.admin!.username,
            reviewNotes: reviewNotes || null,
          },
        });

        // Check if task was ALREADY approved for this user before incrementing
        const existingProgress = await tx.userTaskProgress.findUnique({
          where: { userId_taskId: { userId: user.id, taskId: task.id } },
        });
        const wasAlreadyApproved = existingProgress?.status === 'APPROVED';

        // Update UserTaskProgress
        await tx.userTaskProgress.upsert({
          where: { userId_taskId: { userId: user.id, taskId: task.id } },
          update: {
            status: 'APPROVED',
            approvedAt: new Date(),
            reviewerId: req.admin!.id,
          },
          create: {
            userId: user.id,
            taskId: task.id,
            status: 'APPROVED',
            approvedAt: new Date(),
            reviewerId: req.admin!.id,
          },
        });

        // Resolve any other pending submissions for this task
        await tx.taskSubmission.updateMany({
          where: {
            userId: user.id,
            taskId: task.id,
            status: 'PENDING',
            id: { not: submissionId },
          },
          data: {
            status: 'APPROVED',
            reviewerId: req.admin!.id,
            reviewerName: req.admin!.username,
            reviewNotes: 'Auto-resolved with task approval',
          },
        });

        // Credit credit points and PKR task reward directly to wallet ONLY if not already approved
        let updatedWallet: any = await tx.wallet.findUnique({ where: { userId: user.id } });

        if (!wasAlreadyApproved) {
          const walletUpdateData: any = {
            creditPoints: { increment: creditPointsToAdd },
          };
          if (taskRewardToAdd > 0) {
            walletUpdateData.availableBalance = { increment: taskRewardToAdd };
            walletUpdateData.totalEarned = { increment: taskRewardToAdd };
          }

          updatedWallet = await tx.wallet.update({
            where: { userId: user.id },
            data: walletUpdateData,
          });

          if (taskRewardToAdd > 0) {
            await tx.walletTransaction.create({
              data: {
                userId: user.id,
                transactionType: 'TASK_REWARD',
                amount: taskRewardToAdd,
                currency: 'PKR',
                status: 'COMPLETED',
                relatedEntityId: task.id,
                actorId: req.admin!.id,
                actorName: req.admin!.username,
                reason: `Task #${task.taskNumber} (${task.title}) Reward Credited`,
                notes: `Task reward of PKR ${taskRewardToAdd.toLocaleString()} credited upon admin approval. Account balance updated to PKR ${updatedWallet.availableBalance.toLocaleString()}`,
              },
            });
          }
        }

        // Notification
        const rewardNotice = taskRewardToAdd > 0 ? ` + PKR ${taskRewardToAdd.toLocaleString()} Balance &` : '';
        await tx.notification.create({
          data: {
            userId: user.id,
            title: `Task Approved!${rewardNotice} +${creditPointsToAdd} Points 🎉`,
            message: `Your task "${task.title}" was approved by administrator ${req.admin!.username}.${taskRewardToAdd > 0 ? ` PKR ${taskRewardToAdd.toLocaleString()} has been directly credited to your account balance!` : ''} You earned +${creditPointsToAdd} credit points! The next sequential task is now unlocked.`,
            notificationType: 'TASK_STATUS',
          },
        });

        // Level Completion Milestone: Trigger a Free Spin entitlement strictly when ALL tasks in the level are approved (Level completed)
        const requiredCount = task.level.requiredTaskCount || 10;
        const approvedTasksInLevel = await tx.taskSubmission.count({
          where: {
            userId: user.id,
            task: { levelId: task.levelId },
            status: 'APPROVED',
          },
        });
        const isLevelFullyCompleted = approvedTasksInLevel >= requiredCount;
        if (isLevelFullyCompleted) {
          const milestoneReason = `Level ${task.level.levelNumber} Completion Free Spin`;
          const existingEntitlement = await tx.userSpinEntitlement.findFirst({
            where: {
              userId: user.id,
              levelNumber: task.level.levelNumber,
            },
          });

          if (!existingEntitlement) {
            await tx.userSpinEntitlement.create({
              data: {
                userId: user.id,
                levelNumber: task.level.levelNumber,
                taskNumber: requiredCount,
                triggerReason: milestoneReason,
                totalSpins: 1,
                remainingSpins: 1,
                isEligible: false, // Goes to admin first to assign the prize outcome
                requiresAdminReview: true,
                adminReviewed: false,
                assignedPrizeId: null,
              },
            });

            await tx.notification.create({
              data: {
                userId: user.id,
                title: `Level ${task.level.levelNumber} Completed! Free Spin Earned! 🎡`,
                message: `Congratulations! Completing Level ${task.level.levelNumber} earned you a Free Royal Spin! Your entitlement is submitted to administration to assign your reward.`,
                notificationType: 'SPIN_REWARD',
              },
            });
          }
        }

        return { updatedSub, updatedWallet };
      });

      const { updatedSub, updatedWallet } = result;

      // Update level progression and check for level completion
      await taskProgressionService.updateLevelProgress(user.id, task.levelId);

      // Check and qualify referral if applicable
      await affiliateService.checkAndQualifyReferral(user.id, 'TASK_APPROVED');

      await logAdminAction({
        adminId: req.admin!.id,
        adminUsername: req.admin!.username,
        action: 'TASK_SUBMISSION_APPROVED',
        entityType: 'TaskSubmission',
        entityId: submissionId,
        newState: {
          status: 'APPROVED',
          rewardAmount: task.rewardAmount,
          creditPoints: creditPointsToAdd,
          newBalance: updatedWallet.availableBalance,
        },
        reason: reviewNotes,
        ipAddress: req.ip,
      });

      sendUserLiveCommand(user.id, 'wallet', {
        availableBalance: updatedWallet.availableBalance,
        totalEarned: updatedWallet.totalEarned,
        creditPoints: updatedWallet.creditPoints,
      });
      sendUserLiveCommand(user.id, 'task', { submissionId, taskId: task.id, status: 'APPROVED' });
      sendUserLiveCommand(user.id, 'refresh', { type: 'TASK_APPROVED' });

      res.json({ message: 'Task approved and reward credited successfully!', submission: updatedSub, wallet: updatedWallet });
    } else {
      // REJECT
      const updatedSub = await prisma.$transaction(async (tx) => {
        const sub = await tx.taskSubmission.update({
          where: { id: submissionId },
          data: {
            status: 'REJECTED',
            reviewerId: req.admin!.id,
            reviewerName: req.admin!.username,
            reviewNotes: reviewNotes || null,
            rejectionReason: rejectionReason || 'Verification requirements not satisfied',
          },
        });

        await tx.userTaskProgress.upsert({
          where: { userId_taskId: { userId: user.id, taskId: task.id } },
          update: {
            status: 'REJECTED',
            rejectionReason: rejectionReason || 'Verification requirements not satisfied',
          },
          create: {
            userId: user.id,
            taskId: task.id,
            status: 'REJECTED',
            rejectionReason: rejectionReason || 'Verification requirements not satisfied',
          },
        });

        await tx.notification.create({
          data: {
            userId: user.id,
            title: `Task Submission Rejected ❌`,
            message: `Your submission for "${task.title}" was rejected. Reason: ${rejectionReason || 'Please resubmit with clear proof.'}`,
            notificationType: 'TASK_STATUS',
          },
        });

        return sub;
      });

      await logAdminAction({
        adminId: req.admin!.id,
        adminUsername: req.admin!.username,
        action: 'TASK_SUBMISSION_REJECTED',
        entityType: 'TaskSubmission',
        entityId: submissionId,
        newState: { status: 'REJECTED', rejectionReason },
        reason: reviewNotes,
        ipAddress: req.ip,
      });

      res.json({ message: 'Task submission rejected.', submission: updatedSub });
    }
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 8. DEPOSIT MANAGEMENT
// ==========================================

router.get('/deposits', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const status = (req.query.status as string || '').trim();
    const page = parseInt(req.query.page as string || '1', 10);
    const limit = parseInt(req.query.limit as string || '20', 10);
    const skip = (page - 1) * limit;

    const where: any = {};
    if (status) where.status = status;

    const [deposits, total] = await Promise.all([
      prisma.depositRequest.findMany({
        where,
        include: { user: { select: { id: true, name: true, phone: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.depositRequest.count({ where }),
    ]);

    res.json({
      deposits,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
});

router.put('/deposits/:depositId/review', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const depositId = req.params.depositId as string;
    const { action, reviewNotes } = z.object({
      action: z.enum(['APPROVE', 'REJECT']),
      reviewNotes: z.string().optional(),
    }).parse(req.body);

    const deposit = await prisma.depositRequest.findUnique({
      where: { id: depositId },
      include: { user: true },
    });

    if (!deposit) return res.status(404).json({ error: 'Deposit request not found' });
    if (deposit.status !== 'PENDING') {
      return res.status(400).json({ error: `This deposit has already been reviewed (Status: ${deposit.status})` });
    }

    if (action === 'APPROVE') {
      // Atomic approval & wallet credit
      const result = await prisma.$transaction(async (tx) => {
        const updatedDep = await tx.depositRequest.update({
          where: { id: depositId },
          data: {
            status: 'APPROVED',
            reviewerId: req.admin!.id,
            reviewerName: req.admin!.username,
            reviewNotes: reviewNotes || null,
          },
        });

        // Credit availableBalance and totalDeposited
        await tx.wallet.update({
          where: { userId: deposit.userId },
          data: {
            availableBalance: { increment: deposit.amount },
            totalDeposited: { increment: deposit.amount },
          },
        });

        // Immutable ledger record
        await tx.walletTransaction.create({
          data: {
            userId: deposit.userId,
            transactionType: 'DEPOSIT_CREDIT',
            amount: deposit.amount,
            currency: 'PKR',
            status: 'COMPLETED',
            relatedEntityId: deposit.id,
            actorId: req.admin!.id,
            actorName: req.admin!.username,
            reason: `Deposit approved via ${deposit.paymentMethod} (Ref: ${deposit.transactionReference})`,
            notes: reviewNotes,
          },
        });

        // Notification
        await tx.notification.create({
          data: {
            userId: deposit.userId,
            title: `Deposit Approved: PKR ${deposit.amount.toLocaleString()} ✅`,
            message: `Your deposit of PKR ${deposit.amount.toLocaleString()} has been approved and added to your available balance.`,
            notificationType: 'DEPOSIT_STATUS',
          },
        });

        return updatedDep;
      });

      await logAdminAction({
        adminId: req.admin!.id,
        adminUsername: req.admin!.username,
        action: 'DEPOSIT_APPROVED',
        entityType: 'DepositRequest',
        entityId: depositId,
        newState: { status: 'APPROVED', amount: deposit.amount },
        reason: reviewNotes,
        ipAddress: req.ip,
      });

      // Check and qualify referral if qualification criteria is deposit-based
      await affiliateService.checkAndQualifyReferral(deposit.userId, 'DEPOSIT_APPROVED');

      sendUserLiveCommand(deposit.userId, 'wallet', {
        type: 'DEPOSIT_APPROVED',
        depositId: deposit.id,
        amount: deposit.amount,
      });

      res.json({ message: `Deposit of PKR ${deposit.amount.toLocaleString()} approved and credited!`, deposit: result });
    } else {
      // REJECT
      const updatedDep = await prisma.$transaction(async (tx) => {
        const dep = await tx.depositRequest.update({
          where: { id: depositId },
          data: {
            status: 'REJECTED',
            reviewerId: req.admin!.id,
            reviewerName: req.admin!.username,
            reviewNotes: reviewNotes || 'Transaction details could not be verified',
          },
        });

        await tx.notification.create({
          data: {
            userId: deposit.userId,
            title: `Deposit Rejected ❌`,
            message: `Your deposit request for PKR ${deposit.amount.toLocaleString()} was rejected. Reason: ${reviewNotes || 'Verification unconfirmed.'}`,
            notificationType: 'DEPOSIT_STATUS',
          },
        });

        return dep;
      });

      await logAdminAction({
        adminId: req.admin!.id,
        adminUsername: req.admin!.username,
        action: 'DEPOSIT_REJECTED',
        entityType: 'DepositRequest',
        entityId: depositId,
        newState: { status: 'REJECTED' },
        reason: reviewNotes,
        ipAddress: req.ip,
      });

      sendUserLiveCommand(deposit.userId, 'wallet', {
        type: 'DEPOSIT_REJECTED',
        depositId: deposit.id,
      });

      res.json({ message: 'Deposit request rejected.', deposit: updatedDep });
    }
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 9. WITHDRAWAL MANAGEMENT
// ==========================================

router.get('/withdrawals', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const approvalStatus = (req.query.approvalStatus as string || '').trim();
    const paymentStatus = (req.query.paymentStatus as string || '').trim();
    const page = parseInt(req.query.page as string || '1', 10);
    const limit = parseInt(req.query.limit as string || '20', 10);
    const skip = (page - 1) * limit;

    const where: any = {};
    if (approvalStatus) where.approvalStatus = approvalStatus;
    if (paymentStatus) where.paymentStatus = paymentStatus;

    const [withdrawals, total] = await Promise.all([
      prisma.withdrawalRequest.findMany({
        where,
        include: { user: { select: { id: true, name: true, phone: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.withdrawalRequest.count({ where }),
    ]);

    res.json({
      withdrawals,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
});

router.put('/withdrawals/:withdrawalId/review', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const withdrawalId = req.params.withdrawalId as string;
    const { action, reviewNotes } = z.object({
      action: z.enum(['APPROVE', 'REJECT']),
      reviewNotes: z.string().optional(),
    }).parse(req.body);

    const withdrawal = await prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: { user: true },
    });

    if (!withdrawal) return res.status(404).json({ error: 'Withdrawal not found' });
    if (withdrawal.approvalStatus !== 'PENDING') {
      return res.status(400).json({ error: `Withdrawal has already been reviewed (Status: ${withdrawal.approvalStatus})` });
    }

    if (action === 'APPROVE') {
      // Mark Approved (Payment remains NOT_SENT until admin actually sends funds)
      const updated = await prisma.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          approvalStatus: 'APPROVED',
          paymentStatus: 'NOT_SENT',
          reviewerId: req.admin!.id,
          reviewerName: req.admin!.username,
          reviewNotes: reviewNotes || null,
        },
      });

      await prisma.notification.create({
        data: {
          userId: withdrawal.userId,
          title: `Withdrawal Approved! ✅`,
          message: `Your withdrawal of PKR ${withdrawal.amount.toLocaleString()} has been approved. Payment processing is underway.`,
          notificationType: 'WITHDRAWAL_STATUS',
        },
      });

      await logAdminAction({
        adminId: req.admin!.id,
        adminUsername: req.admin!.username,
        action: 'WITHDRAWAL_APPROVED',
        entityType: 'WithdrawalRequest',
        entityId: withdrawalId,
        newState: { approvalStatus: 'APPROVED', paymentStatus: 'NOT_SENT' },
        reason: reviewNotes,
        ipAddress: req.ip,
      });

      res.json({ message: 'Withdrawal approved. Status is now Approved (Not Sent).', withdrawal: updated });
    } else {
      // REJECT: Release reserved balance back to available balance!
      const updated = await prisma.$transaction(async (tx) => {
        const reqRec = await tx.withdrawalRequest.update({
          where: { id: withdrawalId },
          data: {
            approvalStatus: 'REJECTED',
            paymentStatus: 'FAILED',
            reviewerId: req.admin!.id,
            reviewerName: req.admin!.username,
            reviewNotes: reviewNotes || 'Withdrawal rejected by administrator',
          },
        });

        // Release reserved funds back to available balance
        await tx.wallet.update({
          where: { userId: withdrawal.userId },
          data: {
            availableBalance: { increment: withdrawal.amount },
            pendingBalance: { decrement: withdrawal.amount },
          },
        });

        // Reversal ledger record
        await tx.walletTransaction.create({
          data: {
            userId: withdrawal.userId,
            transactionType: 'WITHDRAWAL_REVERSAL',
            amount: withdrawal.amount,
            currency: 'PKR',
            status: 'COMPLETED',
            relatedEntityId: withdrawal.id,
            actorId: req.admin!.id,
            actorName: req.admin!.username,
            reason: `Reservation refund for rejected withdrawal #${withdrawal.id.slice(-6)}`,
            notes: reviewNotes,
          },
        });

        await tx.notification.create({
          data: {
            userId: withdrawal.userId,
            title: `Withdrawal Rejected - Funds Restored 🔄`,
            message: `Your withdrawal of PKR ${withdrawal.amount.toLocaleString()} was rejected. Reserved funds have been restored to your available balance.`,
            notificationType: 'WITHDRAWAL_STATUS',
          },
        });

        return reqRec;
      });

      await logAdminAction({
        adminId: req.admin!.id,
        adminUsername: req.admin!.username,
        action: 'WITHDRAWAL_REJECTED',
        entityType: 'WithdrawalRequest',
        entityId: withdrawalId,
        newState: { approvalStatus: 'REJECTED' },
        reason: reviewNotes,
        ipAddress: req.ip,
      });

      res.json({ message: 'Withdrawal rejected and funds restored to user.', withdrawal: updated });
    }
  } catch (err) {
    next(err);
  }
});

router.put('/withdrawals/:withdrawalId/payout', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const withdrawalId = req.params.withdrawalId as string;
    const { payoutReference, reviewNotes } = z.object({
      payoutReference: z.string().min(2, 'Payout transaction reference / Trx ID is required'),
      reviewNotes: z.string().optional(),
    }).parse(req.body);

    const withdrawal = await prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: { user: true },
    });

    if (!withdrawal) return res.status(404).json({ error: 'Withdrawal not found' });
    if (withdrawal.approvalStatus !== 'APPROVED') {
      return res.status(400).json({ error: 'Withdrawal must be approved before marking as Paid' });
    }
    if (withdrawal.paymentStatus === 'PAID') {
      return res.status(400).json({ error: 'This withdrawal has already been marked as Paid' });
    }

    // Finalize payment: deduct from pendingBalance, increment totalWithdrawn
    const result = await prisma.$transaction(async (tx) => {
      const updatedReq = await tx.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          paymentStatus: 'PAID',
          payoutReference: payoutReference.trim(),
          reviewNotes: reviewNotes || withdrawal.reviewNotes,
        },
      });

      await tx.wallet.update({
        where: { userId: withdrawal.userId },
        data: {
          pendingBalance: { decrement: withdrawal.amount },
          totalWithdrawn: { increment: withdrawal.amount },
        },
      });

      await tx.walletTransaction.create({
        data: {
          userId: withdrawal.userId,
          transactionType: 'WITHDRAWAL_PAID',
          amount: -withdrawal.amount,
          currency: 'PKR',
          status: 'COMPLETED',
          relatedEntityId: withdrawal.id,
          actorId: req.admin!.id,
          actorName: req.admin!.username,
          reason: `Payout disbursed via ${withdrawal.paymentMethod} (Payout Ref: ${payoutReference.trim()})`,
          notes: reviewNotes,
        },
      });

      await tx.notification.create({
        data: {
          userId: withdrawal.userId,
          title: `Withdrawal Disbursed: PKR ${withdrawal.amount.toLocaleString()} 💸`,
          message: `Your payment of PKR ${withdrawal.amount.toLocaleString()} has been sent! Trx Reference: ${payoutReference.trim()}`,
          notificationType: 'WITHDRAWAL_STATUS',
        },
      });

      return updatedReq;
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'WITHDRAWAL_MARKED_PAID',
      entityType: 'WithdrawalRequest',
      entityId: withdrawalId,
      newState: { paymentStatus: 'PAID', payoutReference },
      reason: reviewNotes,
      ipAddress: req.ip,
    });

    res.json({ message: 'Withdrawal successfully marked as Paid!', withdrawal: result });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 10. SPIN WHEEL MANAGEMENT
// ==========================================

router.get('/spin', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const [prizes, entitlements, pendingMilestones, history] = await Promise.all([
      ensureOfficialSpinPrizes(),
      prisma.userSpinEntitlement.findMany({
        include: {
          user: { select: { id: true, name: true, phone: true } },
          assignedPrize: true,
        },
        orderBy: { createdAt: 'desc' },
        take: 30,
      }),
      prisma.userSpinEntitlement.findMany({
        where: {
          requiresAdminReview: true,
          adminReviewed: false,
          remainingSpins: { gt: 0 },
        },
        include: {
          user: { select: { id: true, name: true, phone: true } },
          assignedPrize: true,
        },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.spinHistory.findMany({
        include: {
          user: { select: { id: true, name: true, phone: true } },
          prize: true,
        },
        orderBy: { createdAt: 'desc' },
        take: 30,
      }),
    ]);

    const spinSetting = await prisma.siteSetting.findUnique({ where: { key: 'spin_enabled' } });

    res.json({
      isSpinEnabled: spinSetting?.value === 'true',
      prizes,
      entitlements,
      pendingMilestones,
      history,
    });
  } catch (err) {
    next(err);
  }
});

router.post('/spin/assign', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const { userId, assignedPrizeId, totalSpins, isEligible } = z.object({
      userId: z.string().min(1, 'User is required'),
      assignedPrizeId: z.string().optional().nullable(),
      totalSpins: z.number().int().positive('Total spins must be at least 1'),
      isEligible: z.boolean().default(true),
    }).parse(req.body);

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    let prize = null;
    if (assignedPrizeId) {
      prize = await prisma.spinPrize.findUnique({ where: { id: assignedPrizeId } });
    }

    const entitlement = await prisma.userSpinEntitlement.create({
      data: {
        userId,
        assignedPrizeId: prize?.id || null,
        totalSpins,
        remainingSpins: totalSpins,
        isEligible,
      },
    });

    await prisma.notification.create({
      data: {
        userId,
        title: `Royal Spin Entitlement Granted! 🎡`,
        message: `An administrator granted you ${totalSpins} royal spin(s)! Spin the wheel now to claim your reward.`,
        notificationType: 'SPIN_REWARD',
      },
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'SPIN_ENTITLEMENT_ASSIGNED',
      entityType: 'UserSpinEntitlement',
      entityId: entitlement.id,
      newState: { userId, assignedPrize: prize?.name || 'Random', totalSpins },
      ipAddress: req.ip,
    });

    sendUserLiveCommand(userId, 'spin', { totalSpins });

    res.status(201).json({ message: 'Spin entitlement assigned successfully!', entitlement });
  } catch (err) {
    next(err);
  }
});

router.put('/spin/entitlements/:entitlementId/assign', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const entitlementId = req.params.entitlementId as string;
    const { assignedPrizeId } = z.object({
      assignedPrizeId: z.string().min(1, 'Assigned prize is required'),
    }).parse(req.body);

    const prize = await prisma.spinPrize.findUnique({ where: { id: assignedPrizeId } });
    if (!prize) return res.status(404).json({ error: 'Selected prize not found' });

    const entitlement = await prisma.userSpinEntitlement.update({
      where: { id: entitlementId },
      data: {
        assignedPrizeId,
        isEligible: true,
        adminReviewed: true,
      },
      include: { user: true, assignedPrize: true },
    });

    await prisma.notification.create({
      data: {
        userId: entitlement.userId,
        title: `Royal Spin Unlocked! 🎡`,
        message: `Your free milestone spin for ${entitlement.triggerReason || 'task progress'} has been prepared by administration! Visit the Royal Spin Wheel now to claim your prize!`,
        notificationType: 'SPIN_REWARD',
      },
    });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'SPIN_PRIZE_ASSIGNED',
      entityType: 'UserSpinEntitlement',
      entityId: entitlement.id,
      newState: { assignedPrize: prize.name, isEligible: true },
      ipAddress: req.ip,
    });

    sendUserLiveCommand(entitlement.userId, 'spin', { entitlementId: entitlement.id, prize: prize.name });

    res.json({ message: `Prize ${prize.name} assigned and spin unlocked for ${entitlement.user.name}!`, entitlement });
  } catch (err) {
    next(err);
  }
});

router.post('/spin/prizes', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const schema = z.object({
      name: z.string().min(2),
      prizeType: z.enum(['CASH', 'PHYSICAL', 'BONUS']),
      monetaryValue: z.number().nonnegative(),
      displayLabel: z.string().min(1),
      color: z.string().min(4),
      icon: z.string().optional(),
      inventory: z.number().int().nonnegative().default(999999),
      status: z.enum(['ACTIVE', 'INACTIVE']).default('ACTIVE'),
    });
    const validated = schema.parse(req.body);

    const prize = await prisma.spinPrize.create({ data: validated });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'SPIN_PRIZE_CREATED',
      entityType: 'SpinPrize',
      entityId: prize.id,
      newState: prize,
      ipAddress: req.ip,
    });

    res.status(201).json({ message: 'Prize created successfully', prize });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 11. REFERRALS & TRANSACTIONS
// ==========================================

router.get('/referrals', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const referrals = await prisma.referral.findMany({
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    // Resolve user names
    const userIds = Array.from(new Set([...referrals.map((r) => r.referrerId), ...referrals.map((r) => r.referredId)]));
    const users = await prisma.user.findMany({
      where: { id: { in: userIds } },
      select: { id: true, name: true, phone: true, referralCode: true },
    });
    const userMap = new Map(users.map((u) => [u.id, u]));

    const formatted = referrals.map((r) => ({
      id: r.id,
      referrer: userMap.get(r.referrerId) || { name: 'Unknown', phone: 'N/A' },
      referee: userMap.get(r.referredId) || { name: 'Unknown', phone: 'N/A' },
      qualifyingStatus: r.qualifyingStatus,
      rewardStatus: r.rewardStatus,
      rewardAmount: r.rewardAmount,
      createdAt: r.createdAt,
    }));

    res.json({ referrals: formatted });
  } catch (err) {
    next(err);
  }
});

router.get('/transactions', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const transactionType = (req.query.type as string || '').trim();
    const page = parseInt(req.query.page as string || '1', 10);
    const limit = parseInt(req.query.limit as string || '20', 10);
    const skip = (page - 1) * limit;

    const where: any = {};
    if (transactionType) where.transactionType = transactionType;

    const [transactions, total] = await Promise.all([
      prisma.walletTransaction.findMany({
        where,
        include: { user: { select: { id: true, name: true, phone: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.walletTransaction.count({ where }),
    ]);

    res.json({
      transactions,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 12. ANNOUNCEMENTS & SETTINGS
// ==========================================

router.get('/announcements', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const announcements = await prisma.announcement.findMany({
      orderBy: { createdAt: 'desc' },
    });
    res.json({ announcements });
  } catch (err) {
    next(err);
  }
});

router.post('/announcements', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const schema = z.object({
      title: z.string().min(2),
      content: z.string().min(5),
      audience: z.enum(['ALL', 'USERS']).default('ALL'),
      status: z.enum(['ACTIVE', 'INACTIVE']).default('ACTIVE'),
    });
    const validated = schema.parse(req.body);

    const announcement = await prisma.announcement.create({ data: validated });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'ANNOUNCEMENT_CREATED',
      entityType: 'Announcement',
      entityId: announcement.id,
      newState: announcement,
      ipAddress: req.ip,
    });

    res.status(201).json({ message: 'Announcement published', announcement });
  } catch (err) {
    next(err);
  }
});

router.delete('/announcements/:id', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const id = req.params.id as string;
    await prisma.announcement.delete({ where: { id } });

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'ANNOUNCEMENT_DELETED',
      entityType: 'Announcement',
      entityId: id,
      ipAddress: req.ip,
    });

    res.json({ message: 'Announcement deleted' });
  } catch (err) {
    next(err);
  }
});

router.get('/settings', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const settings = await prisma.siteSetting.findMany({
      orderBy: { category: 'asc' },
    });
    res.json({ settings });
  } catch (err) {
    next(err);
  }
});

router.put('/settings', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const { settings } = z.object({
      settings: z.array(
        z.object({
          key: z.string(),
          value: z.string(),
        })
      ),
    }).parse(req.body);

    for (const item of settings) {
      await prisma.siteSetting.upsert({
        where: { key: item.key },
        update: { value: item.value },
        create: { key: item.key, value: item.value },
      });
    }

    await logAdminAction({
      adminId: req.admin!.id,
      adminUsername: req.admin!.username,
      action: 'SITE_SETTINGS_UPDATED',
      entityType: 'SiteSetting',
      entityId: 'ALL',
      newState: settings,
      ipAddress: req.ip,
    });

    res.json({ message: 'Site settings updated successfully' });
  } catch (err) {
    next(err);
  }
});

// ==========================================
// 13. REPORTS & AUDIT LOGS
// ==========================================

router.get('/reports', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const [
      totalUsers,
      totalDeposited,
      totalPaidWithdrawals,
      totalPendingWithdrawals,
      totalTaskRewards,
      totalUnlockFees,
      totalReferralRewards,
      totalSpinRewards,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.depositRequest.aggregate({ where: { status: 'APPROVED' }, _sum: { amount: true } }),
      prisma.withdrawalRequest.aggregate({ where: { paymentStatus: 'PAID' }, _sum: { amount: true } }),
      prisma.withdrawalRequest.aggregate({ where: { approvalStatus: 'PENDING' }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: 'TASK_REWARD', status: 'COMPLETED' }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: 'TASK_UNLOCK_FEE', status: 'COMPLETED' }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: 'REFERRAL_REWARD', status: 'COMPLETED' }, _sum: { amount: true } }),
      prisma.walletTransaction.aggregate({ where: { transactionType: 'SPIN_REWARD', status: 'COMPLETED' }, _sum: { amount: true } }),
    ]);

    res.json({
      summary: {
        totalUsers,
        totalDeposited: totalDeposited._sum.amount || 0,
        totalPaidWithdrawals: totalPaidWithdrawals._sum.amount || 0,
        totalPendingWithdrawals: totalPendingWithdrawals._sum.amount || 0,
        totalTaskRewards: totalTaskRewards._sum.amount || 0,
        totalUnlockFees: Math.abs(totalUnlockFees._sum.amount || 0),
        totalReferralRewards: totalReferralRewards._sum.amount || 0,
        totalSpinRewards: totalSpinRewards._sum.amount || 0,
        platformNetYield: (totalDeposited._sum.amount || 0) + Math.abs(totalUnlockFees._sum.amount || 0) - (totalPaidWithdrawals._sum.amount || 0),
      },
    });
  } catch (err) {
    next(err);
  }
});

router.get('/activity-logs', requireAdmin, async (req: AdminAuthRequest, res: Response, next) => {
  try {
    const page = parseInt(req.query.page as string || '1', 10);
    const limit = parseInt(req.query.limit as string || '30', 10);
    const skip = (page - 1) * limit;

    const [logs, total] = await Promise.all([
      prisma.adminAuditLog.findMany({
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.adminAuditLog.count(),
    ]);

    res.json({
      logs,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
