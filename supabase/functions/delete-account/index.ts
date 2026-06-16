// delete-account — irreversibly delete the caller's account and all their data.
//
// The user is identified from their JWT; we then hard-delete that auth user with
// the service role. Every user-owned table is `on delete cascade` from
// auth.users, so the profile, essentials, sessions, ledger, streaks, devices,
// badges, notifications, etc. all go with it. Required for App Store / Play
// (apps with account creation must offer in-app deletion).

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const cors: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  // Identify the caller from their JWT — you can only ever delete yourself.
  const authHeader = req.headers.get('Authorization') ?? '';
  const asUser = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await asUser.auth.getUser();
  if (!user) return json({ error: 'unauthorized' }, 401);

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  try {
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) {
      console.error('delete-account failed:', error.message);
      return json({ error: 'delete_failed' }, 500);
    }
    return json({ deleted: true });
  } catch (e) {
    console.error('delete-account error:', e);
    return json({ error: 'server_error' }, 500);
  }
});
