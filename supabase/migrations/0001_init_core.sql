-- ============================================================================
-- Lull — 0001_init_core
-- Core schema, triggers, RLS, and append-only ledger hardening.
--
-- Conventions:
--   * All app tables live in `public`.
--   * All tables have RLS enabled; clients only ever see their own rows.
--   * Server-authoritative tables (pomodoro_sessions, points_ledger, streaks,
--     daily_progress, user_badges, notification_log) accept NO client writes;
--     Edge Functions use the service role.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Extensions
-- ----------------------------------------------------------------------------
-- pgcrypto: gen_random_uuid() (core in PG13+, kept for parity) and digest
-- helpers. sha256(bytea) itself is a core function. Installed into the
-- `extensions` schema per Supabase convention.
create extension if not exists pgcrypto with schema extensions;

-- ----------------------------------------------------------------------------
-- profiles — one row per auth user, auto-created on signup
-- ----------------------------------------------------------------------------
create table public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  display_name    text,
  avatar_url      text,
  timezone        text not null default 'UTC',
  reduced_motion  boolean not null default false,
  theme_mode      text not null default 'system'
                    check (theme_mode in ('system', 'light', 'dark')),
  created_at      timestamptz not null default now()
);

comment on table public.profiles is
  'Per-user settings; auto-created by trigger on auth.users insert.';

-- Auto-create a profile when an auth user is created.
-- SECURITY DEFINER so it can write to public.profiles regardless of the
-- (auth-internal) role performing the signup insert.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- devices — push targets + per-device notification preferences
-- ----------------------------------------------------------------------------
create table public.devices (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users (id) on delete cascade,
  platform           text not null
                       check (platform in ('ios', 'android', 'web', 'macos')),
  push_token         text,
  token_updated_at   timestamptz,
  display_label      text,
  notify_timer       boolean not null default true,
  notify_essentials  boolean not null default true,
  notify_streak      boolean not null default true,
  notify_rewards     boolean not null default true,
  last_seen_at       timestamptz,
  created_at         timestamptz not null default now()
);

-- A given push token registers at most once per user.
create unique index devices_user_push_token_uniq
  on public.devices (user_id, push_token)
  where push_token is not null;

create index devices_user_id_idx on public.devices (user_id);

-- ----------------------------------------------------------------------------
-- daily_essentials — the three intentions of each local day
-- ----------------------------------------------------------------------------
create table public.daily_essentials (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users (id) on delete cascade,
  local_date          date not null,
  slot                smallint not null check (slot in (1, 2, 3)),
  title               text not null
                        check (char_length(title) between 1 and 120),
  target_pomodoros    smallint not null default 1
                        check (target_pomodoros between 1 and 12),
  completed_pomodoros smallint not null default 0
                        check (completed_pomodoros >= 0),
  completed_at        timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (user_id, local_date, slot)
);

-- Essentials can only be created for "today" as seen from the user's own
-- timezone (profiles.timezone). SECURITY DEFINER so the profile lookup works
-- under any caller, with a defensive UTC fallback.
create or replace function public.enforce_essential_is_today()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tz    text;
  v_today date;
begin
  select p.timezone into v_tz
    from public.profiles p
   where p.id = new.user_id;

  v_tz := coalesce(v_tz, 'UTC');
  v_today := (now() at time zone v_tz)::date;

  if new.local_date <> v_today then
    raise exception
      'daily_essentials.local_date must be today (%) in your timezone (%); got %',
      v_today, v_tz, new.local_date
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger daily_essentials_today_check
  before insert on public.daily_essentials
  for each row
  execute function public.enforce_essential_is_today();

-- Keep updated_at fresh on any update.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger daily_essentials_set_updated_at
  before update on public.daily_essentials
  for each row
  execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- pomodoro_sessions — server-authoritative timer sessions
-- ----------------------------------------------------------------------------
create table public.pomodoro_sessions (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references auth.users (id) on delete cascade,
  essential_id         uuid references public.daily_essentials (id) on delete set null,
  kind                 text not null default 'focus'
                         check (kind in ('focus', 'short_break', 'long_break')),
  started_at           timestamptz not null,
  planned_seconds      integer not null
                         check (planned_seconds between 60 and 7200),
  pause_intervals      jsonb not null default '[]',
  total_paused_seconds integer not null default 0,
  ended_at             timestamptz,
  end_reason           text
                         check (end_reason in ('completed', 'aborted', 'voided_pause', 'expired')),
  client_id            text,
  idempotency_key      uuid not null unique,
  is_valid             boolean,
  created_at           timestamptz not null default now()
);

