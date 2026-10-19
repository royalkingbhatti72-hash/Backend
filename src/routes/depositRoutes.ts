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
          title: settingsMap.easypaisa_title?.trim() || '',
          account: easypaisaNumber,
          isAvailable: Boolean(easypaisaNumber),
          instructions: easypaisaNumber
            ? 'Send money to our official Easypaisa account and enter the 11-digit Trx ID below.'
            : 'Receiving account is currently unavailable. Please contact official support via Telegram.',
        },
        JAZZCASH: {
          name: 'JazzCash',
          title: settingsMap.jazzcash_title?.trim() || '',
          account: jazzcashNumber,
          isAvailable: Boolean(jazzcashNumber),
          instructions: jazzcashNumber
            ? 'Transfer through JazzCash app or USSD and enter the Transaction ID / TID below.'
            : 'Receiving account is currently unavailable. Please contact official support via Telegram.',
        },
        BANK_TRANSFER: {
          name: 'Bank Transfer',
          bankName: settingsMap.bank_name?.trim() || '',
          title: settingsMap.bank_title?.trim() || '',
          accountNumber: bankAccount,
          iban: bankIban,
          isAvailable: Boolean(bankAccount || bankIban),
          instructions: (bankAccount || bankIban)
            ? 'Transfer via online banking or ATM and submit the reference number.'
            : 'Receiving account is currently unavailable. Please contact official support via Telegram.',
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

    // Check if the selected method is currently configured/available in backend settings
    const methodSettingKey =
      validated.paymentMethod === 'EASYPAISA'
        ? 'easypaisa_number'
        : validated.paymentMethod === 'JAZZCASH'
        ? 'jazzcash_number'
        : 'bank_account';

    const accountSetting = await prisma.siteSetting.findUnique({
      where: { key: methodSettingKey },
    });

    const telegramSetting = await prisma.siteSetting.findUnique({
      where: { key: 'support_telegram' },
    });
    const supportTelegram = telegramSetting?.value?.trim() || 'https://t.me/earnsheet_official';

    if (!accountSetting?.value || !accountSetting.value.trim()) {
      return res.status(400).json({
        error: `${validated.paymentMethod.replace(/_/g, ' ')} account is currently unavailable. Please contact official support via Telegram to deposit.`,
        supportTelegram,
      });
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
