import 'package:dio/dio.dart';
import 'package:three_degress_of_doubt_frontend/core/config/backend_config.dart';

class StageProgress {
  const StageProgress({
    required this.stageId,
    required this.stageScore,
    required this.isCleared,
  });

  final int stageId;
  final int stageScore;
  final bool isCleared;
}

class StageRepository {
  StageRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: BackendConfig.connectTimeout,
              sendTimeout: BackendConfig.sendTimeout,
              receiveTimeout: BackendConfig.receiveTimeout,
            ),
          );

  final Dio _dio;

  Future<Map<int, StageProgress>> fetchStageProgresses({
    required String idToken,
  }) async {
    final endpoint = _joinUrl(BackendConfig.baseUrl, BackendConfig.stagesPath);

    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          responseType: ResponseType.json,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw StateError('Stage fetch failed ($statusCode): ${response.data}');
      }

      final payload = _asMap(response.data);
      if (payload == null) {
        throw StateError('Stage response is not a valid JSON object.');
      }

      final status = payload['status']?.toString();
      if (status != 'success') {
        throw StateError('Stage response status is not success.');
      }

      final rawStages = payload['stages'];
      if (rawStages is! List) {
        throw StateError(
          'Stage response does not contain a valid stages list.',
        );
      }

      final result = <int, StageProgress>{};
      for (final rawItem in rawStages) {
        final item = _asMap(rawItem);
        if (item == null) {
          continue;
        }

        final stageId = _toInt(item['stage_id']);
        if (stageId == null) {
          continue;
        }

        result[stageId] = StageProgress(
          stageId: stageId,
          stageScore: _toInt(item['stage_score']) ?? 0,
          isCleared: _toBool(item['is_cleared']) ?? false,
        );
      }

      return result;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final body = error.response?.data ?? error.message;
      final suffix = statusCode != null ? ' ($statusCode)' : '';
      throw StateError('Stage fetch failed$suffix: $body');
    }
  }

  String _joinUrl(String baseUrl, String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedBase$normalizedPath';
  }
}

Map<String, dynamic>? _asMap(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    return payload;
  }
  if (payload is Map) {
    return payload.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

bool? _toBool(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }
  return null;
}
