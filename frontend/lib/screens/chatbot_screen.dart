import 'package:flutter/material.dart';

class ChatBotScreen extends StatefulWidget {
  final String? initialMessage;
  final VoidCallback? onBackHome;

  const ChatBotScreen({super.key, this.initialMessage, this.onBackHome});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();

    _messages = [
      {
        'text':
            '안녕하세요.\n스미싱 대응 AI 챗봇입니다.\n의심 문자 대응, 신고 방법, 링크 클릭 후 조치 방법을 안내해드릴게요.',
        'isMe': false,
      },
    ];

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      _messages.add({'text': widget.initialMessage!, 'isMe': true});
      _messages.add({
        'text':
            '입력하신 내용을 확인했어요.\n스미싱 위험이 의심됩니다.\n\n'
            '1. 링크를 누르지 마세요.\n'
            '2. 발신 번호를 차단하세요.\n'
            '3. 개인정보 입력 여부를 확인하세요.\n'
            '4. 피해가 있었다면 118에 신고하세요.',
        'isMe': false,
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBackHome != null) {
      widget.onBackHome!();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final String text = _messageController.text.trim();

    setState(() {
      _messages.add({'text': text, 'isMe': true});
      _messages.add({'text': _getBotResponse(text), 'isMe': false});
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  String _getBotResponse(String input) {
    final String text = input.toLowerCase();

    if (text.contains('링크') || text.contains('눌렀')) {
      return '의심 링크는 절대 추가로 클릭하지 마세요.\n이미 눌렀다면 개인정보 입력 여부를 확인하고 비밀번호를 변경하세요.';
    } else if (text.contains('신고')) {
      return '스미싱이 의심되면 118(인터넷진흥원)에 신고할 수 있어요.\n금전 피해가 있으면 112 또는 금융기관에도 바로 연락하세요.';
    } else if (text.contains('문자') || text.contains('메시지')) {
      return '택배, 환급금, 청첩장, 계정정지 같은 문구와 함께 링크가 오면 스미싱일 가능성이 높아요.';
    } else {
      return '의심 문자 내용, 링크 클릭 여부, 개인정보 입력 여부를 알려주시면 더 구체적으로 안내해드릴게요.';
    }
  }

  void _addQuickMessage(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildQuickAction(String label, IconData icon) {
    return InkWell(
      onTap: () => _addQuickMessage(label),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB9D8FF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1565C0)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isMe = msg['isMe'] as bool;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1976D2) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(color: const Color(0xFFD9E6F5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                msg['text'] as String,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.55,
                  color: isMe ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF4F8FC),
          foregroundColor: Colors.black,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _handleBack,
          ),
          title: const Text(
            '스미싱 대응 AI 챗봇',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '보안 상담 활성화',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '의심 문자 대응, 신고 안내, 클릭 후 조치 방법을 빠르게 안내합니다.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickAction('링크를 눌렀어요', Icons.link_off),
                    _buildQuickAction('신고 방법 알려주세요', Icons.campaign_outlined),
                    _buildQuickAction('의심 문자 확인방법', Icons.sms_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD6E0EA)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(
                          fontSize: 15.5,
                          color: Color(0xFF0F172A),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '의심 문자 내용이나 궁금한 점을 입력하세요',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _sendMessage,
                    ),
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
