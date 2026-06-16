#!/usr/bin/env bash
# Exercises the session-validate Edge Function end-to-end against the local
# stack: auth, lifecycle, idempotency, single-active, the no-pause rule, the
# valid-completion path, and that clients can't write pomodoro_sessions directly.
set -uo pipefail

API="http://127.0.0.1:55321"
KEY="sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
FN="$API/functions/v1/session-validate"
EMAIL="tester@lull.app"
PASS="test-password-123"
PSQL=(docker exec supabase_db_lull psql -U postgres -d postgres -tAc)

j() { python3 -c "import sys,json; d=json.load(sys.stdin); print(d$1)" 2>/dev/null; }
pass() { echo "PASS — $1"; }
fail() { echo "FAIL — $1"; FAILED=1; }
FAILED=0

# --- auth: sign up (auto-confirmed locally) or fall back to password login ---
TOKEN=$(curl -s -X POST "$API/auth/v1/signup" -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" | j "['access_token']")
if [ -z "$TOKEN" ] || [ "$TOKEN" = "None" ]; then
  TOKEN=$(curl -s -X POST "$API/auth/v1/token?grant_type=password" -H "apikey: $KEY" -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" | j "['access_token']")
fi
[ -n "$TOKEN" ] && [ "$TOKEN" != "None" ] && pass "got user access token" || { fail "no access token"; exit 1; }
UID_=$("${PSQL[@]}" "select id from auth.users where email='$EMAIL';" | tr -d '[:space:]')

call() { # action json -> response
  curl -s -X POST "$FN" -H "apikey: $KEY" -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" -d "$1"
}

K1=$(uuidgen); K2=$(uuidgen); K3=$(uuidgen)

# --- start ---
R=$(call "{\"action\":\"start\",\"plannedSeconds\":1500,\"idempotencyKey\":\"$K1\"}")
SID=$(echo "$R" | j "['session']['id']")
[ -n "$SID" ] && [ "$SID" != "None" ] && pass "start created a session ($SID)" || fail "start: $R"
[ "$(echo "$R" | j "['session']['is_valid']")" = "None" ] && pass "new session is_valid is null" || fail "is_valid not null"

# --- input validation guards (reject before any DB hit, no leaked detail) ---
R=$(call "{\"action\":\"start\",\"plannedSeconds\":10,\"idempotencyKey\":\"$(uuidgen)\"}")
[ "$(echo "$R" | j "['error']")" = "invalid_planned_seconds" ] && pass "rejects out-of-range plannedSeconds (400)" || fail "planned validation: $R"
R=$(call "{\"action\":\"start\",\"plannedSeconds\":1500,\"kind\":\"bogus\",\"idempotencyKey\":\"$(uuidgen)\"}")
[ "$(echo "$R" | j "['error']")" = "invalid_kind" ] && pass "rejects unknown kind (400)" || fail "kind validation: $R"
R=$(call "{\"action\":\"finalize\",\"sessionId\":\"not-a-uuid\"}")
[ "$(echo "$R" | j "['error']")" = "invalid_session_id" ] && pass "rejects malformed sessionId (400)" || fail "uuid validation: $R"

# --- idempotent start (same key) ---
R=$(call "{\"action\":\"start\",\"plannedSeconds\":1500,\"idempotencyKey\":\"$K1\"}")
[ "$(echo "$R" | j "['replayed']")" = "True" ] && [ "$(echo "$R" | j "['session']['id']")" = "$SID" ] \
  && pass "same key replays same session" || fail "idempotency: $R"

# --- single active focus (different key) -> adopt existing ---
R=$(call "{\"action\":\"start\",\"plannedSeconds\":1500,\"idempotencyKey\":\"$K2\"}")
[ "$(echo "$R" | j "['adopted']")" = "True" ] && [ "$(echo "$R" | j "['session']['id']")" = "$SID" ] \
  && pass "second focus adopts the active one (single-active)" || fail "single-active: $R"

# --- pause / resume ---
R=$(call "{\"action\":\"pause\",\"sessionId\":\"$SID\"}")
[ "$(echo "$R" | j "['session']['pause_intervals'][0]['end']")" = "None" ] \
  && pass "pause opened an interval" || fail "pause: $R"
R=$(call "{\"action\":\"resume\",\"sessionId\":\"$SID\"}")
[ "$(echo "$R" | j "['session']['pause_intervals'][0]['end']")" != "None" ] \
  && pass "resume closed the interval" || fail "resume: $R"

# --- finalize (paused + short => aborted, not valid) ---
R=$(call "{\"action\":\"finalize\",\"sessionId\":\"$SID\",\"idempotencyKey\":\"$K1\"}")
[ "$(echo "$R" | j "['isValid']")" = "False" ] && pass "paused/short session is not valid (no-pause rule)" || fail "finalize void: $R"
[ "$(echo "$R" | j "['session']['end_reason']")" = "aborted" ] && pass "short finish marked aborted" || fail "end_reason: $R"

# --- single-active released after finalize: a new focus starts fresh ---
R=$(call "{\"action\":\"start\",\"plannedSeconds\":1500,\"idempotencyKey\":\"$K3\"}")
[ "$(echo "$R" | j "['adopted']")" != "True" ] && [ "$(echo "$R" | j "['session']['id']")" != "$SID" ] \
  && pass "active slot freed after finalize" || fail "post-finalize start: $R"
NEWSID=$(echo "$R" | j "['session']['id']")
call "{\"action\":\"finalize\",\"sessionId\":\"$NEWSID\",\"idempotencyKey\":\"$K3\"}" >/dev/null

# --- valid completion path: backdate a clean session, then finalize ---
# planned 300s (the creditable floor) ran in full, no pauses → valid.
VK=$(uuidgen)
"${PSQL[@]}" "insert into pomodoro_sessions (user_id, kind, started_at, planned_seconds, pause_intervals, idempotency_key) values ('$UID_','focus', now() - interval '310 seconds', 300, '[]', '$VK');" >/dev/null
VSID=$("${PSQL[@]}" "select id from pomodoro_sessions where idempotency_key='$VK';" | tr -d '[:space:]')
R=$(call "{\"action\":\"finalize\",\"sessionId\":\"$VSID\",\"idempotencyKey\":\"$VK\"}")
[ "$(echo "$R" | j "['isValid']")" = "True" ] && pass "clean full focus is valid" || fail "valid path: $R"
[ "$(echo "$R" | j "['session']['end_reason']")" = "completed" ] && pass "full focus marked completed" || fail "completed: $R"

# --- creditable floor: a fully-run but sub-floor session completes, not credits ---
FK=$(uuidgen)
"${PSQL[@]}" "insert into pomodoro_sessions (user_id, kind, started_at, planned_seconds, pause_intervals, idempotency_key) values ('$UID_','focus', now() - interval '70 seconds', 60, '[]', '$FK');" >/dev/null
FSID=$("${PSQL[@]}" "select id from pomodoro_sessions where idempotency_key='$FK';" | tr -d '[:space:]')
R=$(call "{\"action\":\"finalize\",\"sessionId\":\"$FSID\",\"idempotencyKey\":\"$FK\"}")
[ "$(echo "$R" | j "['isValid']")" = "False" ] && pass "sub-floor session is not creditable (H3)" || fail "floor not enforced: $R"
[ "$(echo "$R" | j "['session']['end_reason']")" = "completed" ] && pass "sub-floor session still marked completed" || fail "sub-floor end_reason: $R"

# --- RLS: a client cannot write pomodoro_sessions directly ---
DIRECT=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API/rest/v1/pomodoro_sessions" \
  -H "apikey: $KEY" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$UID_\",\"kind\":\"focus\",\"started_at\":\"$(date -u +%FT%TZ)\",\"planned_seconds\":1500,\"idempotency_key\":\"$(uuidgen)\"}")
[ "$DIRECT" = "401" ] || [ "$DIRECT" = "403" ] && pass "direct client insert blocked by RLS ($DIRECT)" || fail "RLS hole: client insert returned $DIRECT"

echo "---"
[ "$FAILED" = "0" ] && echo "ALL PASSED" || echo "SOME FAILED"
