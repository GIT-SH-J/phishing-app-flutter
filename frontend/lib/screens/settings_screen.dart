import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/setting_header.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBackHome;

  const SettingsScreen({super.key, this.onBackHome});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();

    _listener = () {
      if (mounted) {
        setState(() {});
      }
    };

    appState.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) {
      appState.removeListener(_listener!);
    }
    super.dispose();
  }

  String _getFontSizeLabel(double size) {
    if (size <= 0.8) return '작게';
    if (size <= 1.0) return '보통';
    if (size <= 1.2) return '크게';
    return '매우 크게';
  }

  void _handleBack(BuildContext context) {
    if (widget.onBackHome != null) {
      widget.onBackHome!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => _handleBack(context),
        ),
        centerTitle: true,
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 34,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '홍길동',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'test@test.com',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              '간편로그인 연동 예정',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),

          const SettingHeader(title: '화면'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  title: const Text('다크모드', style: TextStyle(fontSize: 18)),
                  subtitle: const Text('어두운 화면으로 전환합니다'),
                  value: appState.isDarkMode,
                  onChanged: (val) => appState.toggleDarkMode(),
                  secondary: const Icon(Icons.dark_mode_outlined, size: 28),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const Icon(Icons.text_fields, size: 28),
                  title: const Text('글씨 크기', style: TextStyle(fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _getFontSizeLabel(appState.fontSize),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Slider(
                        value: appState.fontSize,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        onChanged: (val) => appState.setFontSize(val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const SettingHeader(title: '알림'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  title: const Text(
                    '스미싱 경고 알림',
                    style: TextStyle(fontSize: 18),
                  ),
                  subtitle: const Text('위험 탐지 시 알림을 받습니다'),
                  value: appState.smishingAlert,
                  onChanged: (val) => appState.toggleSmishingAlert(),
                  secondary: const Icon(Icons.notifications_outlined, size: 28),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  title: const Text('주의 알림', style: TextStyle(fontSize: 18)),
                  subtitle: const Text('주의 탐지 시 알림을 받습니다'),
                  value: appState.cautionAlert,
                  onChanged: (val) => appState.toggleCautionAlert(),
                  secondary: const Icon(Icons.warning_amber_outlined, size: 28),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          const SettingHeader(title: '앱 정보'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFEAEAEA)),
            ),
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(Icons.info_outline, size: 28),
                  title: Text('버전', style: TextStyle(fontSize: 18)),
                  trailing: Text('1.0.0', style: TextStyle(fontSize: 16)),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(Icons.privacy_tip_outlined, size: 28),
                  title: const Text(
                    '개인정보 처리방침',
                    style: TextStyle(fontSize: 18),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
