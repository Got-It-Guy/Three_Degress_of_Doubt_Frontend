class GoogleAuthConfig {
  GoogleAuthConfig._();

  static String? get serverClientId {
    final value = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue:
          '303919331446-t622rvasecqi1or50ct0k91mcrpm2vtk.apps.googleusercontent.com',
    ).trim();
    return value.isEmpty ? null : value;
  }
}
