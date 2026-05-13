import 'package:dio/dio.dart';
import 'package:three_degress_of_doubt_frontend/core/config/backend_config.dart';
import 'package:three_degress_of_doubt_frontend/core/config/dev_auth_config.dart';

class ChatMessageDto {
  const ChatMessageDto({
    required this.messageId,
    required this.roundId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final int? messageId;
  final int? roundId;
  final String role;
  final String content;
  final DateTime createdAt;
}

class SendMessageResult {
  const SendMessageResult({required this.messages});

  final List<ChatMessageDto> messages;
}

class ChatRepository {
  ChatRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<int> createRound({
    required int stageId,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.roundsPathByStageId(stageId),
    );
    final bearerToken = DevAuthConfig.resolveBearerToken(idToken);
    final response = await _dio.post<dynamic>(
      endpoint,
      data: const <String, dynamic>{},
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json; charset=utf-8',
        },
      ),
    );

    final payload = _asMap(response.data);
    if (payload == null) {
      throw StateError('Round create response is not a valid JSON object.');
    }
    final roundId = _extractRoundId(payload);
    if (roundId == null) {
      throw StateError('Round create response does not contain round_id.');
    }
    return roundId;
  }

  Future<SendMessageResult> sendMessage({
    required int roundId,
    required String content,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.messagesPathByRoundId(roundId),
    );
    final bearerToken = DevAuthConfig.resolveBearerToken(idToken);
    final response = await _dio.post<dynamic>(
      endpoint,
      data: <String, dynamic>{'content': content},
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $bearerToken',
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
    required int roundId,
    required String idToken,
  }) async {
    final endpoint = _joinUrl(
      BackendConfig.baseUrl,
      BackendConfig.messagesPathByRoundId(roundId),
    );
    final bearerToken = DevAuthConfig.resolveBearerToken(idToken);
    final response = await _dio.get<dynamic>(
      endpoint,
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer $bearerToken',
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
      messageId: _toInt(item['message_id']) ?? _toInt(item['id']),
      roundId: _toInt(item['round_id']),
      role: (item['role']?.toString().trim().toLowerCase() ?? 'ai'),
      content: content,
      createdAt: _toDateTime(item['created_at']) ?? DateTime.now(),
    );
  }

  int? _extractRoundId(Map<String, dynamic> payload) {
    final topLevel = _toInt(payload['round_id']) ?? _toInt(payload['id']);
    if (topLevel != null) {
      return topLevel;
    }
    final round = _asMap(payload['round']);
    if (round == null) {
      return null;
    }
    return _toInt(round['round_id']) ?? _toInt(round['id']);
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

DateTime? _toDateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
