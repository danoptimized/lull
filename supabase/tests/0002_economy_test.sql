-- pgTAP: award_for_session — the server-authoritative economy core.
-- Exercises a clean valid focus linked to a target-1 essential: the ledger
-- (session + task bonus), streak, badge, essential progress, hash chain,
-- idempotency, and the ownership guard.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(10);

-- A fresh user (the trigger creates their profile).
insert into auth.users (id, email, raw_user_meta_data)
values (
  '11111111-1111-1111-1111-111111111111',
  'econ@lull.test',
  '{}'::jsonb
);

-- One essential today, target 1 pomodoro.
insert into public.daily_essentials
  (id, user_id, local_date, slot, title, target_pomodoros)
values (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  public.user_local_date('11111111-1111-1111-1111-111111111111'),
  1, 'draft', 1
);

-- A finished, valid, completed focus linked to that essential.
insert into public.pomodoro_sessions
  (id, user_id, essential_id, kind, started_at, planned_seconds,
   pause_intervals, total_paused_seconds, ended_at, end_reason,
   is_valid, idempotency_key)
values (
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  'focus', now() - interval '310 seconds', 300,
  '[]'::jsonb, 0, now(), 'completed', true, gen_random_uuid()
);

select public.award_for_session(
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111'
);

select is(
  (select balance_after from public.points_ledger
     where user_id = '11111111-1111-1111-1111-111111111111'
     order by id desc limit 1)::int,
  35,
  'balance is 35 (10 session + 25 task target)'
);

select ok(
  exists(select 1 from public.points_ledger
         where user_id = '11111111-1111-1111-1111-111111111111'
           and entry_type = 'session_complete'),
  'a session_complete entry was minted'
);

select ok(
  exists(select 1 from public.points_ledger
         where user_id = '11111111-1111-1111-1111-111111111111'
           and entry_type = 'task_target_bonus'),
  'a task_target_bonus entry was minted'
);

select is(
  (select current_len from public.streaks
     where user_id = '11111111-1111-1111-1111-111111111111')::int,
  1,
  'streak rolled forward to 1'
);

select ok(
  exists(select 1 from public.user_badges ub
         join public.badges b on b.id = ub.badge_id
         where ub.user_id = '11111111-1111-1111-1111-111111111111'
           and b.code = 'first_focus'),
  'first_focus badge granted'
);

select ok(
  (select completed_at is not null from public.daily_essentials
     where id = '22222222-2222-2222-2222-222222222222'),
  'linked essential marked complete'
);

select is(
  (select completed_pomodoros from public.daily_essentials
     where id = '22222222-2222-2222-2222-222222222222')::int,
  1,
  'linked essential advanced to 1/1'
);

select ok(
  public.verify_ledger_chain('11111111-1111-1111-1111-111111111111'),
  'the hash chain verifies'
);

-- Idempotency: a second award for the same session mints nothing new.
create temp table _before as
  select count(*)::int as c from public.points_ledger
   where user_id = '11111111-1111-1111-1111-111111111111';
select public.award_for_session(
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111'
);
select is(
  (select count(*)::int from public.points_ledger
     where user_id = '11111111-1111-1111-1111-111111111111'),
  (select c from _before),
  'a second award mints no new ledger rows (idempotent)'
);

-- Ownership guard (H1): crediting another user's session must raise.
select throws_ok(
  $$ select public.award_for_session(
       '33333333-3333-3333-3333-333333333333',
       '99999999-9999-9999-9999-999999999999') $$,
  null::text,
  null::text,
  'award_for_session refuses a session that is not the callers'
);

select * from finish();
rollback;
