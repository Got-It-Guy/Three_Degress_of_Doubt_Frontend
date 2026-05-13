class BackendConfig {
  BackendConfig._();

  static String get baseUrl {
    final envBaseUrl = const String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: '',
    );
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    return _defaultBaseUrl();
  }

  static String get authPath {
    return const String.fromEnvironment(
      'BACKEND_AUTH_PATH',
      defaultValue: '/api/users/sync',
    );
  }

  static String get profilePath {
    return const String.fromEnvironment(
      'BACKEND_PROFILE_PATH',
      defaultValue: '/api/users/me',
    );
  }

  static String get userMetadataPath {
  return const String.fromEnvironment(
    'BACKEND_METADATA_PATH',
    defaultValue: '/api/users/me/details',
  );
}

  static String get stagesPath {
    return const String.fromEnvironment(
      'BACKEND_STAGES_PATH',
      defaultValue: '/api/v1/stages',
    );
  }

  static Duration get connectTimeout {
    return Duration(seconds: _readInt('BACKEND_CONNECT_TIMEOUT_SEC', 10));
  }

  static Duration get sendTimeout {
    return Duration(seconds: _readInt('BACKEND_SEND_TIMEOUT_SEC', 15));
  }

  static Duration get receiveTimeout {
    return Duration(seconds: _readInt('BACKEND_RECEIVE_TIMEOUT_SEC', 15));
  }

  static int _readInt(String key, int fallback) {
    final value = String.fromEnvironment(key, defaultValue: '');
    final parsed = int.tryParse(value);
    return (parsed != null && parsed > 0) ? parsed : fallback;
  }

  static String _defaultBaseUrl() {
    return 'https://fraudprevention.onrender.com';
  }
}
