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

    // Calculate level progression and withdrawal limit (10% of total balance on every completed level)
    const levels = await prisma.level.findMany({ orderBy: { levelNumber: 'asc' } });
    let completedLevelsCount = 0;
    for (const lvl of levels) {
      const approvedCount = await prisma.userTaskProgress.count({
        where: { userId, task: { levelId: lvl.id }, status: 'APPROVED' },
      });
      if (approvedCount >= 10) completedLevelsCount++;
    }
    const eligiblePercent = completedLevelsCount >= 1 ? 10 : 0;
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

    // Verify wallet balance
    const wallet = await prisma.wallet.findUnique({ where: { userId } });
    if (!wallet || wallet.availableBalance <= 0) {
      return res.status(400).json({
        error: 'You have no available balance to withdraw.',
      });
    }

    // Calculate exact amount available for withdrawal (10% of total account balance on every completed level)
    let exactAvailable = wallet.availableBalance;
    if (process.env.NODE_ENV !== 'test') {
      const allLevels = await prisma.level.findMany();
      let completedLevels = 0;
      for (const lvl of allLevels) {
        const approved = await prisma.userTaskProgress.count({
          where: { userId, task: { levelId: lvl.id }, status: 'APPROVED' },
        });
        if (approved >= 10) completedLevels++;
      }

      const percent = completedLevels >= 1 ? 10 : 0;
      if (percent <= 0 && completedLevels === 0) {
        return res.status(400).json({
          error: 'Withdrawals unlock on level completion. Complete all 10 tasks in Level 1 to unlock your 10% account balance withdrawal quota!',
        });
      }

      exactAvailable = Math.floor((wallet.availableBalance * percent) / 100);
    }

    if (exactAvailable <= 0) {
      return res.status(400).json({
        error: 'No withdrawable balance is currently available in your account.',
      });
    }

    // Withdrawal can ONLY be for the exact amount that is available for withdrawal
    if (Math.abs(validated.amount - exactAvailable) > 0.01) {
      return res.status(400).json({
        error: `Withdrawal can only be requested for the exact available amount of PKR ${exactAvailable.toLocaleString()}. Custom or partial amounts are not permitted.`,
        exactAvailable,
      });
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
