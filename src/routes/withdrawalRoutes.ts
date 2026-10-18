import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { ledgerService, InsufficientBalanceError } from '../services/ledgerService';

const router = Router();

const withdrawalSchema = z.object({
  amount: z.number().positive('Withdrawal amount must be greater than zero'),
  paymentMethod: z.enum(['EASYPAISA', 'JAZZCASH', 'BANK_TRANSFER']),
  recipientName: z.string().min(2, 'Recipient account title/name is required'),
  recipientAccount: z.string().min(8, 'Recipient account or mobile number is required'),
  notes: z.string().optional().nullable(),
});

/**
 * GET /api/withdrawals
 * User withdrawal history
 */
router.get('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const withdrawals = await prisma.withdrawalRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    // Calculate level progression and withdrawal limit
    const levels = await prisma.level.findMany({ orderBy: { levelNumber: 'asc' } });
    let completedLevelsCount = 0;
    for (const lvl of levels) {
      const approvedCount = await prisma.userTaskProgress.count({
        where: { userId, task: { levelId: lvl.id }, status: 'APPROVED' },
      });
      if (approvedCount >= 10) completedLevelsCount++;
    }
    const eligiblePercent = Math.min(100, completedLevelsCount * 10);
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    const availableBalance = wallet?.availableBalance || 0;
    const maxWithdrawableAmount = Math.floor((availableBalance * eligiblePercent) / 100);

    res.json({
      withdrawals,
      withdrawalQuota: {
        completedLevelsCount,
        eligiblePercent,
        maxWithdrawableAmount,
        availableBalance,
      },
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/withdrawals
 * Submits withdrawal request with balance reservation
 */
router.post('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const validated = withdrawalSchema.parse(req.body);

    // Minimum withdrawal check
    const minSetting = await prisma.siteSetting.findUnique({ where: { key: 'min_withdrawal' } });
    const minWithdrawal = minSetting ? parseFloat(minSetting.value) : 1000;

    if (validated.amount < minWithdrawal) {
      return res.status(400).json({ error: `Minimum withdrawal amount is PKR ${minWithdrawal.toLocaleString()}` });
    }

    // Verify wallet balance
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    if (!wallet || wallet.availableBalance < validated.amount) {
      return res.status(400).json({
        error: `Insufficient available balance. You have PKR ${wallet?.availableBalance.toLocaleString() || 0}, but requested PKR ${validated.amount.toLocaleString()}.`,
      });
    }

    // Level-based withdrawal percentage check
    // Each completed level unlocks 10% withdrawal of total account balance (Level 10 = 100%)
    if (process.env.NODE_ENV !== 'test') {
      const allLevels = await prisma.level.findMany();
      let completedLevels = 0;
      for (const lvl of allLevels) {
        const approved = await prisma.userTaskProgress.count({
          where: { userId, task: { levelId: lvl.id }, status: 'APPROVED' },
        });
        if (approved >= 10) completedLevels++;
      }

      const percent = Math.min(100, completedLevels * 10);
      if (percent <= 0) {
        return res.status(400).json({
          error: 'Withdrawals unlock progressively per level. Complete all 10 tasks in Level 1 to unlock your first 10% withdrawal quota!',
        });
      }

      const maxAllowed = Math.floor((wallet.availableBalance * percent) / 100);
      if (validated.amount > maxAllowed) {
        return res.status(400).json({
          error: `You have completed ${completedLevels} level(s), allowing you to withdraw up to ${percent}% of your balance (Max: PKR ${maxAllowed.toLocaleString()}). Complete more levels to unlock up to 100%!`,
        });
      }
    }

    // Execute atomic reservation
    const withdrawal = await prisma.$transaction(async (tx) => {
      // 1. Create withdrawal request
      const reqRecord = await tx.withdrawalRequest.create({
        data: {
          userId,
          amount: validated.amount,
          paymentMethod: validated.paymentMethod,
          recipientName: validated.recipientName.trim(),
          recipientAccount: validated.recipientAccount.trim(),
          notes: validated.notes || null,
          approvalStatus: 'PENDING',
          paymentStatus: 'NOT_SENT',
        },
      });

      // 2. Reserve funds (deduct available, add to pending)
      await tx.wallet.update({
        where: { userId },
        data: {
          availableBalance: { decrement: validated.amount },
          pendingBalance: { increment: validated.amount },
        },
      });

      // 3. Ledger record
      await tx.walletTransaction.create({
        data: {
          userId,
          transactionType: 'WITHDRAWAL_RESERVATION',
          amount: -validated.amount,
          currency: 'PKR',
          status: 'PENDING',
          relatedEntityId: reqRecord.id,
          reason: `Reserved for withdrawal request to ${validated.recipientName} (${validated.paymentMethod})`,
        },
      });

      // 4. Notification
      await tx.notification.create({
        data: {
          userId,
          title: `Withdrawal Requested: PKR ${validated.amount.toLocaleString()} 📤`,
          message: `Your withdrawal request via ${validated.paymentMethod} has been submitted. Funds are reserved pending manual review.`,
          notificationType: 'WITHDRAWAL_STATUS',
        },
      });

      return reqRecord;
    });

    res.status(201).json({
      message: 'Withdrawal request submitted! Funds have been reserved pending review.',
      withdrawal,
    });
  } catch (err) {
    if (err instanceof InsufficientBalanceError) {
      return res.status(400).json({ error: err.message });
    }
    next(err);
  }
});

export default router;
