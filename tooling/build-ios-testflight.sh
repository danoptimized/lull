#!/usr/bin/env bash
# Build a release IPA for TestFlight (prod Supabase backend).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/app"

flutter pub get
flutter build ipa --dart-define-from-file=env/prod.json
echo "IPA: $ROOT/app/build/ios/ipa/lull.ipa"
