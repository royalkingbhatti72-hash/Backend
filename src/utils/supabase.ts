import { createClient } from '@supabase/supabase-js';

const supabaseUrl =
  process.env.SUPABASE_URL ||
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  'https://ilrngvidbuenxfgsbpim.supabase.co';

const supabaseKey =
  process.env.SUPABASE_ANON_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  'sb_publishable_4EqCtWIiEIwm3ETQvxeOgA_fUcSKkiJ';

export const supabase = createClient(supabaseUrl, supabaseKey);
