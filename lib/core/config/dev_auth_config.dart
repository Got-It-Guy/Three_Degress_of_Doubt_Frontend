class DevAuthConfig {
  DevAuthConfig._();

  static const bool enabled = bool.fromEnvironment(
    'DEV_AUTH_ENABLED',
    defaultValue: false,
  );
}
