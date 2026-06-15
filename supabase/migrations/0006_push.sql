-- ============================================================================
-- Lull — 0006_push
-- Out-of-app push (FCM) support, layered on the M6-part-1 in-app notifications.
--   1. notification_log carries the title/body so a Database Webhook on insert
--      can hand them straight to the push-fanout function.
--   2. devices gets a stable client `device_id` (the app's persistent install id)
--      so a device updates one row as its FCM token rotates — no orphan rows.
-- ============================================================================

-- 1) Title/body on the log row -----------------------------------------------
alter table public.notification_log
  add column if not exists title text,
  add column if not exists body  text;

-- notify_user now records title/body too (the realtime payload for the in-app
-- center is unchanged). A webhook on notification_log fans these out to push.
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
  insert into public.notification_log
    (user_id, category, dedupe_key, status, sent_at, title, body)
  values (
    p_user_id,
    p_category,
    p_category || ':' || gen_random_uuid()::text,
    'sent',
    now(),
    p_title,
    p_body
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

-- 2) Stable per-install device identity --------------------------------------
alter table public.devices
  add column if not exists device_id text;

-- A device keeps a single row per user, keyed by its persistent install id.
create unique index if not exists devices_user_device_id_uniq
  on public.devices (user_id, device_id)
  where device_id is not null;
