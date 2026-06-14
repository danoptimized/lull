-- ============================================================================
-- Lull — pgTAP schema tests
-- Run with `supabase test db` (pg_prove). Everything rolls back.
-- ============================================================================
begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(33);

-- ----------------------------------------------------------------------------
-- Fixture: one auth user. The on_auth_user_created trigger should create the
-- matching profile (timezone defaults to UTC, which the essentials-date
-- trigger relies on below).
-- ----------------------------------------------------------------------------
insert into auth.users (id, email)
values ('00000000-0000-0000-0000-000000000001', 'tap-test@lull.app');

-- ----------------------------------------------------------------------------
-- 1–11: tables exist
-- ----------------------------------------------------------------------------
select has_table('public', 'profiles',          'profiles table exists');
select has_table('public', 'devices',           'devices table exists');
select has_table('public', 'daily_essentials',  'daily_essentials table exists');
select has_table('public', 'pomodoro_sessions', 'pomodoro_sessions table exists');
select has_table('public', 'badges',            'badges table exists');
select has_table('public', 'user_badges',       'user_badges table exists');
select has_table('public', 'streaks',           'streaks table exists');
select has_table('public', 'daily_progress',    'daily_progress table exists');
select has_table('public', 'points_ledger',     'points_ledger table exists');
select has_table('public', 'notification_log',  'notification_log table exists');
select has_table('public', 'economy_config',    'economy_config table exists');

-- ----------------------------------------------------------------------------
-- 12–22: RLS is enabled on every table
-- ----------------------------------------------------------------------------
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),          'RLS enabled on profiles');
select ok((select relrowsecurity from pg_class where oid = 'public.devices'::regclass),           'RLS enabled on devices');
select ok((select relrowsecurity from pg_class where oid = 'public.daily_essentials'::regclass),  'RLS enabled on daily_essentials');
select ok((select relrowsecurity from pg_class where oid = 'public.pomodoro_sessions'::regclass), 'RLS enabled on pomodoro_sessions');
select ok((select relrowsecurity from pg_class where oid = 'public.badges'::regclass),            'RLS enabled on badges');
select ok((select relrowsecurity from pg_class where oid = 'public.user_badges'::regclass),       'RLS enabled on user_badges');
select ok((select relrowsecurity from pg_class where oid = 'public.streaks'::regclass),           'RLS enabled on streaks');
select ok((select relrowsecurity from pg_class where oid = 'public.daily_progress'::regclass),    'RLS enabled on daily_progress');
select ok((select relrowsecurity from pg_class where oid = 'public.points_ledger'::regclass),     'RLS enabled on points_ledger');
select ok((select relrowsecurity from pg_class where oid = 'public.notification_log'::regclass),  'RLS enabled on notification_log');
select ok((select relrowsecurity from pg_class where oid = 'public.economy_config'::regclass),    'RLS enabled on economy_config');

-- ----------------------------------------------------------------------------
-- 23: signup trigger auto-created the profile
-- ----------------------------------------------------------------------------
select is(
  (select count(*)::int from public.profiles
    where id = '00000000-0000-0000-0000-000000000001'),
  1,
  'profile auto-created by on_auth_user_created trigger'
);

-- ----------------------------------------------------------------------------
-- 24–26: daily_essentials slot constraint + (user, date, slot) uniqueness
-- (local_date uses UTC-today since the fixture profile timezone is UTC)
-- ----------------------------------------------------------------------------
select throws_ok(
  $$insert into public.daily_essentials (user_id, local_date, slot, title)
    values ('00000000-0000-0000-0000-000000000001',
            (now() at time zone 'UTC')::date, 4, 'an impossible fourth thing')$$,
  '23514',
  null,
  'daily_essentials rejects slot 4'
);

select lives_ok(
  $$insert into public.daily_essentials (user_id, local_date, slot, title)
    values ('00000000-0000-0000-0000-000000000001',
            (now() at time zone 'UTC')::date, 1, 'write the morning pages')$$,
  'daily_essentials accepts slot 1 for today'
);

select throws_ok(
  $$insert into public.daily_essentials (user_id, local_date, slot, title)
    values ('00000000-0000-0000-0000-000000000001',
            (now() at time zone 'UTC')::date, 1, 'a duplicate slot one')$$,
  '23505',
  null,
  'daily_essentials rejects duplicate (user, local_date, slot)'
);

-- ----------------------------------------------------------------------------
-- 27–29: points_ledger is append-only (insert ok; update/delete blocked
-- by trigger even for the table owner)
-- ----------------------------------------------------------------------------
select lives_ok(
  $$insert into public.points_ledger (user_id, entry_type, points, idempotency_key)
    values ('00000000-0000-0000-0000-000000000001', 'adjustment', 5, gen_random_uuid())$$,
  'points_ledger accepts inserts (hash trigger fills entry_hash/balance_after)'
);

select throws_ok(
  $$update public.points_ledger set points = 10
     where user_id = '00000000-0000-0000-0000-000000000001'$$,
  'P0001',
  null,
  'points_ledger rejects UPDATE'
);

select throws_ok(
  $$delete from public.points_ledger
     where user_id = '00000000-0000-0000-0000-000000000001'$$,
  'P0001',
  null,
  'points_ledger rejects DELETE'
);

-- ----------------------------------------------------------------------------
-- 30–31: at most one active focus session per user (partial unique index)
-- ----------------------------------------------------------------------------
select lives_ok(
  $$insert into public.pomodoro_sessions
      (user_id, kind, started_at, planned_seconds, idempotency_key)
    values ('00000000-0000-0000-0000-000000000001',
            'focus', now(), 1500, gen_random_uuid())$$,
  'first active focus session inserts fine'
);

select throws_ok(
  $$insert into public.pomodoro_sessions
      (user_id, kind, started_at, planned_seconds, idempotency_key)
    values ('00000000-0000-0000-0000-000000000001',
            'focus', now(), 1500, gen_random_uuid())$$,
  '23505',
  null,
  'second concurrent active focus session is blocked by partial unique index'
);

-- ----------------------------------------------------------------------------
-- 32–33: economy_config is a single row, pinned to id = 1
-- ----------------------------------------------------------------------------
select is(
  (select count(*)::int from public.economy_config),
  1,
  'economy_config holds exactly one row'
);

select throws_ok(
  $$insert into public.economy_config (id) values (2)$$,
  '23514',
  null,
  'economy_config rejects any row with id <> 1'
);

select * from finish();

rollback;
