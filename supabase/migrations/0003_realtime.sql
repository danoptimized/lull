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
-- Topics are `<kind>:<user_id>` (session: for the mirror, presence: for the
-- live device list). A user may receive and track on any topic that ends in
-- their own id.
create policy "own channels: receive"
  on realtime.messages
  for select
  to authenticated
  using (split_part(realtime.topic(), ':', 2) = (select auth.uid())::text);

create policy "own channels: presence/broadcast send"
  on realtime.messages
  for insert
  to authenticated
  with check (split_part(realtime.topic(), ':', 2) = (select auth.uid())::text);

-- ----------------------------------------------------------------------------
-- Economy changes also broadcast from the database (same proven path as the
-- session mirror) to `economy:<user_id>`, so a watching device refreshes its
-- stats/essentials when another device finishes a session or earns a badge.
-- ----------------------------------------------------------------------------
create or replace function public.broadcast_economy_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform realtime.send(
    jsonb_build_object('table', tg_table_name, 'id', new.id::text),
    'economy',
    'economy:' || new.user_id::text,
    true
  );
  return null;
end;
$$;

create trigger points_ledger_economy_broadcast
  after insert on public.points_ledger
  for each row
  execute function public.broadcast_economy_change();

create trigger user_badges_economy_broadcast
  after insert on public.user_badges
  for each row
  execute function public.broadcast_economy_change();
