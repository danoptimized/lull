// session-validate — the server-authoritative pomodoro session lifecycle.
//
// Clients never write `pomodoro_sessions` directly (RLS forbids it). They POST
// one of four actions here; the server stamps time, records pauses, and decides
// validity. Because a session can only EXIST if `start` succeeded online, the
// "creditable sessions require an online start" rule is enforced by construction
// — a session run fully offline never reaches this function and is never valid.
//
// Body: { action: 'start'|'pause'|'resume'|'finalize', ... }. Every response
// includes `serverNow` (ISO) so the client can measure clock skew (used in M5).
//
// NOTE: crediting the reward ledger (award_for_session) is wired in M4; this
// function only establishes whether a finished session is_valid.

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const cors: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/** Reward integrity tolerance: a completed focus may finish a few seconds shy. */
const COMPLETION_TOLERANCE_SECONDS = 5;

/**
 * Floor on a creditable focus session's planned length. The v1 Pomodoro is a
 * fixed 25 min, so any real focus is far above this; the floor exists so a
 * tampered-down `plannedSeconds` can't mint points for a trivial session.
 */
const MIN_CREDITABLE_FOCUS_SECONDS = 300;

type Pause = { start: string; end: string | null };

/** The session kinds a client may start. */
const SESSION_KINDS = new Set(['focus', 'short_break', 'long_break']);

/** Loose UUID shape — rejects obviously-garbage ids before any DB hit. */
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

/** Total paused seconds, treating a still-open pause as ending at [nowMs]. */
function pausedSeconds(pauses: Pause[], nowMs: number): number {
  let total = 0;
  for (const p of pauses) {
    const start = Date.parse(p.start);
    const end = p.end ? Date.parse(p.end) : nowMs;
    total += Math.max(0, Math.floor((end - start) / 1000));
  }
  return total;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  // Identify the caller from their JWT (RLS-scoped client just for the check).
  const authHeader = req.headers.get('Authorization') ?? '';
  const asUser = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await asUser.auth.getUser();
  if (!user) return json({ error: 'unauthorized' }, 401);

  // Authoritative writes use the service role (bypasses RLS); every write is
  // still scoped to this verified user id.
  const db: SupabaseClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const action = body.action;
  const nowIso = new Date().toISOString();

  try {
    switch (action) {
      case 'time':
        // Lightweight clock-sync ping for mirror skew correction.
        return json({ serverNow: nowIso });
      case 'start':
        return await start(db, user.id, body, nowIso);
      case 'pause':
        return await pause(db, user.id, body, nowIso);
      case 'resume':
        return await resume(db, user.id, body, nowIso);
      case 'finalize':
        return await finalize(db, user.id, body, nowIso);
      default:
        return json({ error: 'unknown_action' }, 400);
    }
  } catch (e) {
    // Log the real error server-side; never leak DB/internal detail to clients.
    console.error('session-validate error:', e);
    return json({ error: 'server_error' }, 500);
  }
});

async function start(
  db: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
  nowIso: string,
): Promise<Response> {
  const idempotencyKey = body.idempotencyKey as string | undefined;
  const kind = (body.kind as string) ?? 'focus';
  const plannedSeconds = body.plannedSeconds as number;
  if (!idempotencyKey || typeof plannedSeconds !== 'number') {
    return json({ error: 'missing_fields' }, 400);
  }
  // Validate up front rather than leaning on DB constraints (whose errors would
  // leak column/constraint names). A planned focus is 25 min; cap generously.
  if (
    !Number.isInteger(plannedSeconds) ||
    plannedSeconds < 60 ||
    plannedSeconds > 7200
  ) {
    return json({ error: 'invalid_planned_seconds' }, 400);
  }
  if (!SESSION_KINDS.has(kind)) {
    return json({ error: 'invalid_kind' }, 400);
  }

  // Idempotent retry: the same key always returns the same row.
  const { data: byKey } = await db
    .from('pomodoro_sessions')
    .select()
    .eq('idempotency_key', idempotencyKey)
    .maybeSingle();
  if (byKey) return json({ session: byKey, serverNow: nowIso, replayed: true });

  // At most one active focus per user: adopt the existing one instead of erroring
  // (the second device becomes a mirror in M5).
  if (kind === 'focus') {
    const { data: active } = await db
      .from('pomodoro_sessions')
      .select()
      .eq('user_id', userId)
      .eq('kind', 'focus')
      .is('ended_at', null)
      .maybeSingle();
    if (active) {
      return json({ session: active, serverNow: nowIso, adopted: true });
    }
  }

  const { data, error } = await db
    .from('pomodoro_sessions')
    .insert({
      user_id: userId,
      kind,
      started_at: nowIso, // server-stamped anchor
      planned_seconds: plannedSeconds,
      pause_intervals: [],
      total_paused_seconds: 0,
      essential_id: (body.essentialId as string | null) ?? null,
      client_id: (body.clientId as string | null) ?? null,
      idempotency_key: idempotencyKey,
    })
    .select()
    .single();
  if (error) {
    console.error('session insert failed:', error.message);
    return json({ error: 'insert_failed' }, 409);
  }

  return json({ session: data, serverNow: nowIso });
}

