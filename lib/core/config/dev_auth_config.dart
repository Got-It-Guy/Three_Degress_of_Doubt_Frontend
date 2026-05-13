class DevAuthConfig {
  DevAuthConfig._();

  static const bool enabled = bool.fromEnvironment(
    'DEV_AUTH_ENABLED',
    defaultValue: false,
  );

  static const String bearerToken = String.fromEnvironment(
    'DEV_AUTH_BEARER_TOKEN',
    defaultValue: 'dev-user-001',
  );

  static String resolveBearerToken(String? firebaseIdToken) {
    if (enabled) {
      return bearerToken;
    }
    final token = firebaseIdToken?.trim() ?? '';
    if (token.isEmpty) {
      throw StateError('Firebase ID token is missing.');
    }
    return token;
  }
}
