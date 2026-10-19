import { Router, Response } from 'express';
import { prisma } from '../prisma';

const router = Router();

/**
 * GET /api/settings/public
 * Returns general brand, support, financial limits, and affiliate program rules
 */
router.get('/public', async (req, res, next) => {
  try {
    const settings = await prisma.siteSetting.findMany({
      where: {
        key: {
          in: [
            'site_name',
            'support_email',
            'support_whatsapp',
            'welcome_message',
            'currency',
            'min_deposit',
            'min_withdrawal',
            'referral_reward',
            'referral_qualifying_condition',
            'affiliate_program_enabled',
            'affiliate_bronze_target',
            'affiliate_silver_target',
            'affiliate_gold_target',
            'affiliate_share_template',
            'support_telegram',
          ],
        },
      },
    });

    const settingsMap = Object.fromEntries(settings.map((s) => [s.key, s.value]));

    res.json({
      siteName: settingsMap.site_name || 'Earn Sheet',
      supportEmail: settingsMap.support_email || 'support@earnsheet.com',
      supportWhatsapp: settingsMap.support_whatsapp || '+92 300 1234567',
      supportTelegram: settingsMap.support_telegram || 'https://t.me/earnsheet_official',
      welcomeMessage: settingsMap.welcome_message || 'Welcome to Earn Sheet!',
      currency: settingsMap.currency || 'PKR',
      minDeposit: parseFloat(settingsMap.min_deposit || '500'),
      minWithdrawal: parseFloat(settingsMap.min_withdrawal || '1000'),
      referralReward: parseFloat(settingsMap.referral_reward || '250'),
      referralQualifyingCondition: settingsMap.referral_qualifying_condition || 'FIRST_TASK_APPROVED',
      affiliateProgramEnabled: settingsMap.affiliate_program_enabled !== 'false',
      bronzeTarget: parseInt(settingsMap.affiliate_bronze_target || '5', 10),
      silverTarget: parseInt(settingsMap.affiliate_silver_target || '15', 10),
      goldTarget: parseInt(settingsMap.affiliate_gold_target || '30', 10),
      affiliateShareTemplate: settingsMap.affiliate_share_template || '',
    });
  } catch (err) {
    next(err);
  }
});

export default router;
