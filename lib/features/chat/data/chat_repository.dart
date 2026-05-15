import 'package:dio/dio.dart';
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
  const SendMessageResult({required this.messages});

  final List<ChatMessageDto> messages;
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
  });

  final String result;
  final int scoreDelta;
  final int currentScore;
  final int currentWarning;
  final bool isStageCleared;
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

    return SendMessageResult(messages: aiMessages);
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
    final prompt = _asMap(raw);
    if (prompt == null) {
      return null;
    }
    final situation = prompt['situation']?.toString().trim() ?? '';
    final currentStage = prompt['current_stage']?.toString().trim() ?? '';
    final userIntent = prompt['user_intent']?.toString().trim() ?? '';
    if (situation.isEmpty && currentStage.isEmpty && userIntent.isEmpty) {
      return null;
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
