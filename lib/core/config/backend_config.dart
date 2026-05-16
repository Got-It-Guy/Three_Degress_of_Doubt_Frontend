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

  static String roundsPathByStageId(int stageId) {
    return '/api/v1/stages/$stageId/rounds';
  }

  static String enterPathByStageId(int stageId) {
    return '/api/v1/stages/$stageId/enter';
  }

  static String messagesPathByRoundId(String roundId) {
    return '/api/v1/rounds/$roundId/messages';
  }

  static String judgePathByRoundId(String roundId) {
    return '/api/v1/rounds/$roundId/judge';
  }

  static String reportPathByRoundId(String roundId) {
    return '/api/v1/rounds/$roundId/report';
  }

  static Duration? get connectTimeout {
    return _readOptionalDuration('BACKEND_CONNECT_TIMEOUT_SEC');
  }

  static Duration? get sendTimeout {
    return _readOptionalDuration('BACKEND_SEND_TIMEOUT_SEC');
  }

  static Duration? get receiveTimeout {
    return _readOptionalDuration('BACKEND_RECEIVE_TIMEOUT_SEC');
  }

  static Duration? _readOptionalDuration(String key) {
    final value = String.fromEnvironment(key, defaultValue: '');
    if (value.trim().isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return Duration(seconds: parsed);
  }

  static String _defaultBaseUrl() {
    return 'https://fraudprevention.onrender.com';
  }
}
