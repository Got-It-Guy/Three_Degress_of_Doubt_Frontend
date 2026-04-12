import 'package:flutter/material.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AppDependencies.authRepository;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _isFormVisible = false;

  @override
  void initState() {
    super.initState();
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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordMatched {
    return _passwordController.text == _confirmPasswordController.text;
  }

  bool get _isFormValid {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _isPasswordMatched &&
        !_isLoading;
  }

  Future<void> _handleSignup() async {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);

    try {
      final credential = await _authRepository.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('회원가입 사용자 정보를 가져오지 못했습니다.');
      }
      await _authRepository.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인 후 계속 진행해 주세요.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
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

    final isPasswordError =
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        !_isPasswordMatched;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('돌아가기'),
                  style: TextButton.styleFrom(
                    foregroundColor: subtitleColor,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 14),
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
                        '회원가입',
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
                        'ScamShield와 함께 사기 예방 훈련을 시작하세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                      const SizedBox(height: 64),
                      if (_isFormVisible)
                        _buildForm(
                          cardColor: cardColor,
                          primaryGreen: primaryGreen,
                          isPasswordError: isPasswordError,
                        ),
                      if (!_isFormVisible)
                        _buildSkeleton(cardColor, primaryGreen),
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
                      const TextSpan(text: '이미 계정이 있으신가요? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            '로그인',
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

  Widget _buildForm({
    required Color cardColor,
    required Color primaryGreen,
    required bool isPasswordError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: TextField(
            controller: _emailController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 15),
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: TextField(
            controller: _confirmPasswordController,
            onChanged: (_) => setState(() {}),
            obscureText: !_showConfirmPassword,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: '비밀번호 확인',
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
                onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
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
        if (isPasswordError) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '비밀번호가 일치하지 않습니다.',
              style: TextStyle(color: Color(0xFFFF6D6D), fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isFormValid ? _handleSignup : null,
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
                    '회원가입',
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
        _skeletonItem(cardColor),
        const SizedBox(height: 12),
        _skeletonItem(cardColor),
        const SizedBox(height: 12),
        _skeletonItem(cardColor),
        const SizedBox(height: 14),
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

  Widget _skeletonItem(Color color) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  String _mapAuthError(Object error) {
    if (error.toString().contains('email-already-in-use')) {
      return '이미 가입된 이메일입니다.';
    }
    if (error.toString().contains('weak-password')) {
      return '비밀번호가 너무 약합니다.';
    }
    if (error.toString().contains('invalid-email')) {
      return '이메일 형식을 확인해 주세요.';
    }
    return '회원가입 중 오류가 발생했습니다.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
