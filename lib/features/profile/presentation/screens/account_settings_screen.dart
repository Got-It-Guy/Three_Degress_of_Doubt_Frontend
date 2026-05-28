import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _authRepository = AppDependencies.authRepository;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  File? _selectedImage;
  String? _currentImageUrl;

  final _nicknameController = TextEditingController();
  String _currentNickname = '';

  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;

  bool _isEmailProvider = false;

  @override
  void initState() {
    super.initState();
    _initUserInfo();
  }

  Future<void> _initUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isEmailProvider = user.providerData.any((p) => p.providerId == 'password');

    try {
      final idToken = await user.getIdToken();
      if (idToken == null) return;

      final profile = await _authRepository.fetchMyProfile(idToken: idToken);

      if (!mounted) return;

      setState(() {
        _currentNickname = profile.nickname ?? '';
        _nicknameController.text = _currentNickname;
        _currentImageUrl = profile.profileImageUrl;
      });
    } catch (_) {
      setState(() {
        _currentNickname = user.displayName ?? '';
        _nicknameController.text = _currentNickname;
        _currentImageUrl = user.photoURL;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (_) {
      _showSnack('이미지를 불러오는 중 오류가 발생했습니다.');
    }
  }

  Future<void> _saveProfileImage() async {
    if (_selectedImage == null) {
      _showSnack('변경할 이미지를 선택해주세요.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보가 없습니다.');
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('인증 토큰을 가져오지 못했습니다.');

      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await _authRepository.updateMyProfile(
        idToken: idToken,
        nickname: _currentNickname.isNotEmpty ? _currentNickname : '닉네임',
        profileImageDataUrl: base64Image,
      );

      if (!mounted) return;
      setState(() => _currentImageUrl = null);
      _showSnack('프로필 사진이 변경되었습니다.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('사진 변경 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNickname() async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) {
      _showSnack('닉네임을 입력해주세요.');
      return;
    }
    if (newNickname == _currentNickname) {
      _showSnack('현재 닉네임과 동일합니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보가 없습니다.');
      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('인증 토큰을 가져오지 못했습니다.');

      await _authRepository.updateMyProfile(
        idToken: idToken,
        nickname: newNickname,
      );
      await user.updateDisplayName(newNickname);
      await user.reload();

      if (!mounted) return;
      setState(() => _currentNickname = newNickname);
      _showSnack('닉네임이 변경되었습니다.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('닉네임 변경 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPwController.text;
    final newPw = _newPwController.text;
    final confirm = _confirmPwController.text;

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      _showSnack('모든 항목을 입력해주세요.');
      return;
    }
    if (newPw.length < 6) {
      _showSnack('새 비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    if (newPw != confirm) {
      _showSnack('새 비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('로그인 정보가 없습니다.');

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPw);

      if (!mounted) return;
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
      _showSnack('비밀번호가 변경되었습니다.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'wrong-password'
          ? '현재 비밀번호가 올바르지 않습니다.'
          : '비밀번호 변경 실패: ${e.message}';
      _showSnack(message);
    } catch (e) {
      if (!mounted) return;
      _showSnack('비밀번호 변경 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Material(
                    color: cardColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, true),
                      borderRadius: BorderRadius.circular(20),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '계정 설정',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: borderColor, thickness: 1, height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 28.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('프로필 사진', subtitleColor),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isLoading ? null : _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withAlpha(25),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: _buildAvatarContent(primaryGreen),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: subtitleColor,
                                    size: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '사진을 눌러 변경하세요',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _saveButton(
                      label: '사진 저장',
                      onTap: _isLoading ? null : _saveProfileImage,
                      primaryGreen: primaryGreen,
                      cardColor: cardColor,
                    ),

                    const SizedBox(height: 36),
                    const Divider(color: borderColor, thickness: 1),
                    const SizedBox(height: 28),

                    _sectionLabel('닉네임 변경', subtitleColor),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nicknameController,
                      hint: '새 닉네임을 입력하세요',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      primaryGreen: primaryGreen,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 16),
                    _saveButton(
                      label: '닉네임 저장',
                      onTap: _isLoading ? null : _saveNickname,
                      primaryGreen: primaryGreen,
                      cardColor: cardColor,
                    ),

                    if (_isEmailProvider) ...[
                      const SizedBox(height: 36),
                      const Divider(color: borderColor, thickness: 1),
                      const SizedBox(height: 28),

                      _sectionLabel('비밀번호 변경', subtitleColor),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _currentPwController,
                        hint: '현재 비밀번호',
                        obscure: !_showCurrentPw,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        primaryGreen: primaryGreen,
                        subtitleColor: subtitleColor,
                        suffix: _eyeIcon(_showCurrentPw, () {
                          setState(() => _showCurrentPw = !_showCurrentPw);
                        }, subtitleColor),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _newPwController,
                        hint: '새 비밀번호 (6자 이상)',
                        obscure: !_showNewPw,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        primaryGreen: primaryGreen,
                        subtitleColor: subtitleColor,
                        suffix: _eyeIcon(_showNewPw, () {
                          setState(() => _showNewPw = !_showNewPw);
                        }, subtitleColor),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _confirmPwController,
                        hint: '새 비밀번호 확인',
                        obscure: !_showConfirmPw,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        primaryGreen: primaryGreen,
                        subtitleColor: subtitleColor,
                        suffix: _eyeIcon(_showConfirmPw, () {
                          setState(() => _showConfirmPw = !_showConfirmPw);
                        }, subtitleColor),
                      ),
                      const SizedBox(height: 16),
                      _saveButton(
                        label: '비밀번호 변경',
                        onTap: _isLoading ? null : _savePassword,
                        primaryGreen: primaryGreen,
                        cardColor: cardColor,
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFF223042),
                color: Color(0xFF00D64F),
                minHeight: 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(Color primaryGreen) {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    }
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      if (_currentImageUrl!.startsWith('data:')) {
        final commaIdx = _currentImageUrl!.indexOf(',');
        if (commaIdx >= 0) {
          try {
            final bytes = base64Decode(
              _currentImageUrl!.substring(commaIdx + 1),
            );
            return Image.memory(bytes, fit: BoxFit.cover);
          } catch (_) {}
        }
      } else {
        return Image.network(
          _currentImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.person, size: 48, color: primaryGreen),
        );
      }
    }
    return Icon(Icons.person, size: 48, color: primaryGreen);
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color cardColor,
    required Color borderColor,
    required Color primaryGreen,
    required Color subtitleColor,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryGreen),
        ),
        hintText: hint,
        hintStyle: TextStyle(color: subtitleColor),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _saveButton({
    required String label,
    required VoidCallback? onTap,
    required Color primaryGreen,
    required Color cardColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF020911),
          ),
        ),
      ),
    );
  }

  Widget _eyeIcon(bool visible, VoidCallback onTap, Color color) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: color,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}
