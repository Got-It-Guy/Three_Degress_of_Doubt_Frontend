import 'package:three_degress_of_doubt_frontend/core/config/dev_auth_config.dart';

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
    if (DevAuthConfig.enabled) {
      return 'http://10.0.2.2:8000';
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
    if (DevAuthConfig.enabled) {
      return const String.fromEnvironment(
        'BACKEND_PROFILE_PATH',
        defaultValue: '/api/users/me/details',
      );
    }
    return const String.fromEnvironment(
      'BACKEND_PROFILE_PATH',
      defaultValue: '/api/users/me',
    );
  }

  static String get stagesPath {
    return const String.fromEnvironment(
      'BACKEND_STAGES_PATH',
      defaultValue: '/api/v1/stages',
    );
  }

  static String roundsPathByStageId(int stageId) {
    return '/api/v1/stages/$stageId/rounds';
  }

  static String messagesPathByRoundId(int roundId) {
    return '/api/v1/rounds/$roundId/messages';
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
