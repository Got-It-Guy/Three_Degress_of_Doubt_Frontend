import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
  final Random _random = Random();

  late final List<_ChatMessage> _messages;
  bool _isTyping = false;
  int _messageIdSeed = 1000;
  Timer? _pendingReplyTimer;
  _JudgmentType? _judgmentType;

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(
        id: 'initial',
        text: _initialMessageByStageId(widget.args.stageId),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _pendingReplyTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      return;
    }

    final userMessage = _ChatMessage(
      id: 'm${_messageIdSeed++}',
      text: input,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _inputController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    _pendingReplyTimer?.cancel();
    final delayMs = 1500 + _random.nextInt(1501);
    _pendingReplyTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) {
        return;
      }
      final reply = _ChatMessage(
        id: 'm${_messageIdSeed++}',
        text: _randomReply(),
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _isTyping = false;
        _messages.add(reply);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
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
                        color: isUser
                            ? outgoingBubbleColor
                            : incomingBubbleColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              color: isUser
                                  ? const Color(0xFF04330A)
                                  : Colors.white,
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

  String _timeLabel(DateTime time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  String _initialMessageByStageId(int stageId) {
    switch (stageId) {
      case 1:
        return '안녕하세요, 금융감독원입니다. 고객님 명의로 대포통장이 개설되어 연락드렸습니다.';
      case 2:
        return '안녕하세요! 저희 투자 그룹에서 월 30% 수익을 보장하는 특별한 기회가 있습니다.';
      case 3:
        return '안녕하세요. 급매 전세 매물이 나와서 안내드립니다. 오늘 안에 계약금 이체가 필요합니다.';
      case 4:
        return '정부지원 저금리 대출 승인 대상입니다. 선입금 수수료를 보내주시면 즉시 실행됩니다.';
      case 5:
        return '안녕하세요, 올려주신 상품 보고 연락드려요. 급하게 구해서 바로 입금 가능합니다!';
      case 6:
      default:
        return '안녕하세요, 국세청입니다. 환급금 지급을 위해 계좌 확인이 필요합니다.';
    }
  }

  String _randomReply() {
    const responses = [
      '네, 맞습니다. 빠른 처리를 위해 지금 바로 계좌 정보를 알려주시겠어요?',
      '걱정하지 마세요. 도와드릴게요. 본인 확인을 위해 주민번호를 알려주세요.',
      '지금 처리하지 않으면 법적 조치가 진행됩니다. 바로 진행하시죠.',
      '다른 분들은 이미 큰 수익을 얻고 계십니다. 기회를 놓치지 마세요.',
      '보안을 위해 이 번호로 전화 주시면 안전하게 처리해 드리겠습니다.',
    ];
    return responses[_random.nextInt(responses.length)];
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
                    setModalState(() {
                      _judgmentType = type;
                    });
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
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final canConfirm = _judgmentType != null;
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF09131E),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1E2B3D),
                    width: 1.1,
                  ),
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
                        onPressed: canConfirm
                            ? () => _confirmJudgment(dialogContext)
                            : null,
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

  void _confirmJudgment(BuildContext dialogContext) {
    final selected = _judgmentType;
    if (selected == null) {
      return;
    }

    if (selected == _JudgmentType.scam) {
      Navigator.pop(dialogContext);
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      return;
    }

    Navigator.pop(dialogContext);
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
