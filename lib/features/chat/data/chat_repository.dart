import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:three_degress_of_doubt_frontend/core/config/backend_config.dart';

class ChatMessageDto {
  const ChatMessageDto({
    required this.messageId,
    required this.roundId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String? messageId;
  final String? roundId;
  final String role;
  final String content;
  final DateTime createdAt;
}

class SendMessageResult {
  const SendMessageResult({
    required this.messages,
    required this.isEvidence,
    required this.isConversationOver,
    this.endedReason,
  });

  final List<ChatMessageDto> messages;
  final bool isEvidence;
  final bool isConversationOver;
  final String? endedReason;
}

class SituationPromptDto {
  const SituationPromptDto({
    required this.situation,
    required this.currentStage,
    required this.userIntent,
  });

  final String situation;
  final String currentStage;
  final String userIntent;
}

class CreateRoundResult {
  const CreateRoundResult({
    required this.roundId,
    this.scenarioId,
    this.situationPrompt,
    this.initialMessage,
  });

  final String roundId;
  final String? scenarioId;
  final SituationPromptDto? situationPrompt;
  final ChatMessageDto? initialMessage;
}

class JudgeRoundResult {
  const JudgeRoundResult({
    required this.result,
    required this.scoreDelta,
    required this.currentScore,
    required this.currentWarning,
    required this.isStageCleared,
    required this.rawBody,
  });

  final String result;
  final int scoreDelta;
  final int currentScore;
  final int currentWarning;
  final bool isStageCleared;
  final Map<String, dynamic> rawBody;
}

class ReportFraudPointDto {
  const ReportFraudPointDto({
    required this.messageId,
    required this.reason,
    required this.tip,
  });

  final String? messageId;
  final String reason;
  final String tip;
}

class RoundReportResult {
  const RoundReportResult({
    required this.reportId,
    required this.roundId,
    required this.reportType,
    required this.summary,
    required this.fraudPoints,
  });

  final String? reportId;
  final String? roundId;
  final String reportType;
  final String summary;
  final List<ReportFraudPointDto> fraudPoints;
}

class RoundReportDto {
  const RoundReportDto({
    required this.reportId,
    required this.roundId,
    required this.reportType,
    required this.summary,
    required this.fraudPoints,
  });

  final String reportId;
  final String roundId;
  final String reportType;
  final String summary;
  final List<Map<String, dynamic>> fraudPoints;
}

class ChatRepository {
  ChatRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<CreateRoundResult> createRound({
    required int stageId,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.roundsPathByStageId(stageId),
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
      throw StateError('Round create response is not a valid JSON object.');
    }
    final data = _asMap(payload['data']);
    if (kDebugMode) {
      final rawJson = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      debugPrint('[RoundStart] raw response = $rawJson');
    }
    final roundId = _extractRoundId(payload, data);
    if (roundId == null) {
      throw StateError('Round create response does not contain round_id.');
    }
    final scenarioId = _toIdString(data?['scenario_id']);
    final situationPrompt = _parseSituationPrompt(data?['situation_prompt']);
    final initialMessage = _parseMessage(data?['initial_message']);
    return CreateRoundResult(
      roundId: roundId,
      scenarioId: scenarioId,
      situationPrompt: situationPrompt,
      initialMessage: initialMessage,
    );
  }

  Future<SendMessageResult> sendMessage({
    required String roundId,
    required String content,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.messagesPathByRoundId(roundId),
    );
    final response = await _dio.post<dynamic>(
      endpoint,
      data: <String, dynamic>{'content': content},
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ),
    );

    final payload = _asMap(response.data);
    if (payload == null) {
      throw StateError('Send message response is not a valid JSON object.');
    }

    final aiMessages = <ChatMessageDto>[];
    for (final key in const ['ai_message', 'assistant_message', 'message']) {
      final raw = payload[key];
      final parsed = _parseMessage(raw);
      if (parsed != null && parsed.role != 'user') {
        aiMessages.add(parsed);
      }
    }

    return SendMessageResult(
      messages: aiMessages,
      isEvidence: payload['is_evidence'] == true,
      isConversationOver: payload['is_conversation_over'] == true,
      endedReason: payload['ended_reason']?.toString(),
    );
  }

  Future<List<ChatMessageDto>> fetchMessages({
    required String roundId,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.messagesPathByRoundId(roundId),
    );
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
      throw StateError('Messages response is not a valid JSON object.');
    }
    final rawList = payload['messages'];
    if (rawList is! List) {
      return const <ChatMessageDto>[];
    }

    final messages = <ChatMessageDto>[];
    for (final item in rawList) {
      final parsed = _parseMessage(item);
      if (parsed != null) {
        messages.add(parsed);
      }
    }
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<JudgeRoundResult> judgeRound({
    required String roundId,
    required bool isFraudJudged,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.judgePathByRoundId(roundId),
    );
    final response = await _dio.post<dynamic>(
      endpoint,
      data: <String, dynamic>{'is_fraud_judged': isFraudJudged},
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ),
    );

    final payload = _asMap(response.data);
    if (payload == null) {
      throw StateError('Judge response is not a valid JSON object.');
    }
    final data = _asMap(payload['data']) ?? payload;
    return JudgeRoundResult(
      result: data['result']?.toString() ?? '',
      scoreDelta: _toInt(data['score_delta']) ?? 0,
      currentScore: _toInt(data['current_score']) ?? 0,
      currentWarning: _toInt(data['current_warning']) ?? 0,
      isStageCleared: _toBool(data['is_stage_cleared']) ?? false,
      rawBody: payload,
    );
  }

