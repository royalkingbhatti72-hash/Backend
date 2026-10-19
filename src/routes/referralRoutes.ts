import { Router, Response } from 'express';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * GET /api/referrals
 * User referral dashboard details
 */
router.get('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { referralCode: true },
    });

    if (!user) return res.status(404).json({ error: 'User not found' });

    // Fetch referral reward setting
    const rewardSetting = await prisma.siteSetting.findUnique({ where: { key: 'referral_reward' } });
    const rewardPerReferral = rewardSetting ? parseFloat(rewardSetting.value) : 250;

    // Fetch referred users
    const referrals = await prisma.referral.findMany({
      where: { referrerId: userId },
      orderBy: { createdAt: 'desc' },
    });

    // Fetch referred user details
    const referredUserIds = referrals.map((r) => r.referredId);
    const referredUsers = await prisma.user.findMany({
      where: { id: { in: referredUserIds } },
      select: {
        id: true,
        name: true,
        phone: true,
        accountStatus: true,
        createdAt: true,
      },
    });
    const userMap = new Map(referredUsers.map((u) => [u.id, u]));

    // Total referral earnings
    const referralEarnings = await prisma.walletTransaction.aggregate({
      where: {
        userId,
        transactionType: 'REFERRAL_REWARD',
        status: 'COMPLETED',
      },
      _sum: { amount: true },
    });

    const detailedReferrals = referrals.map((r) => {
      const referee = userMap.get(r.referredId);
      // Mask referee phone for privacy (e.g. 0300****567)
      const maskedPhone = referee?.phone
        ? referee.phone.slice(0, 4) + '****' + referee.phone.slice(-3)
        : 'N/A';

      return {
        id: r.id,
        name: referee?.name || 'Referred Member',
        maskedPhone,
        registeredAt: referee?.createdAt || r.createdAt,
        qualifyingStatus: r.qualifyingStatus,
        rewardStatus: r.rewardStatus,
        rewardAmount: r.rewardAmount,
      };
    });

    const totalReferrals = referrals.length;
    const qualifiedReferrals = referrals.filter((r) => r.qualifyingStatus === 'QUALIFIED').length;
    const spinsEarned = await prisma.userSpinEntitlement.count({
      where: {
        userId,
        triggerReason: { contains: 'Referral' },
      },
    });

    res.json({
      referralCode: user.referralCode,
      rewardPerReferral: 0,
      rewardType: 'SPIN',
      totalReferrals,
      qualifiedReferrals,
      spinsEarned: spinsEarned || qualifiedReferrals,
      totalEarned: 0,
      referrals: detailedReferrals,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
