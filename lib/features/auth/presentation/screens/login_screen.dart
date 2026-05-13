import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:three_degress_of_doubt_frontend/core/config/dev_auth_config.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';
import 'package:three_degress_of_doubt_frontend/features/profile/presentation/screens/profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AppDependencies.authRepository;

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isFormVisible = false;

  @override
  void initState() {
    super.initState();
    if (DevAuthConfig.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, '/main');
      });
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _isFormVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        !_isLoading;
  }

  Future<void> _handleEmailLogin() async {
    if (!_canSubmit) return;
    setState(() => _isLoading = true);

    try {
      final credential = await _authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('로그인 사용자 정보를 가져오지 못했습니다.');
      }
      final idToken = await _authRepository.getIdToken(user);
      if (idToken == null || idToken.isEmpty) {
        throw StateError('인증 토큰 발급에 실패했습니다.');
      }
      final syncResult = await _authRepository.syncWithBackend(
        idToken: idToken,
      );
      if (!mounted) return;
      if (syncResult.isNewUser) {
        Navigator.pushReplacementNamed(
          context,
          '/profile-setup',
          arguments: ProfileSetupArgs(
            initialNickname: syncResult.user.nickname ?? '',
            initialProfileImageUrl: syncResult.user.profileImageUrl ?? '',
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showError(_mapAuthError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final credential = await _authRepository.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw StateError('로그인 사용자 정보를 가져오지 못했습니다.');
      }
      final idToken = await _authRepository.getIdToken(user);
      if (idToken == null || idToken.isEmpty) {
        throw StateError('인증 토큰 발급에 실패했습니다.');
      }
      final syncResult = await _authRepository.syncWithBackend(
        idToken: idToken,
      );
      if (!mounted) return;
      if (syncResult.isNewUser) {
        Navigator.pushReplacementNamed(
          context,
          '/profile-setup',
          arguments: ProfileSetupArgs(
            initialNickname: syncResult.user.nickname ?? '',
            initialProfileImageUrl: syncResult.user.profileImageUrl ?? '',
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showError(_mapAuthError(error));
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
      resizeToAvoidBottomInset: false,
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 64),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF072315),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 36,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ScamShield',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AI 사기 방지 시뮬레이터',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                      const SizedBox(height: 64),
                      if (_isFormVisible) _buildForm(cardColor, primaryGreen),
                      if (!_isFormVisible)
                        _buildSkeleton(cardColor, primaryGreen),
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(color: borderColor, height: 1),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '또는',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: borderColor, height: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: cardColor,
                            side: const BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Google로 계속하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: subtitleColor, fontSize: 14),
                    children: [
                      const TextSpan(text: '계정이 없으신가요? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Color cardColor, Color primaryGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: TextField(
            controller: _emailController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: '이메일',
              hintStyle: const TextStyle(
                color: Color(0xFF8D98A8),
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.mail_outline,
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
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: TextField(
            controller: _passwordController,
            onChanged: (_) => setState(() {}),
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: '비밀번호',
              hintStyle: const TextStyle(
                color: Color(0xFF8D98A8),
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF8D98A8),
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF8D98A8),
                  size: 20,
                ),
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
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _canSubmit ? _handleEmailLogin : null,
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
                    '로그인',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(Color cardColor, Color primaryGreen) {
    return Column(
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    );
  }

  String _mapAuthError(Object error) {
    if (error is GoogleSignInException) {
      final description = (error.description ?? '').trim();
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          return description.isEmpty
              ? 'Google 로그인 취소됨 (code: canceled)'
              : 'Google 로그인 취소됨 (code: canceled)\n$description';
        case GoogleSignInExceptionCode.interrupted:
          return description.isEmpty
              ? 'Google 로그인 중단됨 (code: interrupted)'
              : 'Google 로그인 중단됨 (code: interrupted)\n$description';
        case GoogleSignInExceptionCode.uiUnavailable:
          return description.isEmpty
              ? 'Google 로그인 UI 사용 불가 (code: uiUnavailable)'
              : 'Google 로그인 UI 사용 불가 (code: uiUnavailable)\n$description';
        case GoogleSignInExceptionCode.clientConfigurationError:
          return description.isEmpty
              ? 'Google 로그인 설정 오류 (code: clientConfigurationError)'
              : 'Google 로그인 설정 오류 (code: clientConfigurationError)\n$description';
        case GoogleSignInExceptionCode.providerConfigurationError:
          return description.isEmpty
              ? 'Google Provider 설정 오류 (code: providerConfigurationError)'
              : 'Google Provider 설정 오류 (code: providerConfigurationError)\n$description';
        case GoogleSignInExceptionCode.userMismatch:
          return description.isEmpty
              ? 'Google 계정 불일치 (code: userMismatch)'
              : 'Google 계정 불일치 (code: userMismatch)\n$description';
        case GoogleSignInExceptionCode.unknownError:
          return description.isEmpty
              ? 'Google 로그인 알 수 없는 오류 (code: unknownError)'
              : 'Google 로그인 알 수 없는 오류 (code: unknownError)\n$description';
      }
    }

    final text = error.toString();
    if (text.contains('wrong-password') ||
        text.contains('user-not-found') ||
        text.contains('invalid-credential')) {
      return '이메일 또는 비밀번호가 일치하지 않습니다.';
    }
    if (text.contains('invalid-email')) {
      return '이메일 형식을 확인해 주세요.';
    }
    if (text.contains('user-disabled')) {
      return '비활성화된 계정입니다.';
    }
    if (text.contains('canceled')) {
      return '로그인이 취소되었습니다.';
    }
    return '로그인 중 오류가 발생했습니다.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
