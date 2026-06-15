# Build environments

Backend connection is injected at build time (see `lib/data/supabase/supabase_config.dart`).
With no flags, the app points at the **local** Supabase stack — that's the dev default.

For **production** builds, pass this file:

```sh
flutter run   --dart-define-from-file=env/prod.json
flutter build ios     --release --dart-define-from-file=env/prod.json
flutter build appbundle --release --dart-define-from-file=env/prod.json
flutter build macos   --release --dart-define-from-file=env/prod.json
flutter build web     --wasm    --dart-define-from-file=env/prod.json
```

> Android against a **local** stack only: also pass
> `--dart-define=SUPABASE_URL=http://10.0.2.2:55321` (the emulator's host alias).

## Is it safe that these values are committed?

Yes. `SUPABASE_URL` and the **publishable** (anon) key are public by design — they ship
inside every client build, and Row-Level Security is what actually protects data. The
**`service_role`** key is the only Supabase secret; it never appears here or in the client,
only inside Edge Functions (injected automatically by Supabase).
