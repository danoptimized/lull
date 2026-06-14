import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'crypto';

const URL = 'http://127.0.0.1:55321';
const ANON = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
const SERVICE =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';
const email = `rtx-${Date.now()}@lull.app`;

const sb = createClient(URL, ANON);
await sb.auth.signUp({ email, password: 'pw-123456' });
const { data: { session } } = await sb.auth.getSession();
const uid = session.user.id;
sb.realtime.setAuth(session.access_token);

const waitSub = (ch, label) => new Promise((res, rej) => {
  const t = setTimeout(() => rej(new Error(`${label} subscribe timeout`)), 8000);
  ch.subscribe((s) => {
    if (s === 'SUBSCRIBED') { clearTimeout(t); res(); }
    if (s === 'CHANNEL_ERROR' || s === 'TIMED_OUT') { clearTimeout(t); rej(new Error(`${label}:${s}`)); }
  });
});

// --- economy: broadcast-from-database on ledger insert ---
let gotEconomy = false;
const econ = sb.channel(`economy:${uid}`, { config: { private: true } });
econ.on('broadcast', { event: 'economy' }, () => { gotEconomy = true; });
await waitSub(econ, 'economy');
const admin = createClient(URL, SERVICE);
const { error: insErr } = await admin.from('points_ledger').insert({
  user_id: uid, entry_type: 'adjustment', points: 1, idempotency_key: randomUUID(),
});
if (insErr) console.log('ECONOMY insert error:', insErr.message);
for (let i = 0; i < 60 && !gotEconomy; i++) await new Promise((r) => setTimeout(r, 100));
console.log(gotEconomy ? 'ECONOMY: received broadcast on ledger insert ✓' : 'ECONOMY: FAIL (no event)');

// --- presence: two devices, same user ---
const sb2 = createClient(URL, ANON);
await sb2.auth.signInWithPassword({ email, password: 'pw-123456' });
const { data: { session: s2 } } = await sb2.auth.getSession();
sb2.realtime.setAuth(s2.access_token);

let count1 = 0;
const p1 = sb.channel(`presence:${uid}`, { config: { private: true, presence: { key: 'dev-1' } } });
p1.on('presence', { event: 'sync' }, () => { count1 = Object.keys(p1.presenceState()).length; });
await waitSub(p1, 'presence-1');
await p1.track({ device_id: 'dev-1' });
const p2 = sb2.channel(`presence:${uid}`, { config: { private: true, presence: { key: 'dev-2' } } });
await waitSub(p2, 'presence-2');
await p2.track({ device_id: 'dev-2' });
for (let i = 0; i < 60 && count1 < 2; i++) await new Promise((r) => setTimeout(r, 100));
console.log(count1 >= 2 ? `PRESENCE: device 1 sees ${count1} devices ✓` : `PRESENCE: FAIL (count=${count1})`);

process.exit(gotEconomy && count1 >= 2 ? 0 : 1);
