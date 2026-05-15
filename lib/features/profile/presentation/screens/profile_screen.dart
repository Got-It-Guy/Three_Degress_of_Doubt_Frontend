import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';
import 'package:three_degress_of_doubt_frontend/features/auth/data/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepository = AppDependencies.authRepository;

  SyncedUser? _profile;
  bool _isLoadingProfile = true;
  String? _profileErrorMessage;
  bool _isSigningOut = false;

  int stageCount = 5;
  int totalRounds = 12;
  int attendanceDays = 3;

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
      _profileErrorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("로그인 정보가 없습니다.");
      }
      final idToken = await currentUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception("인증 토큰을 가져오지 못했습니다.");
      }

      final profile = await _authRepository.fetchMyProfile(idToken: idToken);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileErrorMessage = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _profileErrorMessage = _mapProfileError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;

    setState(() => _isSigningOut = true);
    try {
      await _authRepository.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  String get _displayNickname {
    final nickname = _profile?.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) return nickname;

    final displayName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    return '닉네임 미설정';
  }

  String get _displayEmail {
    final email = _profile?.email?.trim();
    if (email != null && email.isNotEmpty) return email;

    final authEmail = FirebaseAuth.instance.currentUser?.email?.trim();
    if (authEmail != null && authEmail.isNotEmpty) return authEmail;

    return '이메일 정보 없음';
  }

  String _getBadgeTitle(int level) {
    if (level >= 4) return "전설의 수호자";
    if (level >= 2) return "중급 수호자";
    return "초급 수호자";
  }

  String _mapProfileError(Object error) {
    final text = error.toString();
    if (text.contains('401') || text.contains('403')) {
      return '세션이 만료되었습니다. 다시 로그인해 주세요.';
    }
    if (text.contains('timed out') || text.contains('SocketException')) {
      return '서버에 연결할 수 없습니다. 네트워크를 확인해 주세요.';
    }
    return '프로필 정보를 불러오지 못했습니다.';
  }

  Uint8List? _decodeDataUrl(String? value) {
    if (value == null || !value.startsWith('data:')) return null;
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0) return null;

    final metadata = value.substring(0, commaIndex).toLowerCase();
    if (!metadata.contains(';base64')) return null;

    final raw = value.substring(commaIndex + 1);
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Widget _buildProfileAvatar({
    required Color primaryGreen,
    required Color borderColor,
  }) {
    final imageSource = _profile?.profileImageUrl?.trim();
    final imageBytes = _decodeDataUrl(imageSource);

    Widget content;
    if (imageBytes != null) {
      content = Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 48, color: Color(0xFF00D64F)),
      );
    } else if (imageSource != null &&
        (imageSource.startsWith('http://') ||
            imageSource.startsWith('https://'))) {
      content = Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 48, color: Color(0xFF00D64F)),
      );
    } else {
      content = const Icon(Icons.person, size: 48, color: Color(0xFF00D64F));
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: primaryGreen.withAlpha(25),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF020911);
    const cardColor = Color(0xFF111A24);
    const primaryGreen = Color(0xFF00D64F);
    const subtitleColor = Color(0xFF9AA4B2);
    const borderColor = Color(0xFF223042);
    const logoutRed = Color(0xFFFF4D4D);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Material(
                    color: cardColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '프로필',
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          _buildProfileAvatar(
                            primaryGreen: primaryGreen,
                            borderColor: borderColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isLoadingProfile ? '불러오는 중...' : _displayNickname,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoadingProfile
                                ? '프로필 정보를 가져오는 중입니다'
                                : _displayEmail,
                            style: const TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                          if (_profileErrorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _profileErrorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF6D6D),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed:
                                  _isLoadingProfile ? null : _loadMyProfile,
                              style: TextButton.styleFrom(
                                foregroundColor: subtitleColor,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: const Text('다시 시도'),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBadge(
                                'Lv. $stageCount',
                                primaryGreen.withAlpha(50),
                                primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                _getBadgeTitle(stageCount),
                                borderColor,
                                subtitleColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              '완료 스테이지',
                              '$stageCount',
                              Icons.grid_view_rounded,
                              primaryGreen,
                            ),
                            _buildStatItem(
                              '진행 라운드',
                              '$totalRounds',
                              Icons.play_circle_outline,
                              primaryGreen,
                            ),
                            _buildStatItem(
                              '접속 일수',
                              '$attendanceDays일',
                              Icons.calendar_today_outlined,
                              primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              Icons.person_outline,
                              '내 정보 변경',
                              subtitleColor,
                              borderColor,
                              true,
                              () {
                                Navigator.pushNamed(
                                    context, '/metadata-setup');
                              },
                            ),
                            _buildMenuItem(
                              Icons.settings_outlined,
                              '계정 설정',
                              subtitleColor,
                              borderColor,
                              true,
                              () {},
                            ),
                            _buildMenuItem(
                              Icons.help_outline,
                              '도움말',
                              subtitleColor,
                              borderColor,
                              false,
                              () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isSigningOut ? null : _handleSignOut,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: logoutRed.withAlpha(75)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    foregroundColor: logoutRed,
                  ),
                  child: _isSigningOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '로그아웃',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color primaryGreen,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2835),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9AA4B2),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    Color subtitleColor,
    Color borderColor,
    bool hasDivider,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: hasDivider
                ? Border(bottom: BorderSide(color: borderColor))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: subtitleColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: subtitleColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
