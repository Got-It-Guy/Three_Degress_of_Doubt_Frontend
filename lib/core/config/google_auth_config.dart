class GoogleAuthConfig {
  GoogleAuthConfig._();

  static String? get serverClientId {
    final value = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue:
          '303919331446-ghm2ga3nlksho7akhnt6gvibhjt04tq7.apps.googleusercontent.com',
    ).trim();

    return value.isEmpty ? null : value;
  }
}