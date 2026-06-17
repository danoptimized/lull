-- ============================================================================
-- Lull — 0010_devices_conflict_target
-- The (user_id, device_id) unique index from 0006 was PARTIAL
-- (`where device_id is not null`). PostgREST upserts generate
-- `ON CONFLICT (user_id, device_id)` with no WHERE predicate, and Postgres
-- won't match a partial index without it — so every devices upsert 400'd.
-- Replace it with a plain unique index (device_id is always supplied by the
-- client; null device_ids stay distinct, which is fine).
-- ============================================================================

drop index if exists public.devices_user_device_id_uniq;

create unique index if not exists devices_user_device_id_uniq
  on public.devices (user_id, device_id);
