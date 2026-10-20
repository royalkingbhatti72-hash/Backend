import { Router, Response } from 'express';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * GET /api/referrals
 * User referral details: client list with levels & spin progress
 */
router.get('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { referralCode: true },
    });

    if (!user) return res.status(404).json({ error: 'User not found' });

    // Fetch levels for progress mapping
    const levels = await prisma.level.findMany({
      orderBy: { levelNumber: 'asc' },
      select: { id: true, levelNumber: true, title: true, requiredTaskCount: true },
    });

    // Fetch user's referrals
    const referrals = await prisma.referral.findMany({
      where: { referrerId: userId },
      orderBy: { createdAt: 'desc' },
    });

    // Fetch referred user details with their approved task progress
    const referredUserIds = referrals.map((r) => r.referredId);
    const referredUsers = await prisma.user.findMany({
      where: { id: { in: referredUserIds } },
      select: {
        id: true,
        name: true,
        phone: true,
        accountStatus: true,
        createdAt: true,
        taskProgress: {
          where: { status: 'APPROVED' },
          select: {
            task: {
              select: { levelId: true },
            },
          },
        },
      },
    });
    const userMap = new Map(referredUsers.map((u) => [u.id, u]));

    const detailedReferrals = referrals.map((r) => {
      const referee = userMap.get(r.referredId);
      const maskedPhone = referee?.phone
        ? referee.phone.slice(0, 4) + '****' + referee.phone.slice(-3)
        : 'N/A';

      // Compute referee's current level based on approved tasks
      const countByLevel = new Map<string, number>();
      if (referee?.taskProgress) {
        for (const tp of referee.taskProgress) {
          if (tp.task?.levelId) {
            countByLevel.set(tp.task.levelId, (countByLevel.get(tp.task.levelId) || 0) + 1);
          }
        }
      }

      let currentLevelNumber = 1;
      let currentLevelTitle = 'Level 1';
      let tasksInCurrentLevel = 0;
      let requiredTasksInCurrentLevel = 10;
      let completedLevelsCount = 0;
      let foundActive = false;

      for (const lvl of levels) {
        const approved = countByLevel.get(lvl.id) || 0;
        const required = lvl.requiredTaskCount || 10;
        if (approved >= required) {
          completedLevelsCount++;
        } else if (!foundActive) {
          currentLevelNumber = lvl.levelNumber;
          currentLevelTitle = `Level ${lvl.levelNumber}`;
          tasksInCurrentLevel = approved;
          requiredTasksInCurrentLevel = required;
          foundActive = true;
        }
      }

      if (!foundActive && completedLevelsCount >= levels.length && levels.length > 0) {
        currentLevelNumber = levels.length;
        currentLevelTitle = `Level ${levels.length} (Completed)`;
        tasksInCurrentLevel = 10;
        requiredTasksInCurrentLevel = 10;
      }

      const isLevel1Completed = completedLevelsCount >= 1;
      const isQualified = r.qualifyingStatus === 'QUALIFIED' || isLevel1Completed;

      return {
        id: r.id,
        name: referee?.name || 'Referred Member',
        maskedPhone,
        registeredAt: referee?.createdAt || r.createdAt,
        currentLevelNumber,
        currentLevelTitle,
        tasksInCurrentLevel,
        requiredTasksInCurrentLevel,
        isLevel1Completed,
        qualifyingStatus: isQualified ? 'QUALIFIED' : 'PENDING',
        spinAwarded: isQualified,
        spinStatusText: isQualified
          ? 'Free Spin Unlocked 🎰'
          : `Pending Level 1 (${tasksInCurrentLevel}/${requiredTasksInCurrentLevel} Tasks)`,
      };
    });

    const totalReferrals = referrals.length;
    const qualifiedReferrals = detailedReferrals.filter((r) => r.isLevel1Completed || r.qualifyingStatus === 'QUALIFIED').length;
    const pendingReferrals = Math.max(0, totalReferrals - qualifiedReferrals);

    const spinsEarned = await prisma.userSpinEntitlement.count({
      where: {
        userId,
        triggerReason: { contains: 'Referral' },
      },
    });

    res.json({
      referralCode: user.referralCode,
      totalReferrals,
      qualifiedReferrals,
      pendingReferrals,
      spinsEarned: spinsEarned || qualifiedReferrals,
      spinRule: 'You earn 1 Free Lucky Spin when an invited friend completes Level 1.',
      referrals: detailedReferrals,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
