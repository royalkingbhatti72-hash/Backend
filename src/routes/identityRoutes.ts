import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { ensureIdentityTable } from '../services/identityService';

const router = Router();

const identitySubmissionSchema = z.object({
  idFrontImage: z.string().min(50, 'Front image of ID card is required'),
  idBackImage: z.string().min(50, 'Back image of ID card is required'),
});

/**
 * GET /api/user/identity
 * Returns the authenticated user's current identity verification record & status
 */
router.get('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    await ensureIdentityTable();
    const userId = req.user!.id;
    const record = await prisma.identityVerification.findUnique({
      where: { userId },
    });

    res.json({
      identityVerification: record,
      isVerified: record?.status === 'APPROVED',
      status: record?.status || 'UNVERIFIED',
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/user/identity
 * Submits or re-submits ID card front and back images for verification
 */
router.post('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    await ensureIdentityTable();
    const userId = req.user!.id;
    const { idFrontImage, idBackImage } = identitySubmissionSchema.parse(req.body);

    const existing = await prisma.identityVerification.findUnique({
      where: { userId },
    });

    if (existing && existing.status === 'APPROVED') {
      return res.status(400).json({
        error: 'Your identity has already been verified and approved.',
      });
    }

    const updated = await prisma.$transaction(async (tx) => {
      const record = await tx.identityVerification.upsert({
        where: { userId },
        create: {
          userId,
          idFrontImage,
          idBackImage,
          status: 'PENDING',
          submittedAt: new Date(),
        },
        update: {
          idFrontImage,
          idBackImage,
          status: 'PENDING',
          rejectionReason: null,
          reviewNotes: null,
          submittedAt: new Date(),
        },
      });

      await tx.notification.create({
        data: {
          userId,
          title: 'Identity Verification Submitted 🪪',
          message: 'Your ID card images have been received and are pending compliance review. Verification typically takes 1–2 hours.',
          notificationType: 'SYSTEM_ALERT',
        },
      });

      return record;
    });

    res.status(200).json({
      message: 'Identity verification submitted successfully! Our compliance team will review your ID card shortly.',
      identityVerification: updated,
    });
  } catch (err) {
    next(err);
  }
});

export default router;

