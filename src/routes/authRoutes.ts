import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { prisma } from '../prisma';
import { config } from '../config';
import { requireAuth, AuthRequest } from '../middleware/auth';
import { affiliateService } from '../services/affiliateService';
import { validateAdminReferralCode, claimAdminReferralCode } from '../services/adminReferralService';

const router = Router();

// Validation Schemas
const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(50),
  phone: z.string().min(10, 'Valid phone number is required').max(15),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  confirmPassword: z.string().min(6, 'Confirm password must be at least 6 characters'),
  referralCode: z.string().min(1, 'Referral code is required. Registration is invite-only.'),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});

const loginSchema = z.object({
  phone: z.string().min(10, 'Valid phone number is required'),
  password: z.string().min(1, 'Password is required'),
});

// Helper to generate a unique referral code
function generateReferralCode(name: string): string {
  const prefix = name.replace(/[^a-zA-Z]/g, '').slice(0, 4).toUpperCase() || 'ROYAL';
  const randomSuffix = Math.floor(1000 + Math.random() * 9000);
  return `${prefix}${randomSuffix}`;
}

// Normalize phone
function normalizePhone(phone: string): string {
  return phone.replace(/[^0-9+]/g, '');
}

/**
 * GET /api/auth/validate-referral/:code
 * Public endpoint to check if an exclusive admin referral code is available
 */
router.get('/validate-referral/:code', async (req: Request, res: Response) => {
  const code = (req.params.code as string || '').trim().toUpperCase();
  const isValid = await validateAdminReferralCode(code);
  res.json({ valid: isValid, code });
});

/**
 * POST /api/auth/register
 */
router.post('/register', async (req: Request, res: Response, next) => {
  try {
    const validated = registerSchema.parse(req.body);
    const normalizedPhone = normalizePhone(validated.phone);

    // Enforce official admin referral code requirement
    const trimmedRefCode = (validated.referralCode || '').trim().toUpperCase();
    if (!trimmedRefCode) {
      return res.status(400).json({
        error: 'A valid referral code is required to register. Registration is invite-only.',
      });
    }

    const isValidAdminCode = await validateAdminReferralCode(trimmedRefCode);
    if (!isValidAdminCode) {
      return res.status(400).json({
        error: 'Invalid or already used referral code. Registration requires an exclusive invitation code provided by administration.',
      });
    }

    // Check unique phone
    const existingUser = await prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });
    if (existingUser) {
      return res.status(400).json({ error: 'A user with this phone number is already registered' });
    }

    // Generate unique referral code for new user
    let userReferralCode = generateReferralCode(validated.name);
    let codeExists = await prisma.user.findUnique({ where: { referralCode: userReferralCode } });
    let attempts = 0;
    while (codeExists && attempts < 5) {
      userReferralCode = generateReferralCode(validated.name);
      codeExists = await prisma.user.findUnique({ where: { referralCode: userReferralCode } });
      attempts++;
    }

    const passwordHash = await bcrypt.hash(validated.password, 10);

    // Transaction to create user, wallet, level 1 progress, and claim admin referral code
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          name: validated.name.trim(),
          phone: normalizedPhone,
          passwordHash,
          referralCode: userReferralCode,
          referredById: null,
          accountStatus: 'ACTIVE',
        },
      });

      // Claim the admin referral code immediately
      await tx.$executeRawUnsafe(`
        UPDATE "AdminReferralCode"
        SET "status" = 'USED',
            "usedById" = $1,
            "usedByName" = $2,
            "usedByPhone" = $3,
            "usedAt" = CURRENT_TIMESTAMP,
            "updatedAt" = CURRENT_TIMESTAMP
        WHERE "code" = $4 AND "status" = 'AVAILABLE'
      `, user.id, user.name, normalizedPhone, trimmedRefCode);

      // Create wallet with 100 initial credit points on joining
      const wallet = await tx.wallet.create({
        data: {
          userId: user.id,
          currency: 'PKR',
          availableBalance: 0,
          pendingBalance: 0,
          totalEarned: 0,
          totalDeposited: 0,
          creditPoints: 100,
        },
      });

      // Initialize Level 1 progress
      const level1 = await tx.level.findUnique({ where: { levelNumber: 1 } });
      if (level1) {
        await tx.userLevelProgress.create({
          data: {
            userId: user.id,
            levelId: level1.id,
            completionStatus: 'IN_PROGRESS',
            approvedTaskCount: 0,
          },
        });
      }

      return { ...user, wallet };
    });

    const token = jwt.sign({ userId: result.id }, config.jwtSecret, { expiresIn: '7d' });

    res.status(201).json({
      message: 'Registration successful! Welcome to Earn Street.',
      token,
      user: {
        id: result.id,
        name: result.name,
        phone: result.phone,
        referralCode: result.referralCode,
        accountStatus: result.accountStatus,
        wallet: result.wallet,
      },
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/auth/login
 */
router.post('/login', async (req: Request, res: Response, next) => {
  try {
    const validated = loginSchema.parse(req.body);
    const normalizedPhone = normalizePhone(validated.phone);

    const user = await prisma.user.findUnique({
      where: { phone: normalizedPhone },
      include: { wallet: true },
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    if (user.accountStatus === 'SUSPENDED') {
      return res.status(403).json({ error: 'Your account is suspended. Please contact customer support.' });
    }

    const isValid = await bcrypt.compare(validated.password, user.passwordHash);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid phone number or password' });
    }

    const token = jwt.sign({ userId: user.id }, config.jwtSecret, { expiresIn: '7d' });

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        referralCode: user.referralCode,
        accountStatus: user.accountStatus,
        mustChangePassword: user.mustChangePassword,
        wallet: user.wallet,
      },
    });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/auth/me
 */
router.get('/me', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: {
        id: true,
        name: true,
        phone: true,
        referralCode: true,
        accountStatus: true,
        mustChangePassword: true,
        createdAt: true,
        wallet: true,
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

/**
 * POST /api/auth/logout
 */
router.post('/logout', (req: Request, res: Response) => {
  res.json({ message: 'Logged out successfully' });
});

export default router;