async function loadActive(
  db: SupabaseClient,
  userId: string,
  sessionId: string,
) {
  const { data } = await db
    .from('pomodoro_sessions')
    .select()
    .eq('id', sessionId)
    .eq('user_id', userId)
    .is('ended_at', null)
    .maybeSingle();
  return data;
}

async function pause(
  db: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
  nowIso: string,
): Promise<Response> {
  const sessionId = body.sessionId as string;
  if (!UUID_RE.test(sessionId ?? '')) {
    return json({ error: 'invalid_session_id' }, 400);
  }
  const row = await loadActive(db, userId, sessionId);
  if (!row) return json({ error: 'no_active_session' }, 404);

  const pauses = (row.pause_intervals as Pause[]) ?? [];
  // Idempotent: already paused → no-op.
  if (pauses.length > 0 && pauses[pauses.length - 1].end === null) {
    return json({ session: row, serverNow: nowIso, replayed: true });
  }
  pauses.push({ start: nowIso, end: null });

  const { data } = await db
    .from('pomodoro_sessions')
    .update({ pause_intervals: pauses })
    .eq('id', sessionId)
    .select()
    .single();
  return json({ session: data, serverNow: nowIso });
}

async function resume(
  db: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
  nowIso: string,
): Promise<Response> {
  const sessionId = body.sessionId as string;
  if (!UUID_RE.test(sessionId ?? '')) {
    return json({ error: 'invalid_session_id' }, 400);
  }
  const row = await loadActive(db, userId, sessionId);
  if (!row) return json({ error: 'no_active_session' }, 404);

  const pauses = (row.pause_intervals as Pause[]) ?? [];
  if (pauses.length === 0 || pauses[pauses.length - 1].end !== null) {
    return json({ session: row, serverNow: nowIso, replayed: true });
  }
  pauses[pauses.length - 1].end = nowIso;
  const total = pausedSeconds(pauses, Date.parse(nowIso));

  const { data } = await db
    .from('pomodoro_sessions')
    .update({ pause_intervals: pauses, total_paused_seconds: total })
    .eq('id', sessionId)
    .select()
    .single();
  return json({ session: data, serverNow: nowIso });
}

async function finalize(
  db: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
  nowIso: string,
): Promise<Response> {
  const sessionId = body.sessionId as string;
  if (!UUID_RE.test(sessionId ?? '')) {
    return json({ error: 'invalid_session_id' }, 400);
  }

  // Idempotent: a finalized session returns its recorded verdict.
  const { data: existing } = await db
    .from('pomodoro_sessions')
    .select()
    .eq('id', sessionId)
    .eq('user_id', userId)
    .maybeSingle();
  if (!existing) return json({ error: 'not_found' }, 404);
  if (existing.ended_at) {
    return json({ session: existing, serverNow: nowIso, replayed: true });
  }

  const nowMs = Date.parse(nowIso);
  const pauses = (existing.pause_intervals as Pause[]) ?? [];
  const totalPaused = pausedSeconds(pauses, nowMs);
  const elapsed = Math.max(
    0,
    Math.floor((nowMs - Date.parse(existing.started_at)) / 1000) - totalPaused,
  );

  const completed = elapsed >= existing.planned_seconds - COMPLETION_TOLERANCE_SECONDS;
  // No-pause rule: any pause voids the reward. We honor both the server's own
  // record AND a client-reported pause, so a pause that happened while offline
  // (its pause/resume calls never arrived) still voids on finalize.
  const hadPause = pauses.length > 0 || body.clientPaused === true;
  // Validity also requires a focus session that actually ran its full length,
  // and one whose planned length clears the creditable floor.
  const isValid = existing.kind === 'focus' &&
    existing.planned_seconds >= MIN_CREDITABLE_FOCUS_SECONDS &&
    completed && !hadPause;

  const { data } = await db
    .from('pomodoro_sessions')
    .update({
      ended_at: nowIso,
      end_reason: completed ? 'completed' : 'aborted',
      total_paused_seconds: totalPaused,
      is_valid: isValid,
    })
    .eq('id', sessionId)
    .select()
    .single();

  // Mint the reward in one atomic Postgres transaction: ledger (hash-chained),
  // streak/multiplier, task + daily bonuses, the linked essential's progress,
  // and badge grants. Idempotent by session id, so a finalize retry is safe.
  let award: unknown = null;
  if (isValid) {
    // Rate-limit credited focus sessions to blunt scripted farming: a real
    // person completes well under 20 valid sessions in a rolling hour.
    const since = new Date(nowMs - 3_600_000).toISOString();
    const { count, error: countError } = await db
      .from('points_ledger')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('entry_type', 'session_complete')
      .gte('created_at', since);
    if (countError || (count ?? 0) >= 20) {
      // Fail closed: if we can't verify the rate, don't mint.
      award = { rate_limited: true };
    } else {
      const { data: awarded, error } = await db.rpc('award_for_session', {
        p_session_id: sessionId,
        p_user_id: userId,
      });
      if (!error) award = awarded;
    }
  }

  return json({ session: data, serverNow: nowIso, isValid, award });
}
