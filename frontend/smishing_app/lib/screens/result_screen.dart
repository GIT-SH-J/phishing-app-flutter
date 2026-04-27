import 'package:flutter/material.dart';

import 'chatbot_screen.dart';

class ResultScreen extends StatelessWidget {
  final String inputText;
  final String sourceApp;
  final String messageText;
  final String detectedUrl;

  final String label;
  final double score;
  final String reason;
  final String action;

  final String? finalRiskGrade;
  final int? finalRiskScore;
  final List<Map<String, dynamic>> safeBrowsing;

  final bool? xgboostUsed;
  final double? xgboostScore;
  final String? xgboostVerdict;

  final bool? kcelectraUsed;
  final double? kcelectraScore;
  final String? kcelectraIntent;
  final String? kcelectraVerdict;

  final String? analyzedAt;
  final String? errorMessage;

  const ResultScreen({
    super.key,
    required this.inputText,
    required this.sourceApp,
    required this.messageText,
    required this.detectedUrl,
    required this.label,
    required this.score,
    required this.reason,
    required this.action,
    this.finalRiskGrade,
    this.finalRiskScore,
    this.safeBrowsing = const <Map<String, dynamic>>[],
    this.xgboostUsed,
    this.xgboostScore,
    this.xgboostVerdict,
    this.kcelectraUsed,
    this.kcelectraScore,
    this.kcelectraIntent,
    this.kcelectraVerdict,
    this.analyzedAt,
    this.errorMessage,
  });

  String get _gradeText => (finalRiskGrade ?? label).toUpperCase();

  Color get _gradeColor {
    switch (_gradeText) {
      case 'DANGER':
        return const Color(0xFFF44336);
      case 'SUSPICIOUS':
        return const Color(0xFFFF9800);
      case 'SAFE':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  IconData get _gradeIcon {
    switch (_gradeText) {
      case 'DANGER':
        return Icons.dangerous_outlined;
      case 'SUSPICIOUS':
        return Icons.warning_amber_outlined;
      case 'SAFE':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _formatSafeBrowsing() {
    if (safeBrowsing.isEmpty) return '-';
    return safeBrowsing.map((item) {
      final url = item['url']?.toString() ?? '-';
      final isMalicious = item['isMalicious'] == true;
      return '${isMalicious ? 'malicious' : 'safe'} ($url)';
    }).join('\n');
  }

  String _formatBool(bool? value) => value == null ? '-' : (value ? 'true' : 'false');

  String _formatDouble(double? value, {int fraction = 6}) {
    if (value == null) return '-';
    return value.toStringAsFixed(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskPercent = finalRiskScore?.toDouble() ?? score;

    Color bgColor;
    switch (_gradeText) {
      case 'DANGER':
        bgColor = isDark ? const Color(0xFF2D1515) : const Color(0xFFFFEBEE);
        break;
      case 'SUSPICIOUS':
        bgColor = isDark ? const Color(0xFF2D2510) : const Color(0xFFFFF3E0);
        break;
      case 'SAFE':
        bgColor = isDark ? const Color(0xFF152D1F) : const Color(0xFFE8F5E9);
        break;
      default:
        bgColor = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5);
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _gradeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_gradeIcon, size: 70, color: _gradeColor),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _gradeText,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _gradeColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '위험도 ${riskPercent.toInt()}%',
                  style: TextStyle(
                    fontSize: 20,
                    color: _gradeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ResultCard(
                title: '기본 정보',
                icon: Icons.text_snippet_outlined,
                isDark: isDark,
                rows: [
                  _row('앱/출처', sourceApp),
                  _row('본문', messageText.isEmpty ? inputText : messageText),
                  _row('URL', detectedUrl),
                  _row('최종 등급', _gradeText),
                  _row('최종 점수', finalRiskScore?.toString() ?? '-'),
                  _row('분석 시각', analyzedAt ?? '-'),
                ],
              ),
              const SizedBox(height: 14),
              _ResultCard(
                title: '탐지 상세',
                icon: Icons.security_outlined,
                isDark: isDark,
                rows: [
                  _row('Safe Browsing', _formatSafeBrowsing()),
                  _row('XGBoost used', _formatBool(xgboostUsed)),
                  _row('XGBoost score', _formatDouble(xgboostScore)),
                  _row('XGBoost verdict', xgboostVerdict ?? '-'),
                  _row('KcELECTRA used', _formatBool(kcelectraUsed)),
                  _row('KcELECTRA score', _formatDouble(kcelectraScore)),
                  _row('KcELECTRA intent', kcelectraIntent ?? '-'),
                  _row('KcELECTRA verdict', kcelectraVerdict ?? '-'),
                ],
              ),
              const SizedBox(height: 14),
              _ResultCard(
                title: '판단 및 대처',
                icon: Icons.info_outline,
                isDark: isDark,
                highlight: true,
                rows: [
                  _row('판단 이유', reason),
                  _row('대처 방법', action),
                  if (errorMessage != null && errorMessage!.isNotEmpty)
                    _row('에러 메시지', errorMessage!, color: Colors.red),
                ],
              ),
              const SizedBox(height: 24),
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
                              '검사 URL: $detectedUrl\n최종 등급: $_gradeText\n최종 점수: ${finalRiskScore ?? riskPercent.toInt()}\n판단 이유: $reason',
                          onBackHome: () => Navigator.pop(context),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            ],
          ),
        ),
      ),
    );
  }

  _ResultRow _row(String label, String value, {Color? color}) =>
      _ResultRow(label: label, value: value, color: color);
}

class _ResultRow {
  final String label;
  final String value;
  final Color? color;

  const _ResultRow({
    required this.label,
    required this.value,
    this.color,
  });
}

class _ResultCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool highlight;
  final bool isDark;
  final List<_ResultRow> rows;

  const _ResultCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.rows,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF1976D2).withValues(alpha: 0.12)
            : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? const Color(0xFF1976D2).withValues(alpha: 0.35)
              : isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
          const SizedBox(height: 10),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 128,
                  child: Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: row.color ??
                          (isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
