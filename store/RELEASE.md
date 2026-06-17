# Lull — release runbook

What's done in code vs. what you (the owner) do to ship. Apple Sign in with
Apple is deferred, so **iOS ships email-only** (the Google button is hidden on
iOS for App Store guideline 4.8); Android + web keep Google.

## ✅ Done in code (this repo)
- App id `works.lull`, display name "Lull", version `1.0.0+1`.
- Android: INTERNET + POST_NOTIFICATIONS permissions; release `signingConfig`
  from `android/key.properties` (debug fallback); `flutter build appbundle
  --release` verified.
- iOS: deep-link scheme for Google OAuth; `flutter build ios --no-codesign
  --release` verified.
- Calm splash screen (no asset). Launcher-icon config wired (needs your art).
- Account deletion in-app (Apple requirement). Google sign-in (Android/web).
- Backend live on prod Supabase `datsobemreodeoerkplr` (session-validate,
  push-fanout, delete-account deployed; migrations pushed).
- Store assets: `listing.md`, `privacy-policy.md`, `terms.md`, `support.md`,
  `data-safety.md`, and 8 screenshots in `store/screenshots/`.

## 1. App icon (both platforms)
Drop a square ≥1024px PNG at `app/assets/icon/lull_icon.png`, then:
```sh
cd app && dart run flutter_launcher_icons
```

## 2. Host the legal pages
Publish `privacy-policy.md`, `terms.md`, `support.md` at public URLs
(e.g. https://lull.works/privacy, /terms, /support). The privacy + support URLs
are required by both stores. (I can also add them as routes in the web app.)

## 3. Android → Google Play
1. **Generate an upload keystore** (keep it + the passwords safe forever):
   ```sh
   keytool -genkey -v -keystore ~/lull-upload.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias upload
   ```
2. Create **`app/android/key.properties`** (gitignored):
   ```
   storePassword=<your store password>
   keyPassword=<your key password>
   keyAlias=upload
   storeFile=/Users/<you>/lull-upload.jks
   ```
3. Build the bundle:
   ```sh
   cd app && flutter build appbundle --release
   # → build/app/outputs/bundle/release/app-release.aab
   ```
4. **Play Console**: create the app (package `works.lull`) → use **Play App
   Signing** → upload the `.aab` to **Internal testing** first. Fill: store
   listing (`listing.md`), screenshots (`store/screenshots/*_iphone67.png` work
   as phone shots, or regenerate an Android size), **Data safety**
   (`data-safety.md`), content rating, privacy URL. Roll out internal → closed →
   production.

## 4. iOS → App Store
1. Open **`app/ios/Runner.xcworkspace`** in Xcode → Runner target → **Signing &
   Capabilities** → select your team (**Team ID 4755696MLY**), automatic signing.
   *(Optional now: add the Push Notifications capability + Background Modes →
   Remote notifications to enable iOS push; without it the app still runs, just
   no push on iOS.)*
2. Set the version/build (already `1.0.0` / `1`).
3. Archive + upload:
   ```sh
   cd app && flutter build ipa
   # then upload build/ios/archive/*.xcarchive via Xcode Organizer or:
   # xcrun altool / Transporter, using an App Store Connect API key
   ```
4. **App Store Connect**: create the app (bundle `works.lull`) → TestFlight →
   screenshots (`store/screenshots/*_iphone67.png` for 6.7", `*_ipad13.png` for
   iPad 12.9"), metadata (`listing.md`), **App Privacy** (`data-safety.md`), age
   rating, privacy URL. Submit for review.

## 5. Web (optional, when you deploy)
- Build: `flutter build web --wasm` (Cloudflare Pages / Netlify read
  `app/web/_headers` for the COOP/COEP it needs).
- Add the deployed origin to Supabase → Auth → URL Configuration → Redirect URLs
  so Google sign-in returns there.

## Regenerate store screenshots
```sh
cd app && flutter test --update-goldens --run-skipped -t store test/store
```

## Not yet (post-launch)
- Sign in with Apple (re-enables Google on iOS).
- Web offline cache (ship sqlite3.wasm + drift_worker.js to web/).
- Android R8/minify (enable + test on a device to shrink the build).
- A CI release pipeline (the current CI does smoke builds only).
