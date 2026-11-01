import { Router, Response } from 'express';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

/**
 * Helper to determine if a notification is permitted to be shown to the user.
 * Only Deposit Approved/Rejected, Withdrawal Approved/Rejected, and Announcements are allowed.
 * Any other activity is excluded.
 */
function isAllowedUserNotification(n: { notificationType: string; title: string; message: string }): boolean {
  if (n.notificationType === 'ANNOUNCEMENT') return true;
  const title = (n.title || '').toLowerCase();
  const message = (n.message || '').toLowerCase();

  if (n.notificationType === 'DEPOSIT_STATUS') {
    return title.includes('approved') || title.includes('rejected') || message.includes('approved') || message.includes('rejected');
  }

  if (n.notificationType === 'WITHDRAWAL_STATUS') {
    return (
      title.includes('approved') ||
      title.includes('rejected') ||
      title.includes('disbursed') ||
      title.includes('paid') ||
      message.includes('approved') ||
      message.includes('rejected') ||
      message.includes('disbursed') ||
      message.includes('paid')
    );
  }

  return false;
}

/**
 * GET /api/notifications
 * Returns ONLY deposit and withdrawal approved/rejected notifications and announcements.
 */
router.get('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;

    const [rawNotifications, activeAnnouncements] = await Promise.all([
      prisma.notification.findMany({
        where: {
          userId,
          notificationType: { in: ['DEPOSIT_STATUS', 'WITHDRAWAL_STATUS', 'ANNOUNCEMENT'] },
        },
        orderBy: { createdAt: 'desc' },
        take: 100,
      }),
      prisma.announcement.findMany({
        where: { status: 'ACTIVE' },
        orderBy: { createdAt: 'desc' },
        take: 10,
      }),
    ]);

    // Strictly filter to approved and rejected statuses
    const userNotifications = rawNotifications.filter(isAllowedUserNotification);

    // Map system announcements into user notification format
    const announcementNotifications = activeAnnouncements.map((a) => ({
      id: `announcement_${a.id}`,
      userId,
      title: a.title.startsWith('📢') ? a.title : `📢 Announcement: ${a.title}`,
      message: a.content,
      notificationType: 'ANNOUNCEMENT',
      isRead: false,
      createdAt: a.createdAt,
      isAnnouncement: true,
    }));

    // Merge announcements and transaction notifications, sorted by createdAt desc
    const combined = [...announcementNotifications, ...userNotifications].sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );

    const unreadCount = combined.filter((n) => !n.isRead).length;

    res.json({ notifications: combined, unreadCount });
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

    if (id.startsWith('announcement_')) {
      return res.json({ message: 'Marked as read' });
    }

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
      where: {
        userId,
        isRead: false,
      },
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
