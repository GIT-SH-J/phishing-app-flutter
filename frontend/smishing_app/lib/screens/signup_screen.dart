import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:http/http.dart' as http; // [추가] 외부 서버와 통신하기 위한 패키지
import 'dart:convert'; //  [추가] 데이터를 서버가 이해하는 JSON 형식으로 바꾸기 위함

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: isSuccess
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 18, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  [수정] 기존 void에서 Future<void> 및 async로 변경 (서버 응답을 기다려야 하므로)
  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _idController.text.trim();
    final password = _pwController.text;

    // 1. 유효성 검사 (입력값 체크 로직은 기존 유지)
    if (name.isEmpty) {
      _showDialog('입력 오류', '이름을 입력해주세요');
      return;
    }
    
    final nameRegex = RegExp(r'^[\uAC00-\uD7A3a-zA-Z\u3040-\u30FF\u4E00-\u9FFF ]+$');
    if (!nameRegex.hasMatch(name)) {
      _showDialog('이름 형식 오류', '이름에는 숫자나 특수문자를 사용할 수 없습니다.');
      return;
    }

    if (!email.contains('@')) {
      _showDialog('입력 오류', '아이디는 이메일 형식(@ 포함)이어야 합니다.');
      return;
    }
    if (password.isEmpty) { 
      _showDialog('입력 오류', '비밀번호를 입력해주세요');
      return;
    }
    if (password.length < 6) { 
      _showDialog('입력 오류', '비밀번호는 최소 6자리 이상이어야 합니다.');
      return;
    }
    if (!_agreeTerms) {
      _showDialog('약관 동의', '이용약관 및 개인정보 처리방침에 동의해주세요');
      return;
    }

    //  [추가] 2. 실제 서버 통신 로직 
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:4000/api/auth/signup'), //  에뮬레이터 전용 localhost 주소 적용
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          // 'name': name, // 백엔드 스키마가 email/pw 위주이므로 선택적 적용
        }),
      ).timeout(const Duration(seconds: 5)); //  무한 대기 방지를 위한 타임아웃 추가

      //  [수정] 3. 무조건 성공 팝업을 띄우던 기존과 달리, 서버 응답 상태(statusCode)에 따라 분기 처리
      if (response.statusCode == 201) {
        // 성공 시 (DB 저장 완료)
        _showDialog(
          '회원가입 완료',
          '회원가입이 완료되었습니다!\n이제 로그인 화면으로 이동합니다',
          isSuccess: true,
        );
      } else {
        // 실패 시 (이미 존재하는 계정 등 서버가 보낸 에러 메시지 출력)
        final error = jsonDecode(response.body);
        _showDialog('가입 실패', error['message'] ?? '다시 시도해주세요');
      }
    } catch (e) {
      //  [추가] 서버 연결 실패(네트워크 오류 등)에 대한 예외 처리
      _showDialog('연결 오류', '서버(4000번)가 켜져 있는지 확인하세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // build 함수 내 UI 구성은 기존 깃허브 코드와 동일하게 유지됩니다.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '회원가입',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('이름', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '이름을 입력하세요',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 28, color: Color(0xFF1976D2)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('아이디', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _idController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '아이디를 입력하세요',
                  prefixIcon: const Icon(Icons.person_outline, size: 28, color: Color(0xFF1976D2)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('비밀번호', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _pwController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요',
                  prefixIcon: const Icon(Icons.lock_outline, size: 28, color: Color(0xFF1976D2)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('비밀번호 확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _pwConfirmController,
                obscureText: _obscureConfirm,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '비밀번호를 다시 입력하세요',
                  prefixIcon: const Icon(Icons.lock_outline, size: 28, color: Color(0xFF1976D2)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                    activeColor: const Color(0xFF1976D2),
                  ),
                  const Flexible(child: Text('이용약관 및 개인정보 처리방침에 동의합니다', style: TextStyle(fontSize: 15))),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('회원가입', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
