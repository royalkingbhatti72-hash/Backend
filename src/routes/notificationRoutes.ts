import { Router, Response } from 'express';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * GET /api/notifications
 */
router.get('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    res.json({ notifications, unreadCount });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/notifications/:id/read
 */
router.put('/:id/read', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const id = req.params.id as string;

    await prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });

    res.json({ message: 'Marked as read' });
  } catch (err) {
    next(err);
  }
});

/**
 * PUT /api/notifications/read-all
 */
router.put('/read-all', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;

    await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    res.json({ message: 'All notifications marked as read' });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/notifications/announcements
 */
router.get('/announcements', async (req, res, next) => {
  try {
    const announcements = await prisma.announcement.findMany({
      where: { status: 'ACTIVE' },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });
    res.json({ announcements });
  } catch (err) {
    next(err);
  }
});

export default router;
