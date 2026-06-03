import 'package:flutter/material.dart';

class GameHelpScreen extends StatelessWidget {
  const GameHelpScreen({super.key});

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
                horizontal: 16,
                vertical: 12,
              ),
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
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '게임 방법',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: borderColor, thickness: 1, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF071D13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.36),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: primaryGreen,
                            size: 32,
                          ),
                          SizedBox(height: 14),
                          Text(
                            '사기인지, 정상 상황인지 판단하며\n스테이지를 클리어하세요.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '각 라운드는 대화형 시뮬레이션으로 진행되며, 올바른 판단을 연속으로 쌓는 것이 핵심입니다.',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _HelpSection(
                      number: '01',
                      title: '스테이지 클리어 방법',
                      children: const [
                        '라운드를 3번 연속으로 클리어하면 해당 스테이지가 클리어됩니다.',
                        '도중에 라운드를 실패하거나 경고 누적으로 진행도가 초기화되면, 다시 3번 연속 클리어해야 합니다.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _HelpSection(
                      number: '02',
                      title: '각 라운드 진행 흐름',
                      children: const [
                        '라운드에 입장하면 선택한 테마에 맞는 시나리오가 주어집니다.',
                        '시나리오는 사기 또는 정상 상황 중 하나로 같은 확률로 배정됩니다.',
                        '사기 징후가 보이면 대화 중간에 사기 판정을 할 수 있습니다.',
                        '판정이 맞으면 라운드가 클리어되고, 틀리면 경고가 1회 누적됩니다.',
                        '정상 시나리오는 무사히 대화를 끝까지 마쳐야 클리어됩니다.',
                        '사기 시나리오를 끝까지 진행하면 경고가 1회 누적되고 다음 라운드로 넘어갑니다. 이 동작은 추후 패치될 예정입니다.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _HelpSection(
                      number: '03',
                      title: '점수 기록',
                      children: const [
                        '홈 화면의 점수는 스테이지를 얼마나 적은 라운드로 클리어했는지에 대한 기록입니다.',
                        '빠르게 클리어할수록 더 좋은 기록으로 남습니다.',
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.number,
    required this.title,
    required this.children,
  });

  final String number;
  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF111A24);
    const primaryGreen = Color(0xFF00D64F);
    const subtitleColor = Color(0xFF9AA4B2);
    const borderColor = Color(0xFF223042);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.38),
                  ),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final item in children) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
