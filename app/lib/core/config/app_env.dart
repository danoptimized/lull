/// Build-time environment for lull.
enum AppEnv {
  dev,
  staging,
  prod;

  /// Resolved once from `--dart-define=LULL_ENV=dev|staging|prod`.
  /// Defaults to [dev] when unset or unrecognised — M0 has no remote
  /// backends, so dev is always safe.
  static final AppEnv current = switch (const String.fromEnvironment(
    'LULL_ENV',
  )) {
    'staging' => AppEnv.staging,
    'prod' => AppEnv.prod,
    _ => AppEnv.dev,
  };

  bool get isDev => this == dev;
  bool get isProd => this == prod;
}
