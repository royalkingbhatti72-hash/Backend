import { Router, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../prisma';
import { requireAuth, AuthRequest } from '../middleware/auth';

const router = Router();

const depositSchema = z.object({
  amount: z.coerce.number().positive('Deposit amount must be greater than zero'),
  paymentMethod: z.enum(['EASYPAISA', 'JAZZCASH', 'BANK_TRANSFER']),
  transactionReference: z.string().min(1, 'Transaction ID / reference is required').max(100),
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
            'support_telegram',
          ],
        },
      },
    });

    const settingsMap = Object.fromEntries(settings.map((s) => [s.key, s.value]));

    const easypaisaNumber = (settingsMap.easypaisa_number || '').trim();
    const jazzcashNumber = (settingsMap.jazzcash_number || '').trim();
    const bankAccount = (settingsMap.bank_account || '').trim();
    const bankIban = (settingsMap.bank_iban || '').trim();
    const supportTelegram = (settingsMap.support_telegram || 'https://t.me/earnsheet_official').trim();

    res.json({
      minDeposit: 1,
      supportWhatsapp: settingsMap.support_whatsapp || '',
      supportTelegram,
      methods: {
        EASYPAISA: {
          name: 'Easypaisa',
          title: settingsMap.easypaisa_title?.trim() || 'Earn Sheet Official',
          account: easypaisaNumber,
          isAvailable: true,
          instructions: easypaisaNumber
            ? 'Send money to our official Easypaisa account and enter the 11-digit Trx ID below.'
            : 'Official receiving account allocated via Telegram support. Click Get Account above to receive verified details.',
        },
        JAZZCASH: {
          name: 'JazzCash',
          title: settingsMap.jazzcash_title?.trim() || 'Earn Sheet Official',
          account: jazzcashNumber,
          isAvailable: true,
          instructions: jazzcashNumber
            ? 'Transfer through JazzCash app or USSD and enter the Transaction ID / TID below.'
            : 'Official receiving account allocated via Telegram support. Click Get Account above to receive verified details.',
        },
        BANK_TRANSFER: {
          name: 'Bank Transfer',
          bankName: settingsMap.bank_name?.trim() || 'Official Banking Channel',
          title: settingsMap.bank_title?.trim() || 'Earn Sheet Official',
          accountNumber: bankAccount,
          iban: bankIban,
          isAvailable: true,
          instructions: (bankAccount || bankIban)
            ? 'Transfer via online banking or ATM and submit the reference number.'
            : 'Official receiving account allocated via Telegram support. Click Get Account above to receive verified details.',
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

    // Deposit can be any amount (positive number >= 1)
    if (validated.amount < 1) {
      return res.status(400).json({ error: 'Deposit amount must be at least PKR 1' });
    }

    // Check if duplicate transaction reference already submitted
    const existingRef = await prisma.depositRequest.findFirst({
      where: {
        transactionReference: validated.transactionReference.trim(),
        status: { in: ['PENDING', 'APPROVED'] },
      },
    });
    if (existingRef) {
      return res.status(400).json({ error: 'This transaction reference ID has already been submitted and is currently pending or approved.' });
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
