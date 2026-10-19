import { Router, Response } from 'express';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * GET /api/spin/status
 * Returns user eligibility, remaining spins, assigned prize info, and prize wheel list
 */
router.get('/status', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;

    // Check global spin setting
    const globalSpinSetting = await prisma.siteSetting.findUnique({ where: { key: 'spin_enabled' } });
    const isGlobalSpinEnabled = globalSpinSetting ? globalSpinSetting.value === 'true' : true;

    // Fetch active prizes for wheel rendering
    const prizes = await prisma.spinPrize.findMany({
      where: { status: 'ACTIVE' },
      orderBy: { monetaryValue: 'asc' },
    });

    // Check user entitlement
    const entitlement = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        isEligible: true,
        remainingSpins: { gt: 0 },
      },
      include: {
        assignedPrize: true,
      },
    });

    // Spin history
    const history = await prisma.spinHistory.findMany({
      where: { userId },
      include: { prize: true },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    // Check for won physical products (reserved for delivery after completing 10 levels)
    const wonProducts = await prisma.spinHistory.findMany({
      where: {
        userId,
        prize: { prizeType: 'PHYSICAL' },
      },
      include: {
        prize: true,
        entitlement: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    // Check if user has a pending milestone spin awaiting admin assignment
    const pendingMilestone = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        requiresAdminReview: true,
        adminReviewed: false,
        remainingSpins: { gt: 0 },
      },
    });

    // Check if user has completed Level 10
    const level10Progress = await prisma.userLevelProgress.findFirst({
      where: {
        userId,
        level: { levelNumber: 10 },
        completionStatus: 'COMPLETED',
      },
    });

    res.json({
      isGlobalSpinEnabled,
      isEligible: isGlobalSpinEnabled && !!entitlement && entitlement.remainingSpins > 0,
      remainingSpins: entitlement?.remainingSpins || 0,
      pendingMilestone,
      wonProducts,
      isLevel10Completed: !!level10Progress,
      prizes: prizes.map((p) => {
        let name = p.name;
        let displayLabel = p.displayLabel;
        let prizeType = p.prizeType;
        let monetaryValue = p.monetaryValue;
        let color = p.color;
        let icon = p.icon;

        if (name.includes('250') || displayLabel.includes('250') || name.toLowerCase().includes('alto')) {
          name = 'Suzuki Alto Car';
          displayLabel = 'Alto Car';
          prizeType = 'PHYSICAL';
          monetaryValue = 2500000;
          color = '#059669';
          icon = 'Car';
        } else if (name.toLowerCase().includes('watch') || displayLabel.toLowerCase().includes('watch')) {
          name = 'Expensive Watch';
          displayLabel = 'Expensive Watch';
          prizeType = 'PHYSICAL';
          monetaryValue = 45000;
          color = '#4F46E5';
          icon = 'Watch';
        } else if (name.toLowerCase().includes('phone') || displayLabel.toLowerCase().includes('phone') || name.toLowerCase().includes('iphone')) {
          name = 'iPhone 15 Pro';
          displayLabel = 'iPhone 15 Pro';
          prizeType = 'PHYSICAL';
          monetaryValue = 350000;
          color = '#EAB308';
          icon = 'Smartphone';
        }

        return {
          id: p.id,
          name,
          displayLabel,
          color,
          icon,
          prizeType,
          monetaryValue,
        };
      }),
      history,
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/spin/play
 * Consumes 1 entitlement and resolves the reward strictly on the backend
 */
router.post('/play', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;

    // Verify global setting
    const globalSpinSetting = await prisma.siteSetting.findUnique({ where: { key: 'spin_enabled' } });
    if (globalSpinSetting && globalSpinSetting.value !== 'true') {
      return res.status(403).json({ error: 'The Royal Spin Wheel is currently paused by administration.' });
    }

    // Verify user entitlement
    const entitlement = await prisma.userSpinEntitlement.findFirst({
      where: {
        userId,
        isEligible: true,
        remainingSpins: { gt: 0 },
      },
      include: {
        assignedPrize: true,
      },
    });

    if (!entitlement || entitlement.remainingSpins <= 0) {
      const pendingEntitlement = await prisma.userSpinEntitlement.findFirst({
        where: {
          userId,
          remainingSpins: { gt: 0 },
          adminReviewed: false,
        },
      });

      if (pendingEntitlement) {
        return res.status(403).json({
          error: 'Your milestone free spin has reached administration. Your prize outcome is currently being assigned. You will be notified the moment your spin is ready!',
        });
      }

      return res.status(403).json({
        error: 'You do not have any available spins. Complete levels or invite 3 friends in 24 hours to earn free spins!',
      });
    }

    // All active prizes
    const allActivePrizes = await prisma.spinPrize.findMany({
      where: { status: 'ACTIVE' },
      orderBy: { monetaryValue: 'asc' },
    });

    if (allActivePrizes.length === 0) {
      return res.status(500).json({ error: 'No active prizes configured in the wheel.' });
    }

    // Determine the prize: if administrator assigned a specific prize, use it!
    // Otherwise pick from lowest tier prizes
    let selectedPrize = entitlement.assignedPrize;
    if (!selectedPrize || selectedPrize.status !== 'ACTIVE') {
      selectedPrize = allActivePrizes[0];
    }

    // Execute atomic transaction: decrement spin, record history, credit wallet if cash prize
    const spinResult = await prisma.$transaction(async (tx) => {
      // 1. Decrement entitlement
      await tx.userSpinEntitlement.update({
        where: { id: entitlement.id },
        data: {
          remainingSpins: { decrement: 1 },
          isEligible: entitlement.remainingSpins - 1 > 0,
        },
      });

      let transactionId: string | null = null;

      // 2. If cash prize, credit wallet with immutable transaction
      if (selectedPrize.prizeType === 'CASH' && selectedPrize.monetaryValue > 0) {
        await tx.wallet.update({
          where: { userId },
          data: {
            availableBalance: { increment: selectedPrize.monetaryValue },
            totalEarned: { increment: selectedPrize.monetaryValue },
          },
        });

        const txRecord = await tx.walletTransaction.create({
          data: {
            userId,
            transactionType: 'SPIN_REWARD',
            amount: selectedPrize.monetaryValue,
            currency: 'PKR',
            status: 'COMPLETED',
            relatedEntityId: selectedPrize.id,
            reason: `Royal Spin Wheel cash prize: ${selectedPrize.name}`,
          },
        });
        transactionId = txRecord.id;
      }

      // 3. Create SpinHistory (Physical products marked PENDING_LEVEL_10 for delivery after completing all 10 levels)
      const isPhysical = selectedPrize.prizeType === 'PHYSICAL';
      const history = await tx.spinHistory.create({
        data: {
          userId,
          entitlementId: entitlement.id,
          prizeId: selectedPrize.id,
          resultLabel: selectedPrize.displayLabel,
          prizeValue: selectedPrize.monetaryValue,
          rewardStatus: isPhysical ? 'PENDING_LEVEL_10' : 'CREDITED',
          transactionId,
        },
      });

      // 4. Create Notification
      await tx.notification.create({
        data: {
          userId,
          title: isPhysical ? `Luxury Physical Prize Won! 🎁` : `Cash Spin Winner! 💰`,
          message: isPhysical
            ? `Congratulations! You won ${selectedPrize.name}! This physical product has been reserved in your Royal Vault and will be dispatched to you after completing all 10 Levels!`
            : `Congratulations! You spun the wheel and won PKR ${selectedPrize.monetaryValue.toLocaleString()}! The cash has been added to your available balance.`,
          notificationType: 'SPIN_REWARD',
        },
      });

      return { history, selectedPrize };
    });

    // Find index of prize in active prizes array so client canvas can stop at exact angle
    const prizeIndex = allActivePrizes.findIndex((p) => p.id === selectedPrize.id);

    res.json({
      message: `Congratulations! You won ${selectedPrize.name}!`,
      prize: selectedPrize,
      prizeIndex: prizeIndex >= 0 ? prizeIndex : 0,
      remainingSpins: entitlement.remainingSpins - 1,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
