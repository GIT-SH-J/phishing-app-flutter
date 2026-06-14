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

  final String? llmResponseGuide;

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
    this.llmResponseGuide,
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

  String _replaceEnglishGrades(String text) {
    return text
        .replaceAll(RegExp(r'suspicious', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'suspious', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'warning', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'caution', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'safe', caseSensitive: false), '안전')
        .replaceAll(RegExp(r'success', caseSensitive: false), '안전')
        .replaceAll(RegExp(r'danger', caseSensitive: false), '위험')
        .replaceAll(RegExp(r'risk', caseSensitive: false), '위험')
        .replaceAll(RegExp(r'malicious', caseSensitive: false), '위험');
  }

  String get _gradeText {
    final grade = (finalRiskGrade ?? label).trim().toUpperCase();

    switch (grade) {
      case 'SAFE':
      case 'SUCCESS':
        return '안전';
      case 'SUSPICIOUS':
      case 'SUSPIOUS':
      case 'WARNING':
      case 'CAUTION':
        return '주의';
      case 'DANGER':
      case 'RISK':
      case 'MALICIOUS':
        return '위험';
      default:
        return _replaceEnglishGrades(grade);
    }
  }

  String _toKoreanGrade(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    final grade = value.trim().toUpperCase();

    switch (grade) {
      case 'SAFE':
      case 'SUCCESS':
        return '안전';
      case 'SUSPICIOUS':
      case 'SUSPIOUS':
      case 'WARNING':
      case 'CAUTION':
        return '주의';
      case 'DANGER':
      case 'RISK':
      case 'MALICIOUS':
        return '위험';
      default:
        return _replaceEnglishGrades(value);
    }
  }

  Color get _gradeColor {
    switch (_gradeText) {
      case '위험':
        return const Color(0xFFE53935);
      case '주의':
        return const Color(0xFFFF7A00);
      case '안전':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData get _gradeIcon {
    switch (_gradeText) {
      case '위험':
        return Icons.dangerous_outlined;
      case '주의':
        return Icons.warning_amber_rounded;
      case '안전':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String get _shortSummary {
    switch (_gradeText) {
      case '위험':
        return '스미싱 의심 요소가 발견되었습니다.\n'
            '링크 클릭 및 개인정보 입력에 주의하세요.\n'
            '자세한 내용은 AI 상세 분석 보기에서 확인하세요.';

      case '주의':
        return '주의가 필요한 메시지입니다.\n'
            '발신자 및 링크 정보를 한 번 더 확인하세요.\n'
            '자세한 내용은 AI 상세 분석 보기에서 확인하세요.';

      case '안전':
        return '현재 검사 결과 위험 요소가 발견되지 않았습니다.\n'
            '안전한 메시지로 판단됩니다.\n'
            '자세한 내용은 AI 상세 분석 보기에서 확인하세요.';

      default:
        return '메시지 분석이 완료되었습니다.';
    }
  }

  String _formatSafeBrowsing() {
    if (safeBrowsing.isEmpty) return '-';

    return safeBrowsing.map((item) {
      final url = item['url']?.toString() ?? '-';
      final isMalicious = item['isMalicious'] == true;
      return '${isMalicious ? '위험' : '안전'} ($url)';
    }).join('\n');
  }

  String _formatBool(bool? value) {
    if (value == null) return '-';
    return value ? '사용됨' : '사용 안 됨';
  }

  String _formatDouble(double? value, {int fraction = 6}) {
    if (value == null) return '-';
    return value.toStringAsFixed(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final riskPercent = finalRiskScore?.toDouble() ?? score;
    final guideText = llmResponseGuide?.trim();
    final koreanGuideText =
        guideText == null ? null : _replaceEnglishGrades(guideText);

    const bgColor = Color(0xFFF7FBFF);
    const mainBlue = Color(0xFF1976D2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '검사 결과',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _gradeIcon,
                size: 82,
                color: _gradeColor,
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  _gradeText,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: _gradeColor,
                    letterSpacing: 0.4,
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SimpleCard(
                title: '판단 요약',
                icon: Icons.info_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shortSummary,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.65,
                        color: Colors.black87,
                      ),
                    ),
                    if (koreanGuideText != null &&
                        koreanGuideText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _AiDetailBox(content: koreanGuideText),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SimpleCard(
                title: '기본 정보',
                icon: Icons.description_outlined,
                child: Column(
                  children: [
                    _InfoRow(
                      '입력 방식',
                      sourceApp.isEmpty ? '직접 입력' : sourceApp,
                    ),
                    _InfoRow(
                      '분류',
                      kcelectraIntent == null
                          ? '-'
                          : _replaceEnglishGrades(kcelectraIntent!),
                    ),
                    _InfoRow('판정', _gradeText, valueColor: _gradeColor),
                    _InfoRow(
                      '최종 점수',
                      finalRiskScore?.toString() ??
                          riskPercent.toInt().toString(),
                    ),
                    _InfoRow('분석 시간', analyzedAt ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SimpleCard(
                title: '탐지 정보',
                icon: Icons.shield_outlined,
                child: Column(
                  children: [
                    _InfoRow(
                      '탐지 엔진',
                      kcelectraUsed == true ? 'KcELECTRA' : '-',
                    ),
                    _InfoRow('점수', _formatDouble(kcelectraScore)),
                    _InfoRow(
                      '의도',
                      kcelectraIntent == null
                          ? '-'
                          : _replaceEnglishGrades(kcelectraIntent!),
                    ),
                    _InfoRow(
                      '판정',
                      _toKoreanGrade(kcelectraVerdict ?? _gradeText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatBotScreen(
                          initialMessage: '검사 URL: $detectedUrl\n'
                              '최종 등급: $_gradeText\n'
                              '최종 점수: ${finalRiskScore ?? riskPercent.toInt()}\n'
                              '판단 이유: ${_replaceEnglishGrades(reason)}\n'
                              '${koreanGuideText != null && koreanGuideText.isNotEmpty ? '상세 경고문: $koreanGuideText' : ''}',
                          onBackHome: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'AI 상담사에게 물어보기',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mainBlue,
                    side: const BorderSide(color: mainBlue, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '다시 검사하기',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  '궁금한 점이 있다면 AI 상담사에게 물어보세요.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _HiddenDetail(
                title: '고급 탐지 정보',
                content: 'Safe Browsing: ${_formatSafeBrowsing()}\n'
                    'XGBoost 사용 여부: ${_formatBool(xgboostUsed)}\n'
                    'XGBoost 점수: ${_formatDouble(xgboostScore)}\n'
                    'XGBoost 판정: ${_toKoreanGrade(xgboostVerdict)}\n'
                    'KcELECTRA 사용 여부: ${_formatBool(kcelectraUsed)}\n'
                    'KcELECTRA 점수: ${_formatDouble(kcelectraScore)}\n'
                    'KcELECTRA 의도: ${kcelectraIntent == null ? '-' : _replaceEnglishGrades(kcelectraIntent!)}\n'
                    'KcELECTRA 판정: ${_toKoreanGrade(kcelectraVerdict)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SimpleCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF1976D2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 23, color: mainBlue),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(
    this.label,
    this.value, {
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: valueColor ?? Colors.black87,
                fontWeight:
                    valueColor == null ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiDetailBox extends StatelessWidget {
  final String content;

  const _AiDetailBox({
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE3EEF9),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        leading: const Icon(
          Icons.smart_toy_outlined,
          color: Color(0xFF1976D2),
        ),
        iconColor: const Color(0xFF1976D2),
        collapsedIconColor: const Color(0xFF1976D2),
        title: const Text(
          'AI 상세 분석 보기',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1976D2),
          ),
        ),
        subtitle: const Text(
          'OpenAI 분석 내용을 펼쳐서 확인할 수 있어요.',
          style: TextStyle(
            fontSize: 12.5,
            color: Colors.black54,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenDetail extends StatelessWidget {
  final String title;
  final String content;

  const _HiddenDetail({
    required this.title,
    required this.content,
  });

  String _replaceEnglishGrades(String text) {
    return text
        .replaceAll(RegExp(r'suspicious', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'suspious', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'warning', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'caution', caseSensitive: false), '주의')
        .replaceAll(RegExp(r'safe', caseSensitive: false), '안전')
        .replaceAll(RegExp(r'success', caseSensitive: false), '안전')
        .replaceAll(RegExp(r'danger', caseSensitive: false), '위험')
        .replaceAll(RegExp(r'risk', caseSensitive: false), '위험')
        .replaceAll(RegExp(r'malicious', caseSensitive: false), '위험');
  }

  @override
  Widget build(BuildContext context) {
    final koreanContent = _replaceEnglishGrades(content);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          color: Colors.black45,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            koreanContent,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
