/// Backend connection, supplied at build time via `--dart-define` in
/// CI/release and defaulting to the local Supabase stack for development.
///
/// The default anon key is the well-known local-dev key the Supabase CLI
/// generates for every machine — it is **not** a secret and never reaches
/// production, where `SUPABASE_URL`/`SUPABASE_ANON_KEY` are injected instead.
///
/// Note: `127.0.0.1` works for macOS, web, and the iOS simulator. The Android
/// emulator reaches the host at `10.0.2.2` — pass that via `--dart-define`
/// when running on Android against a local stack.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:55321',
  );

  /// The publishable (anon-role) key. The default is the local stack's key —
  /// public by design; production injects its own via `--dart-define`.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );
}
