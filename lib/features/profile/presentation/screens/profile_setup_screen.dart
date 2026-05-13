import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:three_degress_of_doubt_frontend/core/config/dev_auth_config.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';

class ProfileSetupArgs {
  const ProfileSetupArgs({
    this.initialNickname = '',
    this.initialProfileImageUrl = '',
  });

  final String initialNickname;
  final String initialProfileImageUrl;
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.args = const ProfileSetupArgs()});

  final ProfileSetupArgs args;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const int _maxUploadBytes = 1200 * 1024; // ~1.2MB

  final _nicknameController = TextEditingController();
  final _authRepository = AppDependencies.authRepository;
  final _imagePicker = ImagePicker();

  late final String _initialProfileImageUrl;
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.args.initialNickname;
    _initialProfileImageUrl = widget.args.initialProfileImageUrl;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nicknameController.text.trim().isNotEmpty && !_isLoading;

  Future<void> _pickImageFromGallery() async {
    if (_isLoading) {
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 80,
      );

      if (!mounted || picked == null) {
        return;
      }
      setState(() => _selectedImage = picked);
    } on Exception {
      if (!mounted) {
        return;
      }
      _showError('이미지를 선택하는 중 오류가 발생했습니다.');
    }
  }

  String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  Future<String> _buildDataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxUploadBytes) {
      throw StateError('선택한 이미지가 너무 큽니다. 1.2MB 이하로 선택해 주세요.');
    }
    final base64 = base64Encode(bytes);
    final mimeType = _mimeTypeFromPath(file.path);
    return 'data:$mimeType;base64,$base64';
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      String token;
      if (DevAuthConfig.enabled) {
        token = DevAuthConfig.bearerToken;
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw StateError('로그인 정보가 만료되었습니다. 다시 로그인해 주세요.');
        }
        final idToken = await user.getIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw StateError('인증 토큰 발급에 실패했습니다.');
        }
        token = idToken;
      }

      String? profileImagePayload;
      if (_selectedImage != null) {
        profileImagePayload = await _buildDataUrl(_selectedImage!);
      }

      await _authRepository.updateMyProfile(
        idToken: token,
        nickname: _nicknameController.text.trim(),
        profileImageDataUrl: profileImagePayload,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } on Exception catch (error) {
      if (mounted) {
        _showError(_mapError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF020911);
    const cardColor = Color(0xFF111A24);
    const primaryGreen = Color(0xFF00D64F);
    const subtitleColor = Color(0xFF9AA4B2);
    const borderColor = Color(0xFF223042);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF072315),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 36,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '초기 프로필 설정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '닉네임과 프로필 이미지를 설정하고 시작하세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: subtitleColor, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildProfilePreview(
                cardColor: cardColor,
                borderColor: borderColor,
                subtitleColor: subtitleColor,
                primaryGreen: primaryGreen,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 50,
                        child: TextField(
                          controller: _nicknameController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: '닉네임',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8D98A8),
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF8D98A8),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _pickImageFromGallery,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: cardColor,
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text(
                            _selectedImage == null
                                ? '갤러리에서 이미지 선택'
                                : '이미지 다시 선택',
                          ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _selectedImage = null),
                            style: TextButton.styleFrom(
                              foregroundColor: subtitleColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('선택 해제'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        '목서버 단계에서는 이미지를 Base64로 임시 전송합니다. (최대 1.2MB)',
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: const Color(0xFF001506),
                    disabledBackgroundColor: const Color(0xFF1A4730),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF001506),
                            ),
                          ),
                        )
                      : const Text(
                          '저장하고 시작하기',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePreview({
    required Color cardColor,
    required Color borderColor,
    required Color subtitleColor,
    required Color primaryGreen,
  }) {
    final selectedImage = _selectedImage;
    final initialImageUrl = _initialProfileImageUrl.trim();
    final hasInitialImage =
        selectedImage == null &&
        (initialImageUrl.startsWith('http://') ||
            initialImageUrl.startsWith('https://'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1C2835),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: borderColor),
            ),
            clipBehavior: Clip.hardEdge,
            child: selectedImage != null
                ? Image.file(
                    File(selectedImage.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 34,
                      );
                    },
                  )
                : hasInitialImage
                ? Image.network(
                    initialImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 34,
                      );
                    },
                  )
                : const Icon(Icons.person, color: Colors.white70, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nicknameController.text.trim().isEmpty
                      ? '닉네임을 입력해 주세요'
                      : _nicknameController.text.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedImage != null
                      ? '선택된 이미지가 업로드됩니다'
                      : hasInitialImage
                      ? '기존 이미지가 유지됩니다'
                      : '기본 프로필 이미지가 사용됩니다',
                  style: TextStyle(
                    color: selectedImage != null ? primaryGreen : subtitleColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mapError(Object error) {
    final text = error.toString();
    if (text.contains('401') || text.contains('403')) {
      return '세션이 만료되었습니다. 다시 로그인해 주세요.';
    }
    if (text.contains('413') || text.contains('Payload Too Large')) {
      return '이미지 크기가 너무 큽니다. 더 작은 이미지를 선택해 주세요.';
    }
    if (text.contains('1.2MB')) {
      return '이미지 크기가 너무 큽니다. 1.2MB 이하 이미지를 선택해 주세요.';
    }
    return '프로필 저장 중 오류가 발생했습니다.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
