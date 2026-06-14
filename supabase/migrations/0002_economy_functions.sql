-- ============================================================================
-- Lull — 0002_economy_functions
-- Server-authoritative reward economy: awarding, badge grants, chain verify.
--
-- All functions are SECURITY DEFINER with a pinned search_path. They are
-- intended to be called by Edge Functions (service role) or pg_cron — never
-- directly by clients, so EXECUTE is revoked from anon/authenticated.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- user_local_date(p_user_id) — "today" in the user's profile timezone
-- ----------------------------------------------------------------------------
create or replace function public.user_local_date(p_user_id uuid)
returns date
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select (now() at time zone coalesce(
            (select p.timezone from public.profiles p where p.id = p_user_id),
            'UTC'))::date;
$$;

-- ----------------------------------------------------------------------------
-- grant_badge_if_absent(p_user_id, p_code) — idempotent badge grant
-- ----------------------------------------------------------------------------
-- Inserts a 0-point badge_grant ledger row plus the user_badges row, linked
-- via source_ledger_id. Returns true only when the badge was newly granted.
-- Missing catalog entries (unseeded badges) are a silent no-op.
create or replace function public.grant_badge_if_absent(p_user_id uuid, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_badge_id  uuid;
  v_ledger_id bigint;
begin
  select b.id into v_badge_id from public.badges b where b.code = p_code;
  if v_badge_id is null then
    return false; -- badge not in catalog (seed not applied); skip quietly
  end if;

  if exists (
    select 1 from public.user_badges ub
     where ub.user_id = p_user_id and ub.badge_id = v_badge_id
  ) then
    return false; -- already granted
  end if;

  -- Deterministic idempotency key: one grant per (user, badge code), ever.
  insert into public.points_ledger
    (user_id, entry_type, points, multiplier, badge_id, idempotency_key)
  values
    (p_user_id, 'badge_grant', 0, 1.0, v_badge_id,
     md5('badge_grant:' || p_user_id::text || ':' || p_code)::uuid)
  on conflict (idempotency_key) do nothing
  returning id into v_ledger_id;

  insert into public.user_badges (user_id, badge_id, source_ledger_id)
  values (p_user_id, v_badge_id, v_ledger_id)
  on conflict (user_id, badge_id) do nothing;

  return true;
end;
$$;

-- ----------------------------------------------------------------------------
-- award_for_session(p_session_id) — credit a finalized, valid focus session
-- ----------------------------------------------------------------------------
-- In one transaction:
--   1. validate the session (focus, completed, is_valid, not yet credited),
--   2. roll the streak forward and recompute the multiplier,
--   3. append ledger rows: session_complete (multiplied), task_target_bonus
--      when the linked essential just hit its target, daily_complete_bonus
--      once per local day when all three essentials are done,
--   4. upsert daily_progress,
--   5. evaluate and grant simple badges idempotently.
-- Every ledger insert uses a deterministic md5-derived idempotency key, so
-- the whole function is safe to retry.
create or replace function public.award_for_session(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_session        public.pomodoro_sessions%rowtype;
  v_cfg            public.economy_config%rowtype;
  v_streak         public.streaks%rowtype;
  v_essential      public.daily_essentials%rowtype;
  v_today          date;
  v_session_key    uuid;
  v_new_len        integer;
  v_multiplier     numeric(4, 2);
  v_points_total   integer := 0;
  v_session_points integer;
  v_completed_cnt  integer;
  v_perfect_days   integer;
  v_valid_sessions bigint;
  v_rows           integer;
  v_badges         text[] := '{}';
begin
  -- 1) Load and validate the session (locked for the duration).
  select * into v_session
    from public.pomodoro_sessions
   where id = p_session_id
   for update;

  if not found then
    raise exception 'award_for_session: session % not found', p_session_id;
  end if;

  if v_session.kind <> 'focus'
     or v_session.ended_at is null
     or v_session.end_reason is distinct from 'completed'
     or v_session.is_valid is distinct from true then
    raise exception
      'award_for_session: session % is not a finalized, valid, completed focus session',
      p_session_id;
  end if;

  -- Idempotency: deterministic ledger key for this session's credit.
  v_session_key := md5('session_complete:' || p_session_id::text)::uuid;
  if exists (select 1 from public.points_ledger where idempotency_key = v_session_key) then
    select * into v_streak from public.streaks where user_id = v_session.user_id;
    return jsonb_build_object(
      'points_awarded', 0,
      'multiplier',     coalesce(v_streak.current_multiplier, 1.0),
      'badges_granted', to_jsonb('{}'::text[]),
      'streak_len',     coalesce(v_streak.current_len, 0),
      'already_awarded', true);
  end if;

  select * into v_cfg from public.economy_config where id = 1;
  v_today := public.user_local_date(v_session.user_id);

  -- 2) Streak roll-forward (row locked to serialize concurrent awards).
  insert into public.streaks (user_id) values (v_session.user_id)
  on conflict (user_id) do nothing;

  select * into v_streak
    from public.streaks
   where user_id = v_session.user_id
   for update;

  if v_streak.last_active_local_date = v_today then
    v_new_len := greatest(v_streak.current_len, 1);   -- already active today
  elsif v_streak.last_active_local_date = v_today - 1 then
    v_new_len := v_streak.current_len + 1;            -- consecutive day
  else
    v_new_len := 1;                                   -- gap (or first ever)
  end if;

  v_multiplier := least(1 + v_cfg.streak_step * (v_new_len - 1), v_cfg.streak_cap);

  update public.streaks
     set current_len            = v_new_len,
         longest_len            = greatest(longest_len, v_new_len),
         last_active_local_date = v_today,
         current_multiplier     = v_multiplier,
         updated_at             = now()
   where user_id = v_session.user_id;

  -- 3a) session_complete: base points scaled by the streak multiplier.
  v_session_points := round(v_cfg.session_points * v_multiplier)::integer;

  insert into public.points_ledger
    (user_id, entry_type, points, multiplier, session_id, idempotency_key)
  values
    (v_session.user_id, 'session_complete', v_session_points, v_multiplier,
     p_session_id, v_session_key)
  on conflict (idempotency_key) do nothing;
  get diagnostics v_rows = row_count;

  if v_rows = 0 then
    -- Lost a race with a concurrent retry that already credited the session.
    return jsonb_build_object(
      'points_awarded', 0,
      'multiplier',     v_multiplier,
      'badges_granted', to_jsonb('{}'::text[]),
      'streak_len',     v_new_len,
      'already_awarded', true);
  end if;

  v_points_total := v_points_total + v_session_points;

  -- 3b) Linked essential: count this pomodoro; if it just hit its target,
  --     mark completion and award the (flat) task bonus once per essential.
  if v_session.essential_id is not null then
    select * into v_essential
      from public.daily_essentials
     where id = v_session.essential_id
       and user_id = v_session.user_id
     for update;

    if found then
      update public.daily_essentials
         set completed_pomodoros = completed_pomodoros + 1
       where id = v_essential.id
       returning * into v_essential;

      if v_essential.completed_at is null
         and v_essential.completed_pomodoros = v_essential.target_pomodoros then
        update public.daily_essentials
           set completed_at = now()
         where id = v_essential.id;

        insert into public.points_ledger
          (user_id, entry_type, points, multiplier, essential_id, idempotency_key)
        values
          (v_session.user_id, 'task_target_bonus', v_cfg.task_bonus, 1.0,
           v_essential.id,
           md5('task_target_bonus:' || v_essential.id::text)::uuid)
        on conflict (idempotency_key) do nothing;
        get diagnostics v_rows = row_count;
        if v_rows > 0 then
          v_points_total := v_points_total + v_cfg.task_bonus;
        end if;
      end if;
    end if;
  end if;

  -- 3c) Daily completion bonus: all three of today's essentials done.
  --     Deterministic key from (user, type, local_date) → once per day.
  select count(*) into v_completed_cnt
    from public.daily_essentials de
   where de.user_id = v_session.user_id
     and de.local_date = v_today
     and de.completed_at is not null;

  if v_completed_cnt >= 3 then
    insert into public.points_ledger
      (user_id, entry_type, points, multiplier, idempotency_key)
    values
      (v_session.user_id, 'daily_complete_bonus', v_cfg.daily_bonus, 1.0,
       md5('daily_complete_bonus:' || v_session.user_id::text || ':' || v_today::text)::uuid)
    on conflict (idempotency_key) do nothing;
    get diagnostics v_rows = row_count;
    if v_rows > 0 then
      v_points_total := v_points_total + v_cfg.daily_bonus;
    end if;
  end if;

  -- 4) Daily progress rollup.
  insert into public.daily_progress
    (user_id, local_date, sessions_completed, essentials_completed,
     points_earned, all_three_done)
  values
    (v_session.user_id, v_today, 1, least(v_completed_cnt, 3),
     v_points_total, v_completed_cnt >= 3)
  on conflict (user_id, local_date) do update set
    sessions_completed   = public.daily_progress.sessions_completed + 1,
    essentials_completed = excluded.essentials_completed,
    points_earned        = public.daily_progress.points_earned + excluded.points_earned,
    all_three_done       = excluded.all_three_done;

  -- 5) Badge evaluation (each grant is idempotent; ledger rows carry 0 points).
  select count(*) into v_valid_sessions
    from public.pomodoro_sessions ps
   where ps.user_id = v_session.user_id
     and ps.kind = 'focus'
     and ps.is_valid = true
     and ps.end_reason = 'completed';

  if v_valid_sessions >= 1
     and public.grant_badge_if_absent(v_session.user_id, 'first_focus') then
    v_badges := v_badges || 'first_focus';
  end if;

  if v_new_len >= 7
     and public.grant_badge_if_absent(v_session.user_id, 'seven_day_streak') then
    v_badges := v_badges || 'seven_day_streak';
  end if;

  select count(*) into v_perfect_days
    from public.daily_progress dp
   where dp.user_id = v_session.user_id
     and dp.local_date between v_today - 6 and v_today
     and dp.all_three_done;

  if v_perfect_days = 7
     and public.grant_badge_if_absent(v_session.user_id, 'perfect_week') then
    v_badges := v_badges || 'perfect_week';
  end if;

  if v_valid_sessions >= 100
     and public.grant_badge_if_absent(v_session.user_id, 'hundred_sessions') then
    v_badges := v_badges || 'hundred_sessions';
  end if;

  return jsonb_build_object(
    'points_awarded', v_points_total,
    'multiplier',     v_multiplier,
    'badges_granted', to_jsonb(v_badges),
    'streak_len',     v_new_len);
