-- ============================================================================
-- Lull — seed
-- Badge catalog. Idempotent: safe to re-run (ON CONFLICT (code) DO NOTHING).
-- Names and descriptions follow Lull's calm lowercase voice.
-- ============================================================================

insert into public.badges (code, name, description, rarity, icon_ref, criteria)
values
  (
    'first_focus',
    'first light',
    'your first finished focus session. every practice begins somewhere quiet.',
    'common',
    'badges/first_focus',
    '{"type": "valid_session_count", "threshold": 1}'
  ),
  (
    'seven_day_streak',
    'seven mornings',
    'seven days of showing up, one after another. momentum, gathered gently.',
    'uncommon',
    'badges/seven_day_streak',
    '{"type": "streak_len", "threshold": 7}'
  ),
  (
    'perfect_week',
    'a perfect week',
    'all three essentials, every day, for seven days straight. quietly remarkable.',
    'rare',
    'badges/perfect_week',
    '{"type": "consecutive_all_three_days", "threshold": 7}'
  ),
  (
    'hundred_sessions',
    'a hundred quiet hours',
    'one hundred valid focus sessions. a soft and steady devotion.',
    'rare',
    'badges/hundred_sessions',
    '{"type": "valid_session_count", "threshold": 100}'
  )
on conflict (code) do nothing;
