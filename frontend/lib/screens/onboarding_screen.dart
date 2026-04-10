import 'package:flutter/material.dart';
// ❌ 로그인 화면 제거
// import 'login_screen.dart';

// ✅ URL 검사 화면 (HomeScreen)으로 변경
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(); // 슬라이드 제어
  int _currentPage = 0; // 현재 페이지 index

  // 온보딩에 보여줄 페이지 데이터
  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.security,
      'color': Color(0xFF1976D2),
      'title': '스미싱 탐지기에\n오신걸 환영합니다',
      'desc': '의심스러운 문자와 URL을\n안전하게 확인할 수 있어요',
    },
    {
      'icon': Icons.search,
      'color': Color(0xFF4CAF50),
      'title': '문자나 주소를\n붙여넣고 검사하세요',
      'desc': '카카오톡, 문자메시지에서\n의심스러운 내용을 복사해서\n바로 검사할 수 있어요',
    },
    {
      'icon': Icons.chat_bubble,
      'color': Color(0xFFFFC107),
      'title': 'AI가 위험 여부를\n알려드려요',
      'desc': '검사 결과를 쉽게 확인하고\nAI 상담사에게 도움을\n받을 수 있어요',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 🔹 상단 "건너뛰기" 버튼
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () {
                      // ❗ 로그인 대신 바로 URL 검사 화면으로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                    ),
                  ),
                ),
              ),

              // 🔹 슬라이딩 페이지 영역
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 아이콘 영역
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: (page['color'] as Color).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              page['icon'] as IconData,
                              size: 80,
                              color: page['color'] as Color,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // 제목
                          Text(
                            page['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              color: Color(0xFF212121),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 설명
                          Text(
                            page['desc'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF616161),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 🔹 하단 영역
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // 페이지 인디케이터 (점)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF1976D2)
                                : const Color(0xFFBDBDBD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 🔹 다음 / 시작하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            // 다음 페이지로 이동
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // ❗ 마지막 페이지 → 로그인 대신 바로 URL 검사 화면으로 이동
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1 ? '다음' : '시작하기',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
