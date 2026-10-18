import { createClient } from '@supabase/supabase-js';

const supabaseUrl =
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  'https://iwzonipiymbsspnyoszt.supabase.co';

const supabaseKey =
  process.env.SUPABASE_ANON_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  'sb_publishable_4EqCtWIiEIwm3ETQvxeOgA_fUcSKkiJ';

export const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Broadcast an instant command/notification to a user's active client session
 * without requiring the user to reload the page.
 */
export async function sendUserLiveCommand(userId: string, commandType: string, payload: any = {}) {
  try {
    const channel = supabase.channel(`royal_live_user_${userId}`);
    await channel.send({
      type: 'broadcast',
      event: 'live_command',
      payload: { targetUserId: userId, commandType, ...payload, timestamp: Date.now() },
    });
    supabase.removeChannel(channel);
  } catch (err) {
    console.warn(`[Supabase Broadcast] Notice for user ${userId}:`, err);
  }
}
