import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import 'result_screen.dart';
import 'login_screen.dart';
import '../models/scan_history.dart';
import '../services/history_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  final PageController _pageController = PageController();
  Timer? _bannerTimer;
  int _currentPage = 0;

  final GlobalKey _helpIconKey = GlobalKey();
  OverlayEntry? _guideOverlay;

  final List<String> _noticeMessages = [
    '“택배 주소 확인”, “정부지원금”, “계정 정지” 문구가 포함된 문자를 주의하세요.',
    '출처가 불분명한 단축 URL(bit.ly 등)은 클릭 전 반드시 확인하세요.',
    '가족, 기관, 은행을 사칭하며 링크 클릭을 유도하는 문자가 증가하고 있어요.',
    '앱 설치를 유도하거나 개인정보 입력을 요구하는 문자는 특히 조심하세요.',
  ];

  List<ScanHistory> _recentHistory = [];

  @override
  void initState() {
    super.initState();
    _startBannerAutoSlide();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await HistoryService.getHistory();

    if (!mounted) return;

    setState(() {
      _recentHistory = data;
    });
  }

  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_pageController.hasClients) return;

      _currentPage++;
      if (_currentPage >= _noticeMessages.length) {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showNoticeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Color(0xFF1976D2), size: 22),
              SizedBox(width: 8),
              Text(
                '공지사항',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '닫기',
                style: TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeGuideOverlay() {
    _guideOverlay?.remove();
    _guideOverlay = null;
  }

  void _toggleGuideOverlay() {
    if (_guideOverlay != null) {
      _removeGuideOverlay();
      return;
    }

    final renderBox =
        _helpIconKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null) return;

    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;
    final screenWidth = MediaQuery.of(context).size.width;

    const double bubbleWidth = 280;
    const double horizontalMargin = 16;

    double left = offset.dx - bubbleWidth + size.width;
    if (left < horizontalMargin) {
      left = horizontalMargin;
    }
    if (left + bubbleWidth > screenWidth - horizontalMargin) {
      left = screenWidth - bubbleWidth - horizontalMargin;
    }

    _guideOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeGuideOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: offset.dy + size.height + 12,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: bubbleWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD6E9FF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF1976D2),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '입력 안내',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '의심되는 문자나 주소를 아래 입력창에 붙여넣어 주세요.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    if (!appState.isLoggedIn) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '비회원은 3회까지 검사할 수 있어요.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_guideOverlay!);
  }

  Future<void> _handleSearch() async {
    final inputText = _inputController.text.trim();

    if (inputText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('문자 또는 주소를 입력해주세요')));
      return;
    }

    if (!appState.isLoggedIn) {
      if (!appState.canUseGuestScan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비회원은 3회까지만 검사할 수 있어요. 로그인 후 계속 이용해주세요.'),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      appState.increaseGuestScan();
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    final String resultLabel = '위험';
    final double score = 85.0;
    final String reason = '의심스러운 URL과 키워드가 포함되어 있습니다.';
    final String action = '해당 링크를 클릭하지 마시고 발신자를 확인하세요.';

    final history = ScanHistory(
      url: inputText,
      result: resultLabel,
      checkedAt: DateTime.now().toString(),
    );

    await HistoryService.saveHistory(history);
    await _loadHistory();

    if (!mounted) return;

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          inputText: inputText,
          label: resultLabel,
          score: score,
          reason: reason,
          action: action,
        ),
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    await HistoryService.clearHistory();
    await _loadHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('검사 기록이 모두 삭제되었습니다.')));
  }

  Color _getResultColor(String result) {
    switch (result) {
      case '위험':
        return const Color(0xFFF44336);
      case '주의':
        return const Color(0xFFFFC107);
      case '안전':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _pageController.dispose();
    _bannerTimer?.cancel();
    _removeGuideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int remainingCount = appState.remainingScanCount < 0
        ? 0
        : appState.remainingScanCount;
    final int usedCount = 3 - remainingCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: SizedBox(
          height: 76,
          width: MediaQuery.of(context).size.width * 0.55,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showNoticeDialog(_noticeMessages[_currentPage]);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBDEFB)),
                      ),
                      child: SizedBox(
                        height: 34,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.campaign_rounded,
                              color: Color(0xFF1976D2),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '공지사항',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _noticeMessages.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _noticeMessages[index],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 42),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '문자 또는 주소 입력',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        key: _helpIconKey,
                        onTap: _toggleGuideOverlay,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.question_answer_rounded,
                            size: 18,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: _inputController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: '예) 택배 미수령 안내입니다. 확인하세요.\nhttps://example.com',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFBDBDBD),
                        height: 1.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1976D2),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (!appState.isLoggedIn)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '남은 검사 횟수 $usedCount/3회',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 28),
                      label: const Text(
                        '검사하기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 46),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '최근 검사 기록',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_recentHistory.isNotEmpty)
                        TextButton(
                          onPressed: _clearAllHistory,
                          child: const Text(
                            '전체 삭제',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (_recentHistory.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE3EAF3)),
                      ),
                      child: const Text(
                        '최근 검사 기록이 없습니다.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    )
                  else
                    ..._recentHistory.map((item) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.url,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.result,
                              style: TextStyle(
                                fontSize: 13,
                                color: _getResultColor(item.result),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.checkedAt,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                      SizedBox(height: 20),
                      Text(
                        '분석 중입니다...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '잠시만 기다려주세요',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
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
