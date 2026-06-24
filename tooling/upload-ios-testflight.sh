#!/usr/bin/env bash
# Upload a signed App Store IPA to TestFlight.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app"

IPA="${1:-}"
if [[ -z "$IPA" ]]; then
  IPA="$(find build/ios/ipa -name '*.ipa' -print -quit 2>/dev/null || true)"
fi
if [[ -z "$IPA" || ! -f "$IPA" ]]; then
  echo "No IPA found. Run: flutter build ipa --dart-define-from-file=env/prod.json" >&2
  exit 1
fi

: "${ASC_API_KEY_ID:?Set ASC_API_KEY_ID}"
: "${ASC_API_ISSUER_ID:?Set ASC_API_ISSUER_ID}"

echo "Uploading $IPA to App Store Connect…"
xcrun altool --upload-app \
  --type ios \
  --file "$IPA" \
  --apiKey "$ASC_API_KEY_ID" \
  --apiIssuer "$ASC_API_ISSUER_ID"
