import 'package:flutter/material.dart';
import '../app_state.dart'; 
import 'home_screen.dart';
import 'signup_screen.dart';
import 'onboarding_screen.dart';
import '../widgets/social_login_button.dart';
import 'package:http/http.dart' as http; // 추가됨
import 'dart:convert'; //  추가됨
import 'package:url_launcher/url_launcher.dart'; //  추가됨

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final email = _idController.text.trim();
    final password = _pwController.text.trim();

    // ➕ [추가] 입력값 유무 확인
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')),
      );
      return;
    }

    try {
      //  [수정]  백엔드 주소(4000번)로 로그인 요청 전송
      final response = await http.post(
        Uri.parse('http://10.0.2.2:4000/api/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5)); //  [추가] 5초 타임아웃

      //  [수정] 서버가 성공(200)을 응답했을 때만 로그인 처리
      if (response.statusCode == 200) {
        appState.login();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        //  [수정] 로그인 실패 시 알림 메시지 출력
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('아이디 또는 비밀번호가 올바르지 않습니다.')),
          );
        }
      }
    } catch (e) {
      //  [수정] 서버 연결 불가 시 예외 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 연결 실패! 팀플 백엔드(4000번)를 확인하세요.')),
        );
      }
    }
  }

  //  [수정] 소셜 로그인 실행 함수 (카카오, 네이버 주소 호출)
  void _handleSocialLogin(String platform) async {
    // 팀 프로젝트 백엔드 주소 (4000번 포트)
    final url = Uri.parse('http://10.0.2.2:4000/api/auth/$platform');
    
    try {
      // url_launcher를 사용하여 외부 브라우저 실행
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('브라우저를 열 수 없는 주소입니다: $url');
      }
    } catch (e) {
      debugPrint('소셜 로그인 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.security, color: Colors.white, size: 54),
                    ),
                    const SizedBox(height: 16),
                    const Text('스미싱 탐지기', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 아이디 입력
              const Text('아이디', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
                style: const TextStyle(fontSize: 18), //  추가
                decoration: InputDecoration(
                  hintText: '아이디를 입력하세요', 
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1976D2)), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
              const SizedBox(height: 16),
              // 비밀번호 입력
              const Text('비밀번호', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _pwController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 18), // 추가 
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              // 로그인 버튼
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  onPressed: _handleLogin, //  [수정] 이제 이 버튼은 서버와 통신
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2), 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('로그인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              // 회원가입 버튼
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                  child: const Text('아직 계정이 없으신가요? 회원가입', style: TextStyle(fontSize: 16, color: Color(0xFF1976D2))),
                ),
              ),
              const SizedBox(height: 24),
              // [수정] const Row에서 const 제거 (내부 텍스트 가변성 대응)
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12), 
                    child: Text('간편 로그인', style: TextStyle(color: Colors.grey.shade500))
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              SocialLoginButton(
                color: const Color(0xFFFEE500), 
                textColor: const Color(0xFF191919), 
                icon: Icons.chat_bubble, 
                iconColor: const Color(0xFF191919), 
                text: '카카오로 시작하기', 
                onTap: () => _handleSocialLogin('kakao') //  카카오 호출
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                color: const Color(0xFF03C75A), 
                textColor: Colors.white, 
                icon: Icons.login, 
                iconColor: Colors.white, 
                text: '네이버로 시작하기', 
                onTap: () => _handleSocialLogin('naver') //  네이버 호출
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                color: Colors.white, 
                textColor: const Color(0xFF191919), 
                icon: Icons.g_mobiledata, 
                iconColor: const Color(0xFF4285F4), 
                text: '구글로 시작하기', 
                onTap: () => _handleSocialLogin('google'), //  구글 호출
                hasBorder: true
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
