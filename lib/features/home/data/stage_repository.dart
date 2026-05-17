import 'package:dio/dio.dart';
import 'package:three_degress_of_doubt_frontend/core/config/backend_config.dart';
import 'package:three_degress_of_doubt_frontend/features/home/domain/models/stage_model.dart';

class StageEnterResult {
  const StageEnterResult({
    required this.stageId,
    required this.stageScore,
    required this.warningCount,
    required this.isCleared,
    required this.totalRoundCount,
    required this.hasIncompleteRound,
  });

  final int stageId;
  final int stageScore;
  final int warningCount;
  final bool isCleared;
  final int totalRoundCount;
  final bool hasIncompleteRound;
}

class StageRepository {
  StageRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<int, StageProgress>> fetchStageProgresses({
    required String idToken,
  }) async {
    final endpoint = _joinUrl(BackendConfig.baseUrl, BackendConfig.stagesPath);
    final response = await _dio.get<dynamic>(
      endpoint,
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ),
    );

    final payload = _asMap(response.data);
    if (payload == null) {
      throw StateError('Stages response is not a valid JSON object.');
    }

    final rawList = payload['stages'];
    if (rawList is! List) {
      return <int, StageProgress>{};
    }

    final result = <int, StageProgress>{};
    for (final item in rawList) {
      final parsedItem = _asMap(item);
      if (parsedItem != null) {
        final progress = StageProgress.fromJson(parsedItem);
        result[progress.stageId] = progress;
      }
    }
    return result;
  }

  Future<StageEnterResult> enterStage({
    required int stageId,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.enterPathByStageId(stageId),
    );
    final response = await _dio.post<dynamic>(
      endpoint,
      data: const <String, dynamic>{},
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ),
    );

    final payload = _asMap(response.data);
    if (payload == null) {
      throw StateError('Stage enter response is not a valid JSON object.');
    }
    final data = _asMap(payload['data']) ?? payload;
    return StageEnterResult(
      stageId: stageId,
      stageScore: _toInt(data['stage_score']) ?? 0,
      warningCount: _toInt(data['warning_count']) ?? 0,
      isCleared: _toBool(data['is_cleared']) ?? false,
      totalRoundCount: _toInt(data['total_round_count']) ?? 0,
      hasIncompleteRound: _toBool(data['has_incomplete_round']) ?? false,
    );
  }
}

String _joinUrl(String baseUrl, String path) {
  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$normalizedBase$normalizedPath';
}

Map<String, dynamic>? _asMap(dynamic payload) {
  if (payload is Map<String, dynamic>) return payload;
  if (payload is Map) return payload.map((k, v) => MapEntry(k.toString(), v));
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}
