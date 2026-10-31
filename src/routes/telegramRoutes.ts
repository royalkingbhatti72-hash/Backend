import { Router, Request, Response } from 'express';
import {
  handleTelegramWebhookUpdate,
  setTelegramWebhook,
  getTelegramWebhookInfo,
  TELEGRAM_BOT_TOKEN,
  TELEGRAM_ACCESS_PASSWORD,
} from '../services/telegramService';

const router = Router();

/**
 * POST /api/telegram/webhook
 * Receives incoming messages from Telegram Bot API and responds directly
 * with sub-second execution speed.
 */
router.post('/webhook', async (req: Request, res: Response) => {
  try {
    const update = req.body;
    if (!update || !update.message) {
      return res.status(200).json({ ok: true });
    }

    const replyAction = await handleTelegramWebhookUpdate(update);
    if (replyAction) {
      return res.status(200).json(replyAction);
    }

    return res.status(200).json({ ok: true });
  } catch (err: any) {
    console.error('Webhook processing error:', err);
    return res.status(200).json({ ok: false });
  }
});

/**
 * GET /api/telegram/setup
 * Configures the webhook URL on Telegram Bot API.
 */
router.get('/setup', async (req: Request, res: Response) => {
  try {
    const host = req.get('host') || 'streetearn-backend.vercel.app';
    const protocol = req.protocol === 'http' && !host.includes('vercel.app') ? 'http' : 'https';
    const webhookUrl = `${protocol}://${host}/api/telegram/webhook`;

    const result = await setTelegramWebhook(webhookUrl);
    res.json({
      success: result.ok,
      webhookUrl,
      telegramResponse: result,
      info: 'Telegram Bot webhook is active and configured.',
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/telegram/info
 * Retrieves the current webhook status and bot parameters.
 */
router.get('/info', async (req: Request, res: Response) => {
  try {
    const webhookInfo = await getTelegramWebhookInfo();
    res.json({
      botTokenConfigured: Boolean(TELEGRAM_BOT_TOKEN),
      passwordConfigured: Boolean(TELEGRAM_ACCESS_PASSWORD),
      webhookInfo,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
