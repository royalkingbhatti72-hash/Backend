import { Router, Request, Response } from 'express';
import {
  handleTelegramUpdate,
  setTelegramWebhook,
  getTelegramWebhookInfo,
  sendTelegramMessage,
  TELEGRAM_BOT_TOKEN,
  TELEGRAM_ACCESS_PASSWORD,
} from '../services/telegramService';

const router = Router();

/**
 * POST /api/telegram/webhook
 * Receives incoming messages and updates from Telegram Bot API.
 */
router.post('/webhook', async (req: Request, res: Response) => {
  try {
    const update = req.body;
    // Process update asynchronously and respond with 200 OK immediately
    res.status(200).json({ ok: true });

    if (update) {
      await handleTelegramUpdate(update).catch((err) => {
        console.error('Error handling Telegram update in webhook:', err);
      });
    }
  } catch (err) {
    console.error('Webhook error:', err);
    if (!res.headersSent) {
      res.status(200).json({ ok: false });
    }
  }
});

/**
 * GET /api/telegram/setup
 * Automatically configures the webhook on Telegram pointing to this backend server.
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
      info: 'Telegram Bot is configured to send updates to this webhook URL.',
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/telegram/info
 * Retrieves the current webhook status and bot settings.
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