create index pomodoro_sessions_user_started_idx
  on public.pomodoro_sessions (user_id, started_at desc);

-- At most ONE active (un-ended) focus session per user.
create unique index pomodoro_sessions_one_active_focus
  on public.pomodoro_sessions (user_id)
  where ended_at is null and kind = 'focus';

-- ----------------------------------------------------------------------------
-- badges — global catalog (seeded separately)
-- ----------------------------------------------------------------------------
create table public.badges (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text not null,
  description text not null,
  rarity      text not null default 'common'
                check (rarity in ('common', 'uncommon', 'rare')),
  icon_ref    text,
  criteria    jsonb not null default '{}',
  created_at  timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- user_badges — grants, written only by the economy functions
-- ----------------------------------------------------------------------------
create table public.user_badges (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users (id) on delete cascade,
  badge_id         uuid not null references public.badges (id),
  granted_at       timestamptz not null default now(),
  source_ledger_id bigint,
  unique (user_id, badge_id)
);

-- ----------------------------------------------------------------------------
-- streaks — one row per user, maintained server-side
-- ----------------------------------------------------------------------------
create table public.streaks (
  user_id                uuid primary key references auth.users (id) on delete cascade,
  current_len            integer not null default 0,
  longest_len            integer not null default 0,
  last_active_local_date date,
  current_multiplier     numeric(4, 2) not null default 1.0,
  updated_at             timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- daily_progress — per-local-day rollups, maintained server-side
-- ----------------------------------------------------------------------------
create table public.daily_progress (
  user_id              uuid not null references auth.users (id) on delete cascade,
  local_date           date not null,
  sessions_completed   integer not null default 0,
  essentials_completed integer not null default 0
                         check (essentials_completed between 0 and 3),
  points_earned        integer not null default 0,
  all_three_done       boolean not null default false,
  primary key (user_id, local_date)
);

-- ----------------------------------------------------------------------------
-- points_ledger — append-only, hash-chained reward ledger
-- ----------------------------------------------------------------------------
create table public.points_ledger (
  id              bigint generated always as identity primary key,
  user_id         uuid not null references auth.users (id) on delete cascade,
  created_at      timestamptz not null default now(),
  entry_type      text not null
                    check (entry_type in (
                      'session_complete', 'task_target_bonus',
                      'daily_complete_bonus', 'streak_multiplier_adjust',
                      'badge_grant', 'adjustment', 'future_redeem')),
  points          integer not null,
  multiplier      numeric(4, 2) not null default 1.0,
  session_id      uuid references public.pomodoro_sessions (id),
  essential_id    uuid references public.daily_essentials (id),
  badge_id        uuid references public.badges (id),
  idempotency_key uuid not null unique,
  prev_hash       text,
  entry_hash      text not null,
  balance_after   bigint not null
);

create index points_ledger_user_created_idx
  on public.points_ledger (user_id, created_at desc);

create index points_ledger_user_id_desc_idx
  on public.points_ledger (user_id, id desc);

-- ----------------------------------------------------------------------------
-- notification_log — outbound notification audit trail
-- ----------------------------------------------------------------------------
create table public.notification_log (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users (id) on delete cascade,
  device_id         uuid references public.devices (id) on delete set null,
  category          text not null
                      check (category in ('timer', 'essentials', 'streak', 'rewards')),
  dedupe_key        text not null unique,
  scheduled_for     timestamptz,
  sent_at           timestamptz,
  status            text not null default 'pending'
                      check (status in ('pending', 'sent', 'failed', 'skipped')),
  provider_response jsonb,
  created_at        timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- economy_config — single-row tunables for the reward economy
-- ----------------------------------------------------------------------------
create table public.economy_config (
  id                 integer primary key default 1 check (id = 1),
  session_points     integer not null default 10,
  task_bonus         integer not null default 25,
  daily_bonus        integer not null default 100,
  streak_step        numeric(4, 2) not null default 0.10,
  streak_cap         numeric(4, 2) not null default 2.0,
  -- No-pause policy: ANY pause voids the reward.
  max_pause_seconds  integer not null default 0,
  updated_at         timestamptz not null default now()
);

insert into public.economy_config (id) values (1)
on conflict (id) do nothing;

-- ============================================================================
-- points_ledger hardening — append-only + hash chain
-- ============================================================================

-- 1) Privilege-level: nobody (not even service_role) may UPDATE or DELETE.
revoke update, delete on public.points_ledger
  from public, anon, authenticated, service_role;

-- 2) Trigger-level: defense in depth — block mutations even from the table
--    owner / superuser sessions.
create or replace function public.points_ledger_block_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'points_ledger is append-only: % is not allowed', tg_op
    using errcode = 'P0001';
end;
$$;

create trigger points_ledger_no_mutation
  before update or delete on public.points_ledger
  for each row
  execute function public.points_ledger_block_mutation();

-- 3) Hash chain + running balance, computed server-side BEFORE INSERT.
--
--    entry_hash = sha256(coalesce(prev.entry_hash, 'genesis')
--                        || user_id || entry_type || points
--                        || coalesce(session_id, '') || idempotency_key
--                        || created_at-as-UTC-ISO-text)
--
--    created_at is rendered with an explicit, timezone-independent format
--    (to_char at UTC) so verification yields identical bytes regardless of
--    the session TimeZone setting. Appends are serialized per user via an
--    advisory xact lock (covers the genesis row, which has no prior row to
--    FOR UPDATE lock) plus a FOR UPDATE on the user's latest entry.
create or replace function public.points_ledger_before_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_prev_hash    text;
  v_prev_balance bigint;
  v_created_txt  text;