  Future<RoundReportResult> fetchRoundReport({
    required String roundId,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.reportPathByRoundId(roundId),
    );
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
      throw StateError('Report response is not a valid JSON object.');
    }
    final status = payload['status']?.toString();
    if (status != null && status != 'success') {
      throw StateError('Report response status is not success.');
    }
    final data = _asMap(payload['data']) ?? payload;

    final rawFraudPoints = data['fraud_points'];
    final fraudPoints = <ReportFraudPointDto>[];
    if (rawFraudPoints is List) {
      for (final item in rawFraudPoints) {
        final point = _asMap(item);
        if (point == null) {
          continue;
        }
        fraudPoints.add(
          ReportFraudPointDto(
            messageId: _toIdString(point['message_id']),
            reason: point['reason']?.toString() ?? '',
            tip: point['tip']?.toString() ?? '',
          ),
        );
      }
    }

    return RoundReportResult(
      reportId: _toIdString(data['report_id']),
      roundId: _toIdString(data['round_id']),
      reportType: data['report_type']?.toString() ?? '',
      summary: data['summary']?.toString() ?? '',
      fraudPoints: fraudPoints,
    );
  }

  Future<RoundReportDto> fetchReport({
    required String roundId,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      '/api/v1/rounds/$roundId/report',
    );

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
      throw StateError('Report response is not a valid JSON object.');
    }

    final fraudPointsRaw = payload['fraud_points'];
    final fraudPointsList = <Map<String, dynamic>>[];
    
    if (fraudPointsRaw is List) {
      for (final item in fraudPointsRaw) {
        final parsedItem = _asMap(item);
        if (parsedItem != null) {
          fraudPointsList.add(parsedItem);
        }
      }
    }

    return RoundReportDto(
      reportId: payload['report_id']?.toString() ?? '',
      roundId: payload['round_id']?.toString() ?? '',
      reportType: payload['report_type']?.toString() ?? '',
      summary: payload['summary']?.toString() ?? '',
      fraudPoints: fraudPointsList,
    );
  }

  ChatMessageDto? _parseMessage(dynamic raw) {
    final item = _asMap(raw);
    if (item == null) {
      return null;
    }
    final content = item['content']?.toString().trim() ?? '';
    if (content.isEmpty) {
      return null;
    }
    return ChatMessageDto(
      messageId: _toIdString(item['message_id']) ?? _toIdString(item['id']),
      roundId: _toIdString(item['round_id']),
      role: (item['role']?.toString().trim().toLowerCase() ?? 'ai'),
      content: content,
      createdAt: _toDateTime(item['created_at']) ?? DateTime.now(),
    );
  }

  String? _extractRoundId(
    Map<String, dynamic> payload,
    Map<String, dynamic>? data,
  ) {
    final fromData =
        _toIdString(data?['round_id']) ?? _toIdString(data?['id']);
    if (fromData != null) {
      return fromData;
    }
    final topLevel =
        _toIdString(payload['round_id']) ?? _toIdString(payload['id']);
    if (topLevel != null) {
      return topLevel;
    }
    final round = _asMap(payload['round']);
    if (round == null) {
      return null;
    }
    return _toIdString(round['round_id']) ?? _toIdString(round['id']);
  }

  SituationPromptDto? _parseSituationPrompt(dynamic raw) {
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) {
        return null;
      }
      return _parseSituationPromptFromString(text);
    }

    final prompt = _asMap(raw);
    if (prompt == null) {
      return null;
    }
    final situation =
        prompt['situation']?.toString().trim() ??
        prompt['situation_prompt']?.toString().trim() ??
        '';
    final currentStage =
        prompt['current_stage']?.toString().trim() ??
        prompt['currentStage']?.toString().trim() ??
        '';
    final userIntent =
        prompt['user_intent']?.toString().trim() ??
        prompt['userIntent']?.toString().trim() ??
        '';
    if (situation.isEmpty && currentStage.isEmpty && userIntent.isEmpty) {
      return null;
    }
    return SituationPromptDto(
      situation: situation,
      currentStage: currentStage,
      userIntent: userIntent,
    );
  }

  SituationPromptDto _parseSituationPromptFromString(String text) {
    String situation = '';
    String currentStage = '';
    String userIntent = '';

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('상황:')) {
        situation = line.substring('상황:'.length).trim();
        continue;
      }
      if (line.startsWith('현재 단계:')) {
        currentStage = line.substring('현재 단계:'.length).trim();
        continue;
      }
      if (line.startsWith('내가 하려는 것:')) {
        userIntent = line.substring('내가 하려는 것:'.length).trim();
        continue;
      }
      if (line.startsWith('의도:')) {
        userIntent = line.substring('의도:'.length).trim();
      }
    }

    if (situation.isEmpty && currentStage.isEmpty && userIntent.isEmpty) {
      situation = text;
    }

    return SituationPromptDto(
      situation: situation,
      currentStage: currentStage,
      userIntent: userIntent,
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

String? _toIdString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
  if (value is num) {
    return value.toString();
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _toDateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
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
