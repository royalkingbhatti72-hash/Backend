import { prisma } from '../prisma';
import { generateAdditionalCodes, replenishAvailableCodesTo100 } from './adminReferralService';

export const TELEGRAM_BOT_TOKEN =
  process.env.TELEGRAM_BOT_TOKEN || '9207587440:AAHXQL1Krzbj8zRMqFXJypFiH-N_ePPghgk';
export const TELEGRAM_ACCESS_PASSWORD =
  process.env.TELEGRAM_ACCESS_PASSWORD || '9989GHYRT89';

const TG_API_BASE = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}`;

export interface TelegramAuthUser {
  chatId: number | string;
  username?: string;
  firstName?: string;
  authAt: string;
}

/**
 * Sends a message to a Telegram chat via Bot API.
 */
export async function sendTelegramMessage(
  chatId: number | string,
  text: string,
  keyboard?: any
): Promise<boolean> {
  try {
    const payload: any = {
      chat_id: chatId,
      text,
      parse_mode: 'Markdown',
    };

    if (keyboard) {
      payload.reply_markup = keyboard;
    }

    const res = await fetch(`${TG_API_BASE}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error(`Telegram sendMessage failed [${res.status}]:`, errText);
      return false;
    }

    return true;
  } catch (err) {
    console.error('Error sending Telegram message:', err);
    return false;
  }
}

/**
 * Sets the webhook URL on Telegram.
 */
