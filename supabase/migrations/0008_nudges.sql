-- ============================================================================
-- Lull — 0008_nudges
-- Scheduled, local-time notifications: a gentle essentials reminder in the
-- morning and a streak-at-risk nudge in the evening. pg_cron runs hourly; the
-- function picks users for whom it's the right local hour and who still need
-- the nudge. Each call goes through notify_user, so it shows in the in-app
-- center AND fans out to push (per-device category toggles still apply).
-- Dedupe: at most one of each per user per local day.
-- ============================================================================

create or replace function public.run_nudges()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  r record;
begin
  -- Essentials reminder ~09:00 local: today's three aren't all done yet.
  for r in
    select p.id as user_id, p.timezone
    from public.profiles p
    where extract(hour from (now() at time zone p.timezone)) = 9
  loop
    if (
          select count(*)
          from public.daily_essentials d
          where d.user_id = r.user_id
            and d.local_date = public.user_local_date(r.user_id)
            and d.completed_at is not null
        ) < 3
       and not exists (
          select 1
          from public.notification_log n
          where n.user_id = r.user_id
            and n.category = 'essentials'
            and (n.sent_at at time zone r.timezone)::date
                = public.user_local_date(r.user_id)
        )
    then
      perform public.notify_user(
        r.user_id,
        'essentials',
        'your three are waiting',
        'a calm minute to move one forward'
      );
    end if;
  end loop;

  -- Streak at risk ~20:00 local: an active streak with no valid focus today.
  for r in
    select p.id as user_id, p.timezone, s.current_len
    from public.profiles p
    join public.streaks s on s.user_id = p.id
    where s.current_len > 0
      and extract(hour from (now() at time zone p.timezone)) = 20
  loop
    if not exists (
          select 1
          from public.pomodoro_sessions ps
          where ps.user_id = r.user_id
            and ps.is_valid is true
            and (ps.started_at at time zone r.timezone)::date
                = public.user_local_date(r.user_id)
        )
       and not exists (
          select 1
          from public.notification_log n
          where n.user_id = r.user_id
            and n.category = 'streak'
            and (n.sent_at at time zone r.timezone)::date
                = public.user_local_date(r.user_id)
        )
    then
      perform public.notify_user(
        r.user_id,
        'streak',
        'keep your streak alive',
        format('day %s — one focus keeps it going', r.current_len)
      );
    end if;
  end loop;
end;
$$;

revoke execute on function public.run_nudges() from public, anon, authenticated;
grant execute on function public.run_nudges() to service_role;

-- Run hourly; the function self-selects the right local hour per user.
-- Best-effort schedule (no-op if pg_cron isn't available in this environment).
do $$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule('lull-nudges')
    where exists (select 1 from cron.job where jobname = 'lull-nudges');
  perform cron.schedule('lull-nudges', '0 * * * *', 'select public.run_nudges();');
exception
  when others then
    raise notice 'pg_cron unavailable; nudges not scheduled (%).', sqlerrm;
end;
$$;
