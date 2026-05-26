import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import 'signup_screen.dart';
import 'onboarding_screen.dart';
import 'permission_screen.dart';
import '../widgets/social_login_button.dart';
import 'package:http/http.dart' as http; //  서버 통신 패키지
import 'dart:convert'; // 
import 'package:url_launcher/url_launcher.dart'; //  외부 브라우저 실행 패키지
import 'package:app_links/app_links.dart'; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

 late AppLinks _appLinks;
 final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initDeepLinks(); 
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;

      debugPrint('🔗 감지된 딥링크 수신 호스트: ${uri.host}');

      if (uri.host == 'login-success') {
        final String? token = uri.queryParameters['token'];
        final String? platform = uri.queryParameters['platform'];
        final String? rawName = uri.queryParameters['name'];
        final String? rawEmail = uri.queryParameters['email'];
        
        String? name;
        String? email;
        try {
          if (rawName != null) name = Uri.decodeComponent(rawName);
          if (rawEmail != null) email = Uri.decodeComponent(rawEmail);
        } catch (e) {
          debugPrint('데이터 디코딩 오류 (기본값 대체): $e');
          name = rawName;
          email = rawEmail;
        }

        if (token != null) {
          debugPrint('[$platform 간편로그인 성공] 토큰 획득 완료');
          debugPrint('파싱된 유저 정보 -> 이름: $name, 이메일: $email');
          
          // 기기 보안 저장소 금고에 사용자 세션 정보 영구 박음질
          await _storage.write(key: 'user_token', value: token);
          await _storage.write(key: 'login_platform', value: platform ?? 'unknown');
          
          if (name != null) await _storage.write(key: 'user_name', value: name);
          if (email != null) await _storage.write(key: 'user_email', value: email);
          
          appState.login();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } else if (uri.host == 'login-fail') {
        debugPrint('간편로그인 실패 신호 수신');
        _showSnack('소셜 로그인에 실패했습니다. 다시 시도해주세요.');
      }
    }, onError: (err) {
      debugPrint('딥링크 리스너 내부 에러: $err');
    });
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
 
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _pwController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('이메일과 비밀번호를 입력해주세요');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack('올바른 이메일 형식을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://43.201.26.98:3000/api/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String? token = responseData['token'];

        if (token != null) {
          await _storage.write(key: 'user_token', value: token);
          await _storage.write(key: 'login_platform', value: 'email');
          // 일반 로그인의 경우 받아온 이메일을 식별값으로 금고에 함께 보관
          await _storage.write(key: 'user_email', value: email);
          await _storage.write(key: 'user_name', value: email.split('@')[0]);
        }

        appState.login();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        _showSnack('아이디 또는 비밀번호가 올바르지 않습니다.');
      }
    } catch (e) {
      _showSnack('서버 연결 실패! 팀플 백엔드를 확인하세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false); 
  }

  // 소셜 로그인 실행 함수 (카카오, 네이버, 구글 주소 호출)
  void _handleSocialLogin(String platform) async {
    final url = Uri.parse('http://43.....파일 공유 URL...$platform');
    debugPrint('🚀 외부 브라우저 오픈 요청 API URL: $url');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('브라우저를 열 수 없는 주소입니다: $url');
      }
    } catch (e) {
      debugPrint('소셜 로그인 링크 런처 오류: $e');
    }
  }
    
  Future<void> _continueAsGuest() async {
    await appState.logout(); // 오류시 await 삭제 appState.logout();

    if (!context.mounted) return; // 오류 시 if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const PermissionScreen(),
      ),
    );
  }
    

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Widget _buildGuestButton() {
    return Center(
      child: GestureDetector(
        onTap: _continueAsGuest,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '비회원으로 이용하기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 126,
                height: 1,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
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
              MaterialPageRoute(
                builder: (context) => const OnboardingScreen(),
              ),
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
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '스미싱 탐지기',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '이메일',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    size: 28,
                    color: Color(0xFF1976D2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1976D2),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pwController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    size: 28,
                    color: Color(0xFF1976D2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1976D2),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '아직 계정이 없으신가요? 회원가입',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '간편 로그인',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    ),
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
                onTap: () => _handleSocialLogin('kakao') 
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                color: const Color(0xFF03C75A),
                textColor: Colors.white,
                icon: Icons.login,
                iconColor: Colors.white,
                text: '네이버로 시작하기',
                onTap: () => _handleSocialLogin('naver')
              ),
              const SizedBox(height: 12),
              SocialLoginButton(
                color: Colors.white,
                textColor: const Color(0xFF191919),
                icon: Icons.g_mobiledata,
                iconColor: const Color(0xFF4285F4),
                text: '구글로 시작하기',
                onTap: () => _handleSocialLogin('google'),
                hasBorder: true,
              ),
              const SizedBox(height: 22),
              _buildGuestButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
