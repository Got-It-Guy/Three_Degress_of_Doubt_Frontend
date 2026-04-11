import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF020911);
    const cardColor = Color(0xFF111A24);
    const primaryGreen = Color(0xFF00D64F);
    const subtitleColor = Color(0xFF9AA4B2);
    const borderColor = Color(0xFF223042);

    final List<Map<String, dynamic>> stages = [
      {'title': '보이스피싱', 'desc': '금융기관 사칭 전화사기', 'icon': Icons.phone_outlined, 'level': '쉬움', 'isDone': true, 'rounds': 5},
      {'title': '투자사기', 'desc': '고수익 보장 가짜 투자', 'icon': Icons.trending_up, 'level': '보통', 'isDone': false, 'rounds': 0},
      {'title': '부동산사기', 'desc': '허위 매물 및 전세 사기', 'icon': Icons.domain_outlined, 'level': '어려움', 'isDone': false, 'rounds': 0},
      {'title': '대출사기', 'desc': '저금리 대출 빙자 사기', 'icon': Icons.account_balance_outlined, 'level': '보통', 'isDone': false, 'rounds': 0},
      {'title': '중고사기', 'desc': '입금 후 잠적하는 사기', 'icon': Icons.shopping_bag_outlined, 'level': '쉬움', 'isDone': false, 'rounds': 0},
      {'title': '랜덤', 'desc': '무작위 시나리오 실습', 'icon': Icons.shuffle, 'level': '변동', 'isDone': false, 'rounds': 0},
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 16.0),
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
                        child: const Icon(Icons.shield_outlined, color: primaryGreen, size: 24),
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
                        child: Icon(Icons.person, color: Colors.white, size: 22),
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
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double availableHeight = constraints.maxHeight;
                  final double availableWidth = constraints.maxWidth;
                  const double spacing = 18.0;
                  const double horizontalPadding = 24.0;
                  const double bottomPadding = 32.0;
                  final double itemWidth = (availableWidth - (horizontalPadding * 2) - spacing) / 2;
                  final double itemHeight = (availableHeight - bottomPadding - (spacing * 2)) / 3;
                  final double dynamicAspectRatio = itemWidth / itemHeight;
                  return Padding(
                    padding: const EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, bottom: bottomPadding),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: dynamicAspectRatio,
                      ),
                      itemCount: stages.length,
                      itemBuilder: (context, index) {
                        return _buildStageCard(
                          stages[index],
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

  Widget _buildStageCard(Map<String, dynamic> stage, Color cardColor, Color primaryGreen, Color subtitleColor, Color borderColor) {
    final bool isDone = stage['isDone'];
    final Color iconColor = isDone ? primaryGreen : Colors.white.withValues(alpha: 0.7);
    final Color iconBgColor = isDone ? const Color(0xFF072315) : borderColor.withValues(alpha: 0.5);
    final Color cardBorderColor = isDone ? primaryGreen.withValues(alpha: 0.5) : borderColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorderColor, width: isDone ? 1.5 : 1.0),
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
                  child: Icon(stage['icon'], color: iconColor, size: 26),
                ),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stage['title'],
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage['desc'],
                  style: TextStyle(color: subtitleColor, fontSize: 12, height: 1.2),
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
                          stage['level'],
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (isDone)
                          Text(
                            '완료',
                            style: TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    if (isDone) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.emoji_events_outlined, color: Colors.white.withValues(alpha: 0.8), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${stage['rounds']}라운드 클리어',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ]
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