-- ============================================================================
-- Lull — 0004_notifications
-- In-app notifications: events are logged and broadcast to the user's
-- `notify:<uid>` channel so an open app shows them immediately. Out-of-app
-- delivery (FCM/APNs via the push-fanout function) layers on top once push
-- credentials are configured.
-- ============================================================================

-- Log a notification and broadcast it to the user's notify channel.
create or replace function public.notify_user(
  p_user_id uuid,
  p_category text,
  p_title text,
  p_body text
)
returns void
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
begin
  insert into public.notification_log (user_id, category, dedupe_key, status, sent_at)
  values (
    p_user_id,
    p_category,
    p_category || ':' || gen_random_uuid()::text,
    'sent',
    now()
  );

  perform realtime.send(
    jsonb_build_object(
      'category', p_category,
      'title', p_title,
      'body', p_body,
      'created_at', now()
    ),
    'notification',
    'notify:' || p_user_id::text,
    true
  );
end;
$$;

-- Badge earned → a "rewards" notification.
create or replace function public.notify_badge_earned()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_name text;
begin
  select name into v_name from public.badges where id = new.badge_id;
  perform public.notify_user(
    new.user_id, 'rewards', 'badge earned', coalesce(v_name, 'a new badge')
  );
  return null;
end;
$$;

create trigger user_badges_notify
  after insert on public.user_badges
  for each row
  execute function public.notify_badge_earned();

-- Finishing all three essentials in a day → a "rewards" notification.
create or replace function public.notify_economy()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.entry_type = 'daily_complete_bonus' then
    perform public.notify_user(
      new.user_id,
      'rewards',
      'all three, done',
      'you finished today’s essentials'
    );
  end if;
  return null;
end;
$$;

create trigger points_ledger_notify
  after insert on public.points_ledger
  for each row
  execute function public.notify_economy();
