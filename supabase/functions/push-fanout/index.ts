// push-fanout — deliver one notification to a user's enabled devices via FCM.
//
// Invoked by a Supabase Database Webhook on `notification_log` INSERT (which
// sends the service-role key as the bearer). The same event already reaches
// open apps over Realtime (M6 part 1); this adds out-of-app delivery.
//
// Body: the webhook envelope `{ type, table, record: {...} }`, where `record`
// is the inserted notification_log row (user_id, category, title, body).
//
// FCM credentials: the service-account JSON is read from the `FCM_SERVICE_ACCOUNT`
// secret. Until that secret is set the function is a no-op (sent: 0), so it is
// safe to deploy ahead of the credential.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_SERVICE_ACCOUNT = Deno.env.get('FCM_SERVICE_ACCOUNT');

/** notification_log.category → the devices opt-in column it honors. */
const CATEGORY_COLUMN: Record<string, string> = {
  timer: 'notify_timer',
  essentials: 'notify_essentials',
  streak: 'notify_streak',
  rewards: 'notify_rewards',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// --- Google OAuth: mint an access token from the service account -------------

function b64url(bytes: Uint8Array): string {
  let s = btoa(String.fromCharCode(...bytes));
  return s.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToDer(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/, '')
    .replace(/-----END [^-]+-----/, '')
    .replace(/\s+/g, '');
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

async function mintAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(
    new TextEncoder().encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })),
  );
  const claims = b64url(
    new TextEncoder().encode(
      JSON.stringify({
        iss: sa.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
      }),
    ),
  );
  const signingInput = `${header}.${claims}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      key,
      new TextEncoder().encode(signingInput),
    ),
  );
  const jwt = `${signingInput}.${b64url(signature)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`oauth token failed: ${res.status} ${await res.text()}`);
  }
  return (await res.json()).access_token as string;
}

/** Send to one device token. Reports whether the token is dead (unregistered). */
async function sendToToken(
  projectId: string,
  accessToken: string,
  token: string,
  title: string,
  body: string,
): Promise<{ ok: boolean; unregistered: boolean }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: { token, notification: { title, body } },
      }),
    },
  );
  if (res.ok) return { ok: true, unregistered: false };
  // 404 UNREGISTERED / 400 invalid → the token will never work again.
  const text = await res.text();
  const unregistered =
    res.status === 404 || text.includes('UNREGISTERED') ||
    text.includes('INVALID_ARGUMENT');
  return { ok: false, unregistered };
}

Deno.serve(async (req) => {
  // Only the database (service role) may trigger a fan-out.
  if (req.headers.get('Authorization') !== `Bearer ${SERVICE_ROLE_KEY}`) {
    return json({ error: 'unauthorized' }, 401);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const record = (payload.record ?? payload) as Record<string, unknown>;
  const userId = record.user_id as string | undefined;
  const category = record.category as string | undefined;
  const title = (record.title as string | null) ?? 'lull';
  const body = (record.body as string | null) ?? '';
  const column = category ? CATEGORY_COLUMN[category] : undefined;
  if (!userId || !column) return json({ skipped: true });

  // Deployed-but-not-configured is a valid state: no credential → no-op.
  if (!FCM_SERVICE_ACCOUNT) return json({ sent: 0, reason: 'no_fcm_credentials' });

  const db = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data: devices } = await db
    .from('devices')
    .select('id, push_token')
    .eq('user_id', userId)
    .eq(column, true)
    .not('push_token', 'is', null);
  if (!devices || devices.length === 0) return json({ sent: 0 });

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(FCM_SERVICE_ACCOUNT) as ServiceAccount;
  } catch {
    return json({ error: 'bad_fcm_credentials' }, 500);
  }

  const accessToken = await mintAccessToken(sa);
  let sent = 0;
  const dead: string[] = [];
  for (const device of devices) {
    const result = await sendToToken(
      sa.project_id,
      accessToken,
      device.push_token as string,
      title,
      body,
    );
    if (result.ok) sent++;
    else if (result.unregistered) dead.push(device.id as string);
  }
  // Prune dead tokens so we stop trying them.
  if (dead.length > 0) {
    await db.from('devices').update({ push_token: null }).in('id', dead);
  }

  return json({ sent, pruned: dead.length });
});
