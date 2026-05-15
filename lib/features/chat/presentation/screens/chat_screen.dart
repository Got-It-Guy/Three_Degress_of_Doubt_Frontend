import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:three_degress_of_doubt_frontend/core/di/app_dependencies.dart';
import 'package:three_degress_of_doubt_frontend/features/chat/data/chat_repository.dart';

class ChatScreenArgs {
  const ChatScreenArgs({required this.stageId, required this.stageTitle});

  final int stageId;
  final String stageTitle;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.args});

  final ChatScreenArgs args;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepository = AppDependencies.chatRepository;

  final List<_ChatMessage> _messages = <_ChatMessage>[];

  late _ScenarioIntroData _scenarioIntroData;
  String? _roundId;
  String? _pendingInitialAiMessageId;
  String? _pendingInitialAiMessage;
  bool _isTyping = false;
  bool _isRoundInitializing = false;
  _JudgmentType? _judgmentType;

  @override
  void initState() {
    super.initState();
    _scenarioIntroData = _scenarioDataByStageId(widget.args.stageId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareRoundAndShowScenarioModal();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _prepareRoundAndShowScenarioModal() async {
    if (!mounted || _isRoundInitializing) return;

    setState(() => _isRoundInitializing = true);

    final token = await _resolveIdToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _isRoundInitializing = false);
      _showSnack('인증 토큰을 확인할 수 없습니다.');
      return;
    }

    try {
      debugPrint('[StageFlow] enter->rounds, stage_id=${widget.args.stageId}');
      final roundResult = await _chatRepository.createRound(
        stageId: widget.args.stageId,
        idToken: token,
      );

      final fetched = await _chatRepository.fetchMessages(
        roundId: roundResult.roundId,
        idToken: token,
      );

      final promptSummary = _buildScenarioSummaryFromPrompt(
        roundResult.situationPrompt,
      );

      final initialFromRound = roundResult.initialMessage;
      final firstAi = fetched
          .where((m) => m.role != 'user' && m.content.trim().isNotEmpty)
          .map((m) => m.content.trim())
          .cast<String?>()
          .firstWhere((e) => e != null, orElse: () => null);

      if (!mounted) return;
      setState(() {
        _roundId = roundResult.roundId;
        _pendingInitialAiMessageId = initialFromRound?.messageId;
        _pendingInitialAiMessage =
            initialFromRound?.content.trim().isNotEmpty == true
            ? initialFromRound!.content.trim()
            : (firstAi ?? _scenarioIntroData.firstAiMessage);
        _scenarioIntroData = _scenarioIntroData.copyWith(
          title: widget.args.stageTitle,
          scenarioSummary: promptSummary.isEmpty
              ? _scenarioIntroData.scenarioSummary
              : promptSummary,
        );
        _isRoundInitializing = false;
      });

      await _showScenarioIntroModal();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRoundInitializing = false);
      _showSnack('라운드 초기화 중 오류가 발생했습니다.');
    }
  }

  Future<void> _sendMessage() async {
    final input = _inputController.text.trim();
    if (input.isEmpty || _isRoundInitializing) return;
    if (_roundId == null) {
      _showSnack('라운드가 준비되지 않았습니다.');
      return;
    }

    final token = await _resolveIdToken();
    if (token == null || token.isEmpty) {
      _showSnack('인증 토큰을 확인할 수 없습니다.');
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          id: 'user-${DateTime.now().microsecondsSinceEpoch}',
          text: input,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _inputController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final result = await _chatRepository.sendMessage(
        roundId: _roundId!,
        content: input,
        idToken: token,
      );

      final fetched = await _chatRepository.fetchMessages(
        roundId: _roundId!,
        idToken: token,
      );

      if (!mounted) return;
      final mapped = fetched.map(_fromDto).toList();
      if (mapped.isNotEmpty) {
        setState(() {
          _messages
            ..clear()
            ..addAll(mapped);
          _isTyping = false;
        });
      } else {
        final fallbackAi = result.messages.isNotEmpty
            ? _fromDto(result.messages.first)
            : _ChatMessage(
                id: 'ai-${DateTime.now().microsecondsSinceEpoch}',
                text: '응답을 가져오지 못했습니다.',
                isUser: false,
                timestamp: DateTime.now(),
              );
        setState(() {
          _messages.add(fallbackAi);
          _isTyping = false;
        });
      }
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _showSnack('메시지 전송 중 오류: $error');
    }
  }

  Future<void> _showScenarioIntroModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF09131E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E2B3D), width: 1.1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _scenarioIntroData.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _buildIntroSection('상대방 정보', _scenarioIntroData.counterpartInfo),
                const SizedBox(height: 10),
                _buildIntroSection('시나리오 설명', _scenarioIntroData.scenarioSummary),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _appendInitialAiMessage();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B7A33),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroSection(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A121D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3647), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA6B1BD),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _appendInitialAiMessage() {
    if (!mounted) return;
    final text =
        (_pendingInitialAiMessage ?? _scenarioIntroData.firstAiMessage).trim();
    if (text.isEmpty) return;

    final id =
        (_pendingInitialAiMessageId != null &&
            _pendingInitialAiMessageId!.trim().isNotEmpty)
        ? _pendingInitialAiMessageId!.trim()
        : 'initial-${DateTime.now().microsecondsSinceEpoch}';
    final alreadyExists = _messages.any((m) => m.id == id);
    if (alreadyExists) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          id: id,
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _showJudgmentModal() async {
    _judgmentType = null;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildChoice({
              required _JudgmentType type,
              required String label,
              required IconData icon,
            }) {
              final selected = _judgmentType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setModalState(() => _judgmentType = type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    height: 104,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0x0F00D64F)
                          : const Color(0xFF0A121D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF00D64F)
                            : const Color(0xFF2A3647),
                        width: selected ? 1.6 : 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 22,
                          color: selected
                              ? const Color(0xFF00D64F)
                              : const Color(0xFFA6B1BD),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF00D64F)
                                : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF09131E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E2B3D), width: 1.1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '이 대화는...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          splashRadius: 18,
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFFB2BCC8),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        buildChoice(
                          type: _JudgmentType.scam,
                          label: '사기',
                          icon: Icons.gpp_bad_outlined,
                        ),
                        const SizedBox(width: 10),
                        buildChoice(
                          type: _JudgmentType.unknown,
                          label: '모름',
                          icon: Icons.gpp_maybe_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _judgmentType == null
                            ? null
                            : () => _confirmJudgment(dialogContext),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(0xFF19412B),
                          backgroundColor: const Color(0xFF0B7A33),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmJudgment(BuildContext dialogContext) async {
    final selected = _judgmentType;
    if (selected == null) return;

    if (selected == _JudgmentType.scam) {
      if (_roundId == null) {
        _showSnack('라운드 정보가 없습니다.');
        return;
      }
      final token = await _resolveIdToken();
      if (token == null || token.isEmpty) {
        _showSnack('인증 토큰을 확인할 수 없습니다.');
        return;
      }
      try {
        await _chatRepository.judgeRound(
          roundId: _roundId!,
          isFraudJudged: true,
          idToken: token,
        );
      } catch (error) {
        _showSnack('판정 제출 실패: $error');
        return;
      }

      if (!mounted || !dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      return;
    }

    Navigator.pop(dialogContext);
  }

  Future<String?> _resolveIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.getIdToken();
  }

  _ChatMessage _fromDto(ChatMessageDto dto) {
    return _ChatMessage(
      id: dto.messageId ?? 'msg-${DateTime.now().microsecondsSinceEpoch}',
      text: dto.content,
      isUser: dto.role == 'user',
      timestamp: dto.createdAt,
    );
  }

  String _buildScenarioSummaryFromPrompt(SituationPromptDto? prompt) {
    if (prompt == null) return '';
    final lines = <String>[];
    if (prompt.situation.trim().isNotEmpty) {
      lines.add('상황: ${prompt.situation.trim()}');
    }
    if (prompt.currentStage.trim().isNotEmpty) {
      lines.add('현재 단계: ${prompt.currentStage.trim()}');
    }
    if (prompt.userIntent.trim().isNotEmpty) {
      lines.add('의도: ${prompt.userIntent.trim()}');
    }
    return lines.join('\n');
  }

  _ScenarioIntroData _scenarioDataByStageId(int stageId) {
    switch (stageId) {
      case 1:
        return const _ScenarioIntroData(
          title: '보이스피싱',
          counterpartInfo: '김민수 수사관 (금융감독원 사칭)',
          scenarioSummary: '금융기관을 사칭해 계좌가 범죄에 연루됐다고 압박하며 개인정보와 자금 이체를 유도합니다.',
          firstAiMessage: '안녕하세요, 금융감독원입니다. 고객님 명의로 대포통장이 개설되어 연락드렸습니다.',
        );
      case 2:
        return const _ScenarioIntroData(
          title: '투자사기',
          counterpartInfo: '박도윤 팀장 (투자리딩방 운영자)',
          scenarioSummary: '단기간 고수익을 보장한다고 접근하고, 급하게 입금을 유도한 뒤 추가 입금을 반복 요구합니다.',
          firstAiMessage: '안녕하세요! 저희 투자 그룹에서 월 30% 수익을 보장하는 특별한 기회가 있습니다.',
        );
      case 3:
        return const _ScenarioIntroData(
          title: '부동산사기',
          counterpartInfo: '김철수 공인중개사',
          scenarioSummary: '실제와 다른 매물 정보로 신뢰를 만든 후 계약금 선이체를 유도해 금전 피해를 노립니다.',
          firstAiMessage: '안녕하세요. 급매 전세 매물이 나와서 안내드립니다. 오늘 안에 계약금 이체가 필요합니다.',
        );
      case 4:
        return const _ScenarioIntroData(
          title: '대출사기',
          counterpartInfo: '이재훈 상담사 (정책금융기관 사칭)',
          scenarioSummary: '저금리 대출 승인 대상이라며 접근해 보증료·수수료 명목의 선입금을 요구합니다.',
          firstAiMessage: '정부지원 저금리 대출 승인 대상입니다. 선입금 수수료를 보내주시면 즉시 실행됩니다.',
        );
      case 5:
        return const _ScenarioIntroData(
          title: '중고사기',
          counterpartInfo: '최유진 구매자',
          scenarioSummary: '급히 거래하겠다며 신뢰를 유도하고, 안전결제 링크나 환불 명목으로 추가 정보를 요구합니다.',
          firstAiMessage: '안녕하세요, 올려주신 상품 보고 연락드려요. 급하게 구해서 바로 입금 가능합니다!',
        );
      case 6:
      default:
        return const _ScenarioIntroData(
          title: '랜덤',
          counterpartInfo: '정우성 담당자 (기관 사칭)',
          scenarioSummary: '공공기관을 사칭해 환급, 지원금, 조사 등을 빌미로 개인정보 입력 또는 송금을 유도합니다.',
          firstAiMessage: '안녕하세요, 국세청입니다. 환급금 지급을 위해 계좌 확인이 필요합니다.',
        );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _timeLabel(DateTime time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF020911);
    const headerColor = Color(0xFF09141F);
    const borderColor = Color(0xFF1A2635);
    const incomingBubbleColor = Color(0xFF1D2733);
    const outgoingBubbleColor = Color(0xFF00D64F);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: headerColor,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.args.stageTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '상대방과 대화 중',
                          style: TextStyle(
                            color: Color(0xFF94A1AF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showJudgmentModal,
                    icon: const Icon(Icons.pause, size: 16),
                    label: const Text('판정'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: outgoingBubbleColor,
                      side: const BorderSide(color: outgoingBubbleColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  final message = _messages[index];
                  final isUser = message.isUser;

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.74,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? outgoingBubbleColor : incomingBubbleColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              color: isUser ? const Color(0xFF04330A) : Colors.white,
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _timeLabel(message.timestamp),
                            style: TextStyle(
                              color: isUser
                                  ? const Color(0xFF0F6620)
                                  : const Color(0xFF8A98A8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: headerColor,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF151F2A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          hintText: '메시지를 입력하세요...',
                          hintStyle: TextStyle(
                            color: Color(0xFF6B7888),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ListenableBuilder(
                    listenable: _inputController,
                    builder: (context, _) {
                      final enabled = _inputController.text.trim().isNotEmpty;
                      return Material(
                        color: enabled
                            ? outgoingBubbleColor
                            : outgoingBubbleColor.withValues(alpha: 0.45),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: enabled ? _sendMessage : null,
                          child: const SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(
                              Icons.send_rounded,
                              color: Color(0xFF04330A),
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bubbleColor = Color(0xFF1D2733);
    const dotColor = Color(0xFF7D8A99);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final value = ((_controller.value - (index * 0.18)) % 1.0)
                    .clamp(0.0, 1.0);
                final scale = 0.75 + (sin(value * pi * 2).abs() * 0.35);
                return Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
                  child: Transform.scale(
                    scale: scale,
                    child: const Icon(Icons.circle, size: 8, color: dotColor),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
}

enum _JudgmentType { scam, unknown }

class _ScenarioIntroData {
  const _ScenarioIntroData({
    required this.title,
    required this.counterpartInfo,
    required this.scenarioSummary,
    required this.firstAiMessage,
  });

  final String title;
  final String counterpartInfo;
  final String scenarioSummary;
  final String firstAiMessage;

  _ScenarioIntroData copyWith({
    String? title,
    String? counterpartInfo,
    String? scenarioSummary,
    String? firstAiMessage,
  }) {
    return _ScenarioIntroData(
      title: title ?? this.title,
      counterpartInfo: counterpartInfo ?? this.counterpartInfo,
      scenarioSummary: scenarioSummary ?? this.scenarioSummary,
      firstAiMessage: firstAiMessage ?? this.firstAiMessage,
    );
  }
}