export async function setTelegramWebhook(webhookUrl: string): Promise<any> {
  try {
    const res = await fetch(`${TG_API_BASE}/setWebhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        url: webhookUrl,
        drop_pending_updates: false,
        allowed_updates: ['message'],
      }),
    });
    return await res.json();
  } catch (err: any) {
    console.error('Error setting Telegram webhook:', err);
    return { ok: false, error: err.message };
  }
}

/**
 * Retrieves the current webhook info from Telegram.
 */
export async function getTelegramWebhookInfo(): Promise<any> {
  try {
    const res = await fetch(`${TG_API_BASE}/getWebhookInfo`);
    return await res.json();
  } catch (err: any) {
    console.error('Error getting Telegram webhook info:', err);
    return { ok: false, error: err.message };
  }
}

/**
 * Checks if a chat is authenticated.
 */
export async function isChatAuthenticated(chatId: number | string): Promise<boolean> {
  try {
    const setting = await prisma.siteSetting.findUnique({
      where: { key: 'TELEGRAM_AUTHORIZED_CHATS' },
    });

    if (!setting || !setting.value) return false;
    const list: TelegramAuthUser[] = JSON.parse(setting.value);
    return list.some((u) => String(u.chatId) === String(chatId));
  } catch {
    return false;
  }
}

/**
 * Authorizes a chat after entering the correct password.
 */
export async function authorizeChat(
  chatId: number | string,
  userMeta?: { username?: string; firstName?: string }
): Promise<void> {
  try {
    const setting = await prisma.siteSetting.findUnique({
      where: { key: 'TELEGRAM_AUTHORIZED_CHATS' },
    });

    let list: TelegramAuthUser[] = [];
    if (setting && setting.value) {
      try {
        list = JSON.parse(setting.value);
      } catch {
        list = [];
      }
    }

    const existingIndex = list.findIndex((u) => String(u.chatId) === String(chatId));
    const record: TelegramAuthUser = {
      chatId,
      username: userMeta?.username,
      firstName: userMeta?.firstName,
      authAt: new Date().toISOString(),
    };

    if (existingIndex >= 0) {
      list[existingIndex] = record;
    } else {
      list.push(record);
    }

    await prisma.siteSetting.upsert({
      where: { key: 'TELEGRAM_AUTHORIZED_CHATS' },
      create: {
        key: 'TELEGRAM_AUTHORIZED_CHATS',
        value: JSON.stringify(list),
        category: 'REFERRAL',
        description: 'Authorized Telegram client chat IDs for invitation code generation',
      },
      update: {
        value: JSON.stringify(list),
      },
    });
  } catch (err) {
    console.error('Error authorizing Telegram chat:', err);
  }
}

/**
 * Assigns a random available 6-letter referral code to the requesting Telegram chat.
 */
export async function assignCodeForTelegramChat(
  chatId: number | string,
  userMeta?: { username?: string; firstName?: string }
): Promise<string> {
  // Query a random available code
  const available = await prisma.$queryRawUnsafe<any[]>(`
    SELECT "id", "code"
    FROM "AdminReferralCode"
    WHERE "status" = 'AVAILABLE'
    ORDER BY RANDOM()
    LIMIT 1
  `);

  let codeId: string;
  let code: string;

  if (available.length > 0) {
    codeId = available[0].id;
    code = available[0].code;
  } else {
    // Generate fresh codes if pool is exhausted
    const generated = await generateAdditionalCodes(10);
    code = generated[0];
    const row = await prisma.$queryRawUnsafe<any[]>(
      `SELECT "id" FROM "AdminReferralCode" WHERE "code" = $1 LIMIT 1`,
      code
    );
    codeId = row[0]?.id || `arc_tg_${Date.now()}`;
  }

  // Tag the code with TG:chatId in notes
  const tag = `TG:${chatId}|${userMeta?.username || userMeta?.firstName || 'Client'}`;
  await prisma.$executeRawUnsafe(
    `UPDATE "AdminReferralCode" SET "notes" = $1, "updatedAt" = CURRENT_TIMESTAMP WHERE "id" = $2`,
    tag,
    codeId
  );

  return code;
}

/**
 * Notifies the Telegram client who requested this code that it has been used.
 */
export async function notifyTelegramCodeUsed(
  code: string,
  user: { name: string; phone: string }
): Promise<void> {
  try {
    const rows = await prisma.$queryRawUnsafe<any[]>(
      `SELECT "notes" FROM "AdminReferralCode" WHERE LOWER("code") = $1 LIMIT 1`,
      code.toLowerCase()
    );

    if (rows.length === 0 || !rows[0].notes) return;
    const notes: string = rows[0].notes;

    // Look for TG:<chatId> tag
    const match = notes.match(/TG:([0-9-]+)/);
    if (!match) return;

    const targetChatId = match[1];
    const nowStr = new Date().toLocaleString('en-US', {
      timeZone: 'Asia/Karachi',
      dateStyle: 'medium',
      timeStyle: 'short',
    });

    const message =
      `🔔 *Invitation Code Used!*\n\n` +
      `🎟️ *Code:* \`${code.toLowerCase()}\`\n` +
      `👤 *Used by:* *${user.name}*\n` +
      `📱 *Phone:* \`${user.phone}\`\n` +
      `⏰ *Time:* ${nowStr} (PKT)\n\n` +
      `✅ Your user has successfully registered an account!`;

    await sendTelegramMessage(targetChatId, message, {
      keyboard: [[{ text: 'code' }]],
      resize_keyboard: true,
    });
  } catch (err) {
    console.error('Error notifying Telegram client of used code:', err);
  }
}

/**
 * Handles incoming updates from Telegram Webhook.
 */
export async function handleTelegramUpdate(update: any): Promise<void> {
  const message = update?.message;
  if (!message || !message.text) return;

  const chatId = message.chat.id;
  const rawText = message.text.trim();
  const lowerText = rawText.toLowerCase();
  const firstName = message.from?.first_name || 'Friend';
  const username = message.from?.username;

  const isAuth = await isChatAuthenticated(chatId);

  // Default Keyboard for authenticated users
  const authKeyboard = {
    keyboard: [[{ text: 'code' }]],
    resize_keyboard: true,
    one_time_keyboard: false,
  };

  // Case 1: User enters the secret password
  if (rawText === TELEGRAM_ACCESS_PASSWORD) {
    await authorizeChat(chatId, { username, firstName });
    await sendTelegramMessage(
      chatId,
      `✅ *Access Granted, ${firstName}!*\n\n` +
        `You are now authenticated to generate official invitation codes for new user signups.\n\n` +
        `👉 Send *code* anytime or tap the button below to get an invitation code.`,
      authKeyboard
    );
    return;
  }

  // Case 2: Not authenticated yet
  if (!isAuth) {
    await sendTelegramMessage(
      chatId,
      `👋 *Welcome, ${firstName}!*\n\n` +
        `Welcome to the *Official Invitation Code Bot*.\n\n` +
        `🔒 Please send the *password* to unlock invitation code generation:`
    );
    return;
  }

  // Case 3: Authenticated user requests code
  if (lowerText === 'code' || lowerText === '/code' || lowerText === 'get code') {
    const code = await assignCodeForTelegramChat(chatId, { username, firstName });

    await sendTelegramMessage(
      chatId,
      `🎟️ *Your Invitation Code:*\n\n` +
        `\`${code}\`\n\n` +
        `📋 _(Tap code above to copy)_\n\n` +
        `Give this 6-letter code to your user to create their account.\n\n` +
        `🔔 *You will receive an instant message here the moment this code is used to register!*`,
      authKeyboard
    );
    return;
  }

  // Case 4: Authenticated user sends /start or greeting
  if (lowerText === '/start' || lowerText === 'help' || lowerText === '/help') {
    await sendTelegramMessage(
      chatId,
      `👋 *Welcome Back, ${firstName}!*\n\n` +
        `Your access is active.\n\n` +
        `👉 Send *code* to generate a random invitation code.`,
      authKeyboard
    );
    return;
  }

  // Fallback for unknown messages from authenticated user
  await sendTelegramMessage(
    chatId,
    `Send *code* to receive a random invitation code.`,
    authKeyboard
  );
}
