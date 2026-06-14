#!/usr/bin/env bash
# Verifies the reward economy end to end against the local stack: a valid focus
# session, on finalize, mints a hash-chained ledger entry, rolls the streak,
# advances the linked essential, awards the task bonus, records daily progress,
# grants the first-focus badge, and keeps the ledger chain verifiable — all
# idempotently.
set -uo pipefail

API="http://127.0.0.1:55321"
KEY="sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
FN="$API/functions/v1/session-validate"
EMAIL="econ-$(uuidgen | tr 'A-Z' 'a-z' | cut -c1-8)@lull.app"
PASSWD="test-password-123"
PSQL=(docker exec supabase_db_lull psql -U postgres -d postgres -tAc)
TODAY=$(date -u +%F)

j() { python3 -c "import sys,json; d=json.load(sys.stdin); print(d$1)" 2>/dev/null; }
q() { "${PSQL[@]}" "$1" | tr -d '[:space:]'; }
pass() { echo "PASS — $1"; }
fail() { echo "FAIL — $1"; FAILED=1; }
FAILED=0

# --- fresh user ---
TOKEN=$(curl -s -X POST "$API/auth/v1/signup" -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWD\"}" | j "['access_token']")
[ -n "$TOKEN" ] && [ "$TOKEN" != "None" ] && pass "fresh user signed up" || { fail "signup"; exit 1; }
UID_=$(q "select id from auth.users where email='$EMAIL';")

# --- the user creates one essential (target 1 pomodoro) via REST (RLS-scoped) ---
EID=$(curl -s -X POST "$API/rest/v1/daily_essentials?select=id" -H "apikey: $KEY" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d "{\"user_id\":\"$UID_\",\"local_date\":\"$TODAY\",\"slot\":1,\"title\":\"finish the draft\",\"target_pomodoros\":1}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])" 2>/dev/null)
[ -n "$EID" ] && pass "essential created ($EID)" || fail "essential create"

# --- backdate a clean, completed focus session linked to that essential ---
VK=$(uuidgen)
"${PSQL[@]}" "insert into pomodoro_sessions (user_id, essential_id, kind, started_at, planned_seconds, pause_intervals, idempotency_key) values ('$UID_','$EID','focus', now() - interval '70 seconds', 60, '[]', '$VK');" >/dev/null
SID=$(q "select id from pomodoro_sessions where idempotency_key='$VK';")

# --- finalize via the Edge Function → should credit the economy ---
R=$(curl -s -X POST "$FN" -H "apikey: $KEY" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"action\":\"finalize\",\"sessionId\":\"$SID\",\"idempotencyKey\":\"$VK\"}")
[ "$(echo "$R" | j "['isValid']")" = "True" ] && pass "valid session finalized" || fail "finalize: $R"
AWARDED=$(echo "$R" | j "['award']['points_awarded']")
[ "$AWARDED" = "35" ] && pass "points_awarded = 35 (10 session + 25 task bonus)" || fail "points_awarded=$AWARDED (want 35)"

# --- ledger ---
LEDGER_TYPES=$(q "select string_agg(entry_type, ',' order by id) from points_ledger where user_id='$UID_';")
echo "$LEDGER_TYPES" | grep -q "session_complete" && echo "$LEDGER_TYPES" | grep -q "task_target_bonus" \
  && pass "ledger has session_complete + task_target_bonus ($LEDGER_TYPES)" || fail "ledger types: $LEDGER_TYPES"
BAL=$(q "select balance_after from points_ledger where user_id='$UID_' order by id desc limit 1;")
[ "$BAL" = "35" ] && pass "running balance = 35" || fail "balance=$BAL"

# --- linked essential advanced + completed ---
EP=$(q "select completed_pomodoros from daily_essentials where id='$EID';")
EC=$(q "select (completed_at is not null) from daily_essentials where id='$EID';")
[ "$EP" = "1" ] && [ "$EC" = "t" ] && pass "essential advanced to 1/1 and marked complete" || fail "essential ep=$EP complete=$EC"

# --- streak + daily_progress ---
SLEN=$(q "select current_len from streaks where user_id='$UID_';")
[ "$SLEN" = "1" ] && pass "streak current_len = 1" || fail "streak=$SLEN"
DP=$(q "select sessions_completed||'/'||points_earned from daily_progress where user_id='$UID_' and local_date='$TODAY';")
[ "$DP" = "1/35" ] && pass "daily_progress 1 session / 35 points" || fail "daily_progress=$DP"

# --- badge ---
BADGE=$(q "select b.code from user_badges ub join badges b on b.id=ub.badge_id where ub.user_id='$UID_';")
echo "$BADGE" | grep -q "first_focus" && pass "first_focus badge granted" || fail "badges: $BADGE"

# --- hash chain verifies ---
CHAIN=$(q "select public.verify_ledger_chain('$UID_');")
[ "$CHAIN" = "t" ] && pass "ledger hash chain verifies" || fail "chain verify=$CHAIN"

# --- idempotency: re-finalize must not double-credit ---
curl -s -X POST "$FN" -H "apikey: $KEY" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"action\":\"finalize\",\"sessionId\":\"$SID\",\"idempotencyKey\":\"$VK\"}" >/dev/null
NROWS=$(q "select count(*) from points_ledger where user_id='$UID_';")
BAL2=$(q "select balance_after from points_ledger where user_id='$UID_' order by id desc limit 1;")
[ "$BAL2" = "35" ] && pass "re-finalize did not double-credit (balance still 35, $NROWS rows)" || fail "double-credit: balance=$BAL2"

echo "---"
[ "$FAILED" = "0" ] && echo "ALL PASSED" || echo "SOME FAILED"