end;
$$;

-- ----------------------------------------------------------------------------
-- verify_ledger_chain(p_user_id) — recompute the user's hash chain + balance
-- ----------------------------------------------------------------------------
-- Walks the ledger in id order, recomputing every entry_hash, prev_hash link
-- and running balance with the exact formula used by the insert trigger
-- (created_at rendered as UTC ISO text via to_char, timezone-independent).
-- Returns false at the first discrepancy. Intended for a pg_cron verifier.
create or replace function public.verify_ledger_chain(p_user_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  r            record;
  v_prev_hash  text   := null;
  v_balance    bigint := 0;
  v_expected   text;
begin
  for r in
    select *
      from public.points_ledger
     where user_id = p_user_id
     order by id
  loop
    if r.prev_hash is distinct from v_prev_hash then
      return false;
    end if;

    v_expected := encode(
      sha256(convert_to(
        coalesce(v_prev_hash, 'genesis')
        || r.user_id::text
        || r.entry_type
        || r.points::text
        || coalesce(r.session_id::text, '')
        || r.idempotency_key::text
        || to_char(r.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'utf8')),
      'hex');

    if r.entry_hash <> v_expected then
      return false;
    end if;

    v_balance := v_balance + r.points;
    if r.balance_after <> v_balance then
      return false;
    end if;

    v_prev_hash := r.entry_hash;
  end loop;

  return true;
end;
$$;

-- ----------------------------------------------------------------------------
-- Execution privileges: server-side only
-- ----------------------------------------------------------------------------
revoke execute on function public.user_local_date(uuid)            from public, anon, authenticated;
revoke execute on function public.grant_badge_if_absent(uuid, text) from public, anon, authenticated;
revoke execute on function public.award_for_session(uuid)          from public, anon, authenticated;
revoke execute on function public.verify_ledger_chain(uuid)        from public, anon, authenticated;

grant execute on function public.user_local_date(uuid)             to service_role;
grant execute on function public.grant_badge_if_absent(uuid, text) to service_role;
grant execute on function public.award_for_session(uuid)           to service_role;
grant execute on function public.verify_ledger_chain(uuid)         to service_role;
