import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:three_degress_of_doubt_frontend/core/config/dev_auth_config.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';
import 'package:three_degress_of_doubt_frontend/features/chat/presentation/screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingProgress = true;
  String? _progressError;
  late List<_StageCardData> _stages;

  @override
  void initState() {
    super.initState();
    _stages = _baseStages();
    _loadStageProgress();
  }

  Future<void> _loadStageProgress() async {
    try {
      String idToken;
      if (DevAuthConfig.enabled) {
        idToken = DevAuthConfig.bearerToken;
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw StateError('로그인 정보가 없습니다. 다시 로그인해주세요.');
        }
        final token = await user.getIdToken();
        if (token == null || token.isEmpty) {
          throw StateError('인증 토큰을 가져오지 못했습니다.');
        }
        idToken = token;
      }

      final progressByStageId = await AppDependencies.stageRepository
          .fetchStageProgresses(idToken: idToken);
          
      if (!mounted) return;

      setState(() {
        _stages = _baseStages().map((stage) {
          final progress = progressByStageId[stage.stageId];
          final isCleared = progress?.isCleared ?? false;
          final stageScore = progress?.stageScore ?? 0;
          return stage.copyWith(
            isDone: isCleared,
            rounds: isCleared ? stageScore : 0,
          );
        }).toList();
        _progressError = null;
        _isLoadingProgress = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;

      setState(() {
        _progressError = error.toString();
        _isLoadingProgress = false;
      });
    }
  }

  Future<String?> _resolveIdToken() async {
    if (DevAuthConfig.enabled) {
      return DevAuthConfig.bearerToken;
    }
    final user = FirebaseAuth.instance.currentUser;
    return user?.getIdToken();
  }

  Future<void> _handleStageTap(_StageCardData stage) async {
    final token = await _resolveIdToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('인증 토큰을 가져오지 못했습니다.')));
      return;
    }

    try {
      debugPrint('[StageFlow] sync -> enter, stage_id=${stage.stageId}');
      if (!DevAuthConfig.enabled) {
        await AppDependencies.authRepository.syncWithBackend(idToken: token);
      }
      await AppDependencies.stageRepository.enterStage(
        stageId: stage.stageId,
        idToken: token,
      );
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: ChatScreenArgs(
          stageId: stage.stageId,
          stageTitle: stage.title,
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('스테이지 입장 실패: $error')));
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 20.0,
                bottom: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF072315),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ScamShield',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '사기 예방 훈련',
                            style: TextStyle(
                              color: subtitleColor.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Material(
                    color: borderColor,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      hoverColor: Colors.white.withValues(alpha: 0.1),
                      highlightColor: Colors.white.withValues(alpha: 0.2),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: borderColor, thickness: 1, height: 1),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: 16.0),
              child: Text(
                '훈련 시나리오',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_isLoadingProgress)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4),
                child: Text(
                  '진행 정보를 불러오는 중...',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
              ),
            if (_progressError != null && !_isLoadingProgress)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 4,
                ),
                child: Text(
                  '진행 정보 조회 실패: $_progressError',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final availableWidth = constraints.maxWidth;
                  const spacing = 18.0;
                  const horizontalPadding = 24.0;
                  const bottomPadding = 32.0;
                  final itemWidth =
                      (availableWidth - (horizontalPadding * 2) - spacing) / 2;
                  double itemHeight =
                      (availableHeight - bottomPadding - (spacing * 2)) / 3;

                  if (itemHeight <= 0) itemHeight = 1.0;

                  final dynamicAspectRatio = itemWidth / itemHeight;
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: bottomPadding,
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: dynamicAspectRatio,
                      ),
                      itemCount: _stages.length,
                      itemBuilder: (context, index) {
                        return _buildStageCard(
                          _stages[index],
                          cardColor,
                          primaryGreen,
                          subtitleColor,
                          borderColor,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_StageCardData> _baseStages() {
    return const [
      _StageCardData(
        stageId: 1,
        title: '보이스피싱',
        desc: '금융기관 사칭 전화사기',
        icon: Icons.phone_outlined,
        level: '쉬움',
        isDone: false,
        rounds: 0,
      ),
      _StageCardData(
        stageId: 2,
        title: '투자사기',
        desc: '고수익 보장 가짜 투자',
        icon: Icons.trending_up,
        level: '보통',
        isDone: false,
        rounds: 0,
      ),
      _StageCardData(
        stageId: 3,
        title: '부동산사기',
        desc: '허위 매물 및 전세 사기',
        icon: Icons.domain_outlined,
        level: '어려움',
        isDone: false,
        rounds: 0,
      ),
      _StageCardData(
        stageId: 4,
        title: '대출사기',
        desc: '저금리 대출 빙자 사기',
        icon: Icons.account_balance_outlined,
        level: '보통',
        isDone: false,
        rounds: 0,
      ),
      _StageCardData(
        stageId: 5,
        title: '중고사기',
        desc: '입금 후 잠적하는 사기',
        icon: Icons.shopping_bag_outlined,
        level: '쉬움',
        isDone: false,
        rounds: 0,
      ),
      _StageCardData(
        stageId: 6,
        title: '랜덤',
        desc: '무작위 시나리오 실습',
        icon: Icons.shuffle,
        level: '변동',
        isDone: false,
        rounds: 0,
      ),
    ];
  }

  Widget _buildStageCard(
    _StageCardData stage,
    Color cardColor,
    Color primaryGreen,
    Color subtitleColor,
    Color borderColor,
  ) {
    final isDone = stage.isDone;
    final iconColor = isDone
        ? primaryGreen
        : Colors.white.withValues(alpha: 0.7);
    final iconBgColor = isDone
        ? const Color(0xFF072315)
        : borderColor.withValues(alpha: 0.5);
    final cardBorderColor = isDone
        ? primaryGreen.withValues(alpha: 0.5)
        : borderColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleStageTap(stage),
        borderRadius: BorderRadius.circular(20),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardBorderColor,
              width: isDone ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(stage.icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stage.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.desc,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stage.level,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isDone)
                          Text(
                            '완료',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (isDone) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stage.rounds}라운드 클리어',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageCardData {
  const _StageCardData({
    required this.stageId,
    required this.title,
    required this.desc,
    required this.icon,
    required this.level,
    required this.isDone,
    required this.rounds,
  });

  final int stageId;
  final String title;
  final String desc;
  final IconData icon;
  final String level;
  final bool isDone;
  final int rounds;

  _StageCardData copyWith({
    int? stageId,
    String? title,
    String? desc,
    IconData? icon,
    String? level,
    bool? isDone,
    int? rounds,
  }) {
    return _StageCardData(
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      icon: icon ?? this.icon,
      level: level ?? this.level,
      isDone: isDone ?? this.isDone,
      rounds: rounds ?? this.rounds,
    );
  }
}
