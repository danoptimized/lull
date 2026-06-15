-- ============================================================================
-- Lull — 0007_push_trigger
-- Fan every notification_log insert out to push, in the database — no dashboard
-- webhook to hand-configure. An AFTER INSERT trigger POSTs the row to the
-- push-fanout Edge Function via pg_net, authenticating with the service-role
-- key read from Vault (so no secret lives in git).
--
-- Owner setup (one time): store the project's service-role key in Vault under
-- the name `service_role_key` (Dashboard → Project Settings → Vault → Add new
-- secret, or `select vault.create_secret('<key>', 'service_role_key');`). Until
-- it's set the trigger is a no-op — in-app realtime notifications still work.
-- ============================================================================

-- pg_net powers the async HTTP call. Best-effort: if it's unavailable in this
-- environment (some local stacks) the migration still succeeds.
do $$
begin
  create extension if not exists pg_net;
exception
  when others then
    raise notice 'pg_net unavailable; push fan-out trigger inert (%).', sqlerrm;
end;
$$;

create or replace function public.fanout_push_on_notification()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_service_key text;
  -- The public push-fanout endpoint for this project (not a secret).
  v_url text :=
    'https://datsobemreodeoerkplr.supabase.co/functions/v1/push-fanout';
begin
  -- Never let push wiring break the insert (or the realtime broadcast that
  -- already fired). Any missing piece — Vault, pg_net, the secret — no-ops.
  begin
    select decrypted_secret
      into v_service_key
      from vault.decrypted_secrets
     where name = 'service_role_key';

    if v_service_key is null then
      return null; -- not configured yet
    end if;

    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_service_key
      ),
      body := to_jsonb(new)
    );
  exception
    when others then
      raise notice 'push fan-out skipped: %', sqlerrm;
  end;
  return null;
end;
$$;

drop trigger if exists notification_log_fanout on public.notification_log;
create trigger notification_log_fanout
  after insert on public.notification_log
  for each row
  execute function public.fanout_push_on_notification();
