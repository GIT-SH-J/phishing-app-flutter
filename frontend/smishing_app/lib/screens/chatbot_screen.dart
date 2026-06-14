import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  bool _isLoading = false;

  static const String _openAiApiKey = '_여기에 api키를 입력하세요_';

  @override
  void initState() {
    super.initState();

    _messages = [
      {
        'text': '안녕하세요. 스미싱 탐지기 AI 보안 상담사입니다. 무엇이든 편하게 물어보세요.',
        'isMe': false,
      },
    ];

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      _messages.add({'text': widget.initialMessage!, 'isMe': true});

      Future.delayed(Duration.zero, () {
        _sendInitialMessage(widget.initialMessage!);
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
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<String> _getAiResponse(String message) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_openAiApiKey', 
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', 
          'messages': [
            {
              'role': 'system',
              'content': '''
[ROLE] 스마트폰 보안 전문 한국어 AI assistant.
[TONE] 이모지(🔒, 🛡️, 🚨 등)를 적절히 활용하여 친구처럼 친근하고 명확한 '해요체(~해요, ~하세요)'로 답변. 기계적인 매뉴얼 복사/붙여넣기를 절대 피하고, 사용자가 처한 상황에 맞춰 사람처럼 유연하게 컨설팅할 것.

[상황별 답변 로직]
1. 일상적인 인사나 질문: 
   ➔ 불필요한 매뉴얼을 꺼내지 말고 가볍게 인사만 나눈다.

2. 사용자가 앱의 '검사 결과(주의, 위험, 상세 경고문 등)'를 복사해 오거나 특정 텍스트를 보여주는 경우:
   ➔ 앵무새처럼 고정된 매뉴얼을 나열하지 말 것!
   ➔ 먼저 사용자가 가져온 내용(예: 사칭 가능성, 공포심 유발 등)을 바탕으로 "이 문자가 왜 위험한지" 1~2줄로 알기 쉽게 공감하며 분석해 줄 것.
   ➔ 그 후, "따라서 고객님 상황에서는 아래 조치가 가장 필요해요"라며 상황에 딱 맞는 맞춤형 대처법을 제시할 것.

3. 사용자가 "링크를 이미 눌렀어!", "돈이 결제됐대!" 등 긴급 상황을 호소하는 경우:
   ➔ 즉시 안심시킨 뒤, 아래의 핵심 행동 가이드를 조합하여 신속한 조치를 유도할 것.

[핵심 행동 가이드 (상황에 맞게 변형 및 발췌하여 자연스럽게 안내할 것)]
- 링크 클릭 금지/대처: "절대 URL을 누르지 마세요! 이미 눌렀다면 당황하지 말고 즉시 스마트폰을 비행기 모드(✈️)로 바꿔서 인터넷을 끊어야 해요."
- 공식 채널 확인: "문자에 적힌 번호로 절대 전화하지 마시고, 공식 앱이나 홈페이지를 통해 직접 확인해 보세요."
- 백신 검사: "혹시 모르니 V3 Mobile Plus나 알약M 같은 백신 앱으로 정밀 검사를 한 번 돌려보는 걸 추천해요."
- 차단 및 신고: "해당 번호는 꼭 스팸 차단하시고, KISA(118)나 시티즌코난 앱으로 신고하시면 안전합니다."
'''
            },
            ..._messages.map((msg) => {
              'role': msg['isMe'] ? 'user' : 'assistant',
              'content': msg['text'].toString(),
            }),
          ],
          'temperature': 0.6, 
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final text = data['choices']?[0]?['message']?['content'];

        if (text != null && text.toString().trim().isNotEmpty) {
          return text.toString().trim();
        }
        return '답변이 비어 있어요. 다시 입력해주세요.';
      } else {
        return 'OpenAI API 오류가 발생했어요.\n상태 코드: ${response.statusCode}\n응답 내용: ${response.body}';
      }
    } catch (e) {
      return '네트워크 오류가 발생했어요.\n$e';
    }
  }

  Future<void> _sendInitialMessage(String text) async {
    setState(() {
      _isLoading = true;
    });

    final aiReply = await _getAiResponse(text);

    setState(() {
      _messages.add({'text': aiReply, 'isMe': false});
      _isLoading = false;
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final String text = _messageController.text.trim();

    setState(() {
      _messages.add({'text': text, 'isMe': true});
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    final String aiReply = await _getAiResponse(text);

    setState(() {
      _messages.add({'text': aiReply, 'isMe': false});
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _addQuickMessage(String text) {
    if (_isLoading) return;
    _messageController.text = text;
    _sendMessage();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildKbQuickButton(String title) {
    return InkWell(
      onTap: () => _addQuickMessage(title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 10,
                child: Container(color: const Color(0xFFFFE066).withOpacity(0.7)),
              ),
              const Text(
                '오늘의 보안 소식',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '가장 많이 찾는 대처법을 모아왔어요.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          _buildKbQuickButton('링크를 실수로 눌렀어요'),
          _buildKbQuickButton('KISA 및 112 신고 방법'),
          _buildKbQuickButton('의심스러운 문자 확인해줘'),
        ],
      ),
    );
  }

  Widget _buildQuickKeywordChip(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _addQuickMessage(title),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD9E6F5)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickKeywordsRow() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildQuickKeywordChip('링크를 실수로 눌렀어요'),
          _buildQuickKeywordChip('KISA 및 112 신고 방법'),
          _buildQuickKeywordChip('의심스러운 문자 확인해줘'),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isMe = msg['isMe'] as bool;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                Icons.smart_toy_rounded,
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
                border:
                isMe ? null : Border.all(color: const Color(0xFFD9E6F5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9E6F5)),
            ),
            child: const Text(
              '답변을 생성하고 있어요...',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
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
            'AI 챗봇',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        resizeToAvoidBottomInset: true,
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
                        Icons.smart_toy_rounded,
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
                            'AI 상담 활성화',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'AI가 상담을 도와드립니다.',
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
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  ..._messages.map((msg) => _buildMessageBubble(msg)),
                  if (_isLoading) _buildLoadingBubble(),
                  if (_messages.length == 1 && !_isLoading)
                    _buildRecommendationCard(),
                ],
              ),
            ),
            
            if (_messages.length > 1) 
              _buildQuickKeywordsRow(),

            const SizedBox(height: 10),
            SafeArea(
              top: false,
              child: Container(
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
                          enabled: !_isLoading,
                          style: const TextStyle(
                            fontSize: 15.5,
                            color: Color(0xFF0F172A),
                          ),
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: '무엇이든 물어보세요',
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
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
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