begin
  -- Serialize appends per user.
  perform pg_advisory_xact_lock(hashtext('points_ledger'), hashtext(new.user_id::text));

  select pl.entry_hash, pl.balance_after
    into v_prev_hash, v_prev_balance
    from public.points_ledger pl
   where pl.user_id = new.user_id
   order by pl.id desc
   limit 1
   for update;

  new.created_at := coalesce(new.created_at, now());
  v_created_txt  := to_char(new.created_at at time zone 'UTC',
                            'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');

  new.prev_hash := v_prev_hash;
  new.entry_hash := encode(
    sha256(convert_to(
      coalesce(v_prev_hash, 'genesis')
      || new.user_id::text
      || new.entry_type
      || new.points::text
      || coalesce(new.session_id::text, '')
      || new.idempotency_key::text
      || v_created_txt,
      'utf8')),
    'hex');
  new.balance_after := coalesce(v_prev_balance, 0) + new.points;

  return new;
end;
$$;

create trigger points_ledger_hash_chain
  before insert on public.points_ledger
  for each row
  execute function public.points_ledger_before_insert();

-- ============================================================================
-- Row Level Security
-- ============================================================================
alter table public.profiles          enable row level security;
alter table public.devices           enable row level security;
alter table public.daily_essentials  enable row level security;
alter table public.pomodoro_sessions enable row level security;
alter table public.badges            enable row level security;
alter table public.user_badges       enable row level security;
alter table public.streaks           enable row level security;
alter table public.daily_progress    enable row level security;
alter table public.points_ledger     enable row level security;
alter table public.notification_log  enable row level security;
alter table public.economy_config    enable row level security;

-- profiles: read/update own; no client insert (signup trigger creates it).
create policy "profiles_select_own"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id);

create policy "profiles_update_own"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- devices: full CRUD on own rows.
create policy "devices_crud_own"
  on public.devices for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- daily_essentials: full CRUD on own rows (date validity enforced by trigger).
create policy "daily_essentials_select_own"
  on public.daily_essentials for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "daily_essentials_insert_own"
  on public.daily_essentials for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "daily_essentials_update_own"
  on public.daily_essentials for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "daily_essentials_delete_own"
  on public.daily_essentials for delete to authenticated
  using ((select auth.uid()) = user_id);

-- pomodoro_sessions: read own only; all writes go through Edge Functions
-- using the service role (which bypasses RLS).
create policy "pomodoro_sessions_select_own"
  on public.pomodoro_sessions for select to authenticated
  using ((select auth.uid()) = user_id);

-- Server-maintained tables: read own only.
create policy "points_ledger_select_own"
  on public.points_ledger for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "user_badges_select_own"
  on public.user_badges for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "streaks_select_own"
  on public.streaks for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "daily_progress_select_own"
  on public.daily_progress for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "notification_log_select_own"
  on public.notification_log for select to authenticated
  using ((select auth.uid()) = user_id);

-- Catalog/config: readable by any signed-in user.
create policy "badges_select_all"
  on public.badges for select to authenticated
  using (true);

create policy "economy_config_select_all"
  on public.economy_config for select to authenticated
  using (true);
