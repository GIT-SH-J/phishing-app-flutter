import 'package:flutter/material.dart';
import 'chatbot_screen.dart';

class ResultScreen extends StatelessWidget {
  final String inputText;
  final String label;
  final double score;
  final String reason;
  final String action;

  const ResultScreen({
    super.key,
    required this.inputText,
    required this.label,
    required this.score,
    required this.reason,
    required this.action,
  });

  Color get _labelColor {
    switch (label) {
      case '위험':
        return const Color(0xFFF44336);
      case '주의':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData get _labelIcon {
    switch (label) {
      case '위험':
        return Icons.dangerous_outlined;
      case '주의':
        return Icons.warning_amber_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 다크모드 색상 부드럽게 조정
    Color bgColor;
    switch (label) {
      case '위험':
        bgColor = isDark
            ? const Color(0xFF2D1515)
            : const Color(0xFFFFEBEE);
        break;
      case '주의':
        bgColor = isDark
            ? const Color(0xFF2D2510)
            : const Color(0xFFFFFDE7);
        break;
      default:
        bgColor = isDark
            ? const Color(0xFF152D1F)
            : const Color(0xFFE8F5E9);
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '검사 결과',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _labelColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_labelIcon, size: 70, color: _labelColor),
              ),
              const SizedBox(height: 24),
              Text(
                label,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '위험도 ${score.toInt()}%',
                style: TextStyle(
                  fontSize: 20,
                  color: _labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 16,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(_labelColor),
                ),
              ),
              const SizedBox(height: 32),
              _ResultCard(
                title: '검사한 내용',
                content: inputText,
                icon: Icons.text_snippet_outlined,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _ResultCard(
                title: '판단 이유',
                content: reason,
                icon: Icons.info_outline,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _ResultCard(
                title: '대처 방법',
                content: action,
                icon: Icons.shield_outlined,
                highlight: true,
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // AI 상담사 버튼 → 챗봇으로 이동하면서 내용 전달
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatBotScreen(
                          initialMessage:
                              '검사한 내용: $inputText\n판단 결과: $label ($score%)\n이유: $reason',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text(
                    'AI 상담사에게 물어보기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    side: BorderSide(
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '다시 검사하기',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final bool highlight;
  final bool isDark;

  const _ResultCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF1976D2).withOpacity(0.12)
            : isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: const Color(0xFF1976D2).withOpacity(0.4))
            : Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
              ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF1976D2)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 17,
              height: 1.6,
              color: isDark
                  ? Colors.white.withOpacity(0.87)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}