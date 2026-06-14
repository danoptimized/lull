-- ============================================================================
-- Lull — 0003_realtime
-- Live cross-device mirror: the server broadcasts every session change to the
-- owner's private channel so their other devices can render the running timer
-- in real time. Durable economy changes flow over postgres_changes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Broadcast session lifecycle changes to `session:<user_id>` (private).
-- ----------------------------------------------------------------------------
-- Fires on the service-role writes the session-validate function makes
-- (start/pause/resume/finalize). The payload is just the anchor + status — each
-- receiving device renders its own countdown from it (timestamp-anchored, so no
-- per-tick traffic). AFTER trigger, returns null.
create or replace function public.broadcast_session_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform realtime.send(
    jsonb_build_object(
      'id', new.id,
      'kind', new.kind,
      'started_at', new.started_at,
      'planned_seconds', new.planned_seconds,
      'pause_intervals', new.pause_intervals,
      'total_paused_seconds', new.total_paused_seconds,
      'ended_at', new.ended_at,
      'end_reason', new.end_reason,
      'is_valid', new.is_valid,
      'essential_id', new.essential_id,
      'client_id', new.client_id
    ),
    'session',                              -- event
    'session:' || new.user_id::text,        -- topic
    true                                    -- private channel
  );
  return null;
end;
$$;

create trigger pomodoro_sessions_broadcast
  after insert or update on public.pomodoro_sessions
  for each row
  execute function public.broadcast_session_change();

-- ----------------------------------------------------------------------------
-- Realtime authorization: a user may receive broadcasts and track presence
-- ONLY on their own session channel. realtime.messages has RLS on by default
-- with no policies, so private channels are locked until these are added.
-- ----------------------------------------------------------------------------
create policy "own session channel: receive"
  on realtime.messages
  for select
  to authenticated
  using (realtime.topic() = 'session:' || (select auth.uid())::text);

create policy "own session channel: presence/broadcast send"
  on realtime.messages
  for insert
  to authenticated
  with check (realtime.topic() = 'session:' || (select auth.uid())::text);

-- ----------------------------------------------------------------------------
-- Durable economy changes over postgres_changes: clients subscribe to their own
-- ledger/badge inserts (RLS already restricts SELECT to the owner) and refresh
-- stats. Replica identity full so row data is delivered.
-- ----------------------------------------------------------------------------
alter table public.points_ledger replica identity full;
alter table public.user_badges replica identity full;
alter publication supabase_realtime add table public.points_ledger;
alter publication supabase_realtime add table public.user_badges;
