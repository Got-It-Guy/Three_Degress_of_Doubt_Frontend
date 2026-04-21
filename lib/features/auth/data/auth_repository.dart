import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:three_degress_of_doubt_frontend/core/config/backend_config.dart';
import 'package:three_degress_of_doubt_frontend/core/config/google_auth_config.dart';

class SyncedUser {
  const SyncedUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.provider,
    required this.nickname,
    required this.isNewUser,
    required this.profileImageUrl,
  });

  final int? id;
  final String? firebaseUid;
  final String? email;
  final String? provider;
  final String? nickname;
  final bool isNewUser;
  final String? profileImageUrl;

  factory SyncedUser.fromJson(Map<String, dynamic> json) {
    return SyncedUser(
      id: _toIntOrNull(json['id']),
      firebaseUid: _toStringOrNull(json['firebaseUid']),
      email: _toStringOrNull(json['email']),
      provider: _toStringOrNull(json['provider']),
      nickname: _toStringOrNull(json['nickname']),
      isNewUser: _toBool(json['isNewUser']) ?? false,
      profileImageUrl:
          _toStringOrNull(json['profileImageUrl']) ??
          _toStringOrNull(json['profileImageDataUrl']) ??
          _toStringOrNull(json['profileImageBase64']),
    );
  }

  SyncedUser copyWith({
    int? id,
    String? firebaseUid,
    String? email,
    String? provider,
    String? nickname,
    bool? isNewUser,
    String? profileImageUrl,
  }) {
    return SyncedUser(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      nickname: nickname ?? this.nickname,
      isNewUser: isNewUser ?? this.isNewUser,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class AuthSyncResult {
  const AuthSyncResult({required this.user});

  final SyncedUser user;

  bool get isNewUser => user.isNewUser;
}

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required Dio dio,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _dio = dio;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final Dio _dio;
  Future<void>? _googleInitFuture;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw StateError(
        'Google authentication is not supported on this platform',
      );
    }

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      if (_googleSignIn.supportsAuthenticate()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // ignore: best-effort sign out for Google provider
    }
  }

  Future<String?> getIdToken(User user) {
    return user.getIdToken();
  }

  Future<AuthSyncResult> syncWithBackend({
    required String idToken,
    String? nickname,
  }) async {
    final baseUrl = BackendConfig.baseUrl;
    final authPath = BackendConfig.authPath;

    final safeNickname = (nickname != null && nickname.trim().isNotEmpty)
        ? nickname.trim()
        : null;

    final endpoint = _joinUrl(baseUrl, authPath);
    final body = <String, dynamic>{};
    if (safeNickname != null) {
      body['nickname'] = safeNickname;
    }

    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: body,
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
        throw StateError('Backend auth failed ($statusCode): ${response.data}');
      }

      final payload = _asMap(response.data);
      if (payload == null) {
        throw StateError('Backend auth response is not a valid JSON object.');
      }

      final status = payload['status']?.toString();
      if (status != 'success') {
        throw StateError('Backend auth status is not success.');
      }

      final user = _extractSyncedUser(payload);
      return AuthSyncResult(user: user);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final body = error.response?.data ?? error.message;
      final suffix = statusCode != null ? ' ($statusCode)' : '';
      throw StateError('Backend auth failed$suffix: $body');
    }
  }

  Future<SyncedUser> updateMyProfile({
    required String idToken,
    required String nickname,
    String? profileImageUrl,
    String? profileImageDataUrl,
  }) async {
    final baseUrl = BackendConfig.baseUrl;
    final profilePath = BackendConfig.profilePath;
    final endpoint = _joinUrl(baseUrl, profilePath);

    final safeNickname = nickname.trim();
    if (safeNickname.isEmpty) {
      throw StateError('닉네임은 비어 있을 수 없습니다.');
    }

    final body = <String, dynamic>{'nickname': safeNickname};
    final safeImageUrl = _toStringOrNull(profileImageUrl);
    final safeImageDataUrl = _toStringOrNull(profileImageDataUrl);

    if (safeImageUrl != null) {
      body['profileImageUrl'] = safeImageUrl;
    }
    if (safeImageDataUrl != null) {
      // Compatibility payload for mock server now and multipart transition later.
      body['profileImageDataUrl'] = safeImageDataUrl;
      body['profileImageBase64'] = safeImageDataUrl;
      body['profileImageUrl'] = body['profileImageUrl'] ?? safeImageDataUrl;
    }

    try {
      final response = await _dio.patch<dynamic>(
        endpoint,
        data: body,
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
        throw StateError(
          'Backend profile update failed ($statusCode): ${response.data}',
        );
      }

      final payload = _asMap(response.data);
      if (payload == null) {
        throw StateError(
          'Backend profile response is not a valid JSON object.',
        );
      }

      final userMap = payload['user'] is Map<String, dynamic>
          ? payload['user'] as Map<String, dynamic>
          : payload;
      final parsedUser = _extractSyncedUser(payload);

      final mergedUser = parsedUser.copyWith(
        nickname: _toStringOrNull(userMap['nickname']) ?? safeNickname,
        profileImageUrl:
            _toStringOrNull(userMap['profileImageUrl']) ??
            _toStringOrNull(userMap['profileImageDataUrl']) ??
            _toStringOrNull(userMap['profileImageBase64']) ??
            parsedUser.profileImageUrl,
      );

      return mergedUser;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final body = error.response?.data ?? error.message;
      final suffix = statusCode != null ? ' ($statusCode)' : '';
      throw StateError('Backend profile update failed$suffix: $body');
    }
  }

  Future<SyncedUser> fetchMyProfile({required String idToken}) async {
    final baseUrl = BackendConfig.baseUrl;
    final profilePath = BackendConfig.profilePath;
    final endpoint = _joinUrl(baseUrl, profilePath);

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
        throw StateError(
          'Backend profile fetch failed ($statusCode): ${response.data}',
        );
      }

      final payload = _asMap(response.data);
      if (payload == null) {
        throw StateError(
          'Backend profile fetch response is not a valid JSON object.',
        );
      }

      final status = payload['status']?.toString();
      if (status != null && status != 'success') {
        throw StateError('Backend profile fetch status is not success.');
      }

      return _extractSyncedUser(payload);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final body = error.response?.data ?? error.message;
      final suffix = statusCode != null ? ' ($statusCode)' : '';
      throw StateError('Backend profile fetch failed$suffix: $body');
    }
  }

  Future<void> _ensureGoogleInitialized() {
    _googleInitFuture ??= _googleSignIn.initialize(
      serverClientId: GoogleAuthConfig.serverClientId,
    );
    return _googleInitFuture!;
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

  SyncedUser _extractSyncedUser(Map<String, dynamic> payload) {
    final userRaw = payload['user'];
    Map<String, dynamic> userMap;
    if (userRaw is Map<String, dynamic>) {
      userMap = userRaw;
    } else if (userRaw is Map) {
      userMap = userRaw.map((key, value) => MapEntry(key.toString(), value));
    } else {
      userMap = payload;
    }

    final parsed = SyncedUser.fromJson(userMap);
    final topLevelIsNewUser = _toBool(payload['isNewUser']);
    if (topLevelIsNewUser != null) {
      return parsed.copyWith(isNewUser: topLevelIsNewUser);
    }
    return parsed;
  }
}

int? _toIntOrNull(dynamic value) {
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

String? _toStringOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
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
