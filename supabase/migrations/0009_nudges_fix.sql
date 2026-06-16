-- ============================================================================
-- Lull — 0009_nudges_fix
-- The essentials reminder must only fire for users who set essentials today and
-- haven't finished them. The first cut used `count(completed) < 3`, which also
-- nudged users with zero essentials or fewer than three — the opposite of calm.
-- Compare completed against the actual number defined for the day instead.
-- ============================================================================

create or replace function public.run_nudges()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  r       record;
  v_total integer;
  v_done  integer;
begin
  -- Essentials reminder ~09:00 local: some essentials set today, not all done.
  for r in
    select p.id as user_id, p.timezone
    from public.profiles p
    where extract(hour from (now() at time zone p.timezone)) = 9
  loop
    select count(*), count(d.completed_at)
      into v_total, v_done
      from public.daily_essentials d
      where d.user_id = r.user_id
        and d.local_date = public.user_local_date(r.user_id);

    if v_total > 0
       and v_done < v_total
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
        'your essentials are waiting',
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
