import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

const depositSchema = z.object({
  amount: z.number().positive('Deposit amount must be greater than zero'),
  paymentMethod: z.enum(['EASYPAISA', 'JAZZCASH', 'BANK_TRANSFER']),
  transactionReference: z.string().min(4, 'Transaction ID / reference is required').max(100),
  proofEvidence: z.string().optional().nullable(),
});

/**
 * GET /api/deposits/instructions
 * Receiving account details and deposit guidelines
 */
router.get('/instructions', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const settings = await prisma.siteSetting.findMany({
      where: {
        key: {
          in: [
            'min_deposit',
            'easypaisa_title',
            'easypaisa_number',
            'jazzcash_title',
            'jazzcash_number',
            'bank_name',
            'bank_title',
            'bank_account',
            'bank_iban',
            'support_whatsapp',
          ],
        },
      },
    });

    const settingsMap = Object.fromEntries(settings.map((s) => [s.key, s.value]));

    res.json({
      minDeposit: parseFloat(settingsMap.min_deposit || '500'),
      supportWhatsapp: settingsMap.support_whatsapp || '+92 300 1234567',
      methods: {
        EASYPAISA: {
          name: 'Easypaisa',
          title: settingsMap.easypaisa_title || 'Earn Sheet Official',
          account: settingsMap.easypaisa_number || '0312-3456789',
          instructions: 'Send money to our official Easypaisa account and enter the 11-digit Trx ID below.',
        },
        JAZZCASH: {
          name: 'JazzCash',
          title: settingsMap.jazzcash_title || 'Earn Sheet Official',
          account: settingsMap.jazzcash_number || '0301-9876543',
          instructions: 'Transfer through JazzCash app or USSD and enter the Transaction ID / TID below.',
        },
        BANK_TRANSFER: {
          name: 'Bank Transfer',
          bankName: settingsMap.bank_name || 'Meezan Bank Limited',
          title: settingsMap.bank_title || 'Earn Sheet Enterprise PVT',
          accountNumber: settingsMap.bank_account || '01020304050607',
          iban: settingsMap.bank_iban || 'PK12MEZN0001020304050607',
          instructions: 'Transfer via online banking or ATM and submit the reference number.',
        },
      },
    });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /api/deposits
 * User deposit history
 */
router.get('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const deposits = await prisma.depositRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ deposits });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/deposits
 * Submit manual deposit request
 */
router.post('/', requireAuth, async (req: AuthRequest, res: Response, next) => {
  try {
    const userId = req.user!.id;
    const validated = depositSchema.parse(req.body);

    // Check minimum deposit setting
    const minSetting = await prisma.siteSetting.findUnique({ where: { key: 'min_deposit' } });
    const minDeposit = minSetting ? parseFloat(minSetting.value) : 500;

    if (validated.amount < minDeposit) {
      return res.status(400).json({ error: `Minimum deposit amount is PKR ${minDeposit.toLocaleString()}` });
    }

    // Check if duplicate transaction reference already submitted
    const existingRef = await prisma.depositRequest.findFirst({
      where: { transactionReference: validated.transactionReference.trim() },
    });
    if (existingRef) {
      return res.status(400).json({ error: 'This transaction reference ID has already been submitted' });
    }

    const deposit = await prisma.$transaction(async (tx) => {
      const dep = await tx.depositRequest.create({
        data: {
          userId,
          amount: validated.amount,
          paymentMethod: validated.paymentMethod,
          transactionReference: validated.transactionReference.trim(),
          proofEvidence: validated.proofEvidence || null,
          status: 'PENDING',
        },
      });

      await tx.notification.create({
        data: {
          userId,
          title: `Deposit Submitted: PKR ${validated.amount.toLocaleString()} 📥`,
          message: `Your deposit request via ${validated.paymentMethod} (Ref: ${validated.transactionReference}) is pending administrator verification.`,
          notificationType: 'DEPOSIT_STATUS',
        },
      });

      return dep;
    });

    res.status(201).json({
      message: 'Deposit request submitted successfully! Funds will be credited once verified by administration.',
      deposit,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
