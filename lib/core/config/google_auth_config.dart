class GoogleAuthConfig {
  GoogleAuthConfig._();

  static String? get serverClientId {
    final value = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue:
          '303919331446-5jc784n8k4p6bcri6a0tqf4ofr9ejul0.apps.googleusercontent.com',
    ).trim();
    return value.isEmpty ? null : value;
  }
}
