import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';

const URL = 'http://127.0.0.1:55321';
const KEY = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
const email = `rtnode-${Date.now()}@lull.app`;

const sb = createClient(URL, KEY);
await sb.auth.signUp({ email, password: 'pw-123456' });
const { data: { session } } = await sb.auth.getSession();
if (!session) { console.log('FAIL: no session'); process.exit(1); }
const uid = session.user.id;
sb.realtime.setAuth(session.access_token);

let received = null;
const ch = sb.channel(`session:${uid}`, { config: { private: true } });
ch.on('broadcast', { event: 'session' }, (msg) => { received = msg.payload; });

await new Promise((res, rej) => {
  const t = setTimeout(() => rej(new Error('subscribe timeout')), 8000);
  ch.subscribe((status) => {
    if (status === 'SUBSCRIBED') { clearTimeout(t); res(); }
    if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') { clearTimeout(t); rej(new Error(status)); }
  });
}).catch((e) => { console.log('FAIL subscribe:', e.message); process.exit(1); });

console.log('subscribed to session:' + uid.slice(0, 8) + '…');

// Trigger a session via the real Edge Function (server-stamped insert → trigger → broadcast).
const { error } = await sb.functions.invoke('session-validate', {
  body: { action: 'start', plannedSeconds: 1500, idempotencyKey: randomUUID() },
});
if (error) { console.log('FAIL invoke:', error.message); process.exit(1); }
console.log('started a session, waiting for the broadcast…');

for (let i = 0; i < 60 && !received; i++) await new Promise(r => setTimeout(r, 100));

if (received && (received.id || (received.payload && received.payload.id))) {
  const p = received.payload?.id ? received.payload : received;
  console.log(`RECEIVED broadcast — planned_seconds=${p.planned_seconds}, started_at=${p.started_at}`);
  process.exit(0);
} else {
  console.log('FAIL: no broadcast received', JSON.stringify(received));
  process.exit(1);
}
