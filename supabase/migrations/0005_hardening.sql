-- ============================================================================
-- Lull — 0005_hardening
-- Ledger integrity monitoring (scheduled chain verification + alerts), and the
-- inert seams for future phases (partner reward fulfillment, subscriptions).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Ledger chain alerts — a row per user whose hash chain failed verification.
-- Server/ops-only; no client policies.
-- ----------------------------------------------------------------------------
create table public.ledger_chain_alerts (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  detected_at timestamptz not null default now()
);

alter table public.ledger_chain_alerts enable row level security;

-- ----------------------------------------------------------------------------
-- verify_all_ledger_chains() — re-derive every user's hash chain + balance and
-- record any failure. Returns the number of failures. Run by pg_cron; callable
-- only by the service role.
-- ----------------------------------------------------------------------------
create or replace function public.verify_all_ledger_chains()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  r          record;
  v_failures integer := 0;
begin
  for r in select distinct user_id from public.points_ledger loop
    if not public.verify_ledger_chain(r.user_id) then
      insert into public.ledger_chain_alerts (user_id) values (r.user_id);
      v_failures := v_failures + 1;
    end if;
  end loop;
  return v_failures;
end;
$$;

revoke execute on function public.verify_all_ledger_chains() from public, anon, authenticated;
grant execute on function public.verify_all_ledger_chains() to service_role;

-- ----------------------------------------------------------------------------
-- Schedule a daily verification (04:00 UTC). Best-effort: if pg_cron isn't
-- available in this environment the migration still succeeds.
-- ----------------------------------------------------------------------------
do $$
begin
  create extension if not exists pg_cron;
  perform cron.unschedule('lull-verify-ledger')
    where exists (select 1 from cron.job where jobname = 'lull-verify-ledger');
  perform cron.schedule(
    'lull-verify-ledger',
    '0 4 * * *',
    'select public.verify_all_ledger_chains();'
  );
exception
  when others then
    raise notice 'pg_cron unavailable; ledger verifier not scheduled (%).', sqlerrm;
end;
$$;

-- ----------------------------------------------------------------------------
-- Inert future seams (no behavior yet) — present so later phases drop in
-- without a migration that touches live tables.
-- ----------------------------------------------------------------------------

-- Subscriptions (RevenueCat later). Free until then.
alter table public.profiles
  add column if not exists subscription_status text not null default 'free'
    check (subscription_status in ('free', 'premium'));

-- Real third-party reward fulfillment: points spent → a partner grant. The
-- append-only ledger already has the `future_redeem` entry type for the debit.
create table public.partner_redemptions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  points_spent integer not null check (points_spent > 0),
  partner      text not null,
  external_ref text,
  status       text not null default 'pending'
                 check (status in ('pending', 'fulfilled', 'failed')),
  created_at   timestamptz not null default now()
);

alter table public.partner_redemptions enable row level security;

create policy "partner_redemptions_select_own"
  on public.partner_redemptions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);
-- Inserts/updates happen server-side (service role) during fulfillment.
