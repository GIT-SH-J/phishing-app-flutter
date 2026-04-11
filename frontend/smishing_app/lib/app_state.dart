import 'package:flutter/material.dart';

final appState = AppState();

class AppState extends ChangeNotifier {
  bool _isDarkMode = false;
  String _userName = '홍길동';
  double _fontSize = 1.0;
  bool _smishingAlert = true;
  bool _cautionAlert = false;

  // ===============================
  // 🔥 추가: 로그인 & 비회원 제한 관련 상태
  // ===============================

  bool _isLoggedIn = false; // 로그인 여부
  int _guestScanCount = 0; // 비회원 검사 횟수
  final int _maxGuestScanCount = 3; // 최대 3회 제한

  // ===============================
  // 기존 getter
  // ===============================

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;
  double get fontSize => _fontSize;
  bool get smishingAlert => _smishingAlert;
  bool get cautionAlert => _cautionAlert;

  // ===============================
  // 🔥 추가 getter
  // ===============================

  bool get isLoggedIn => _isLoggedIn;

  int get guestScanCount => _guestScanCount;

  int get maxGuestScanCount => _maxGuestScanCount;

  // 👉 비회원이 아직 검사 가능한지
  bool get canUseGuestScan => _guestScanCount < _maxGuestScanCount;

  // 👉 남은 횟수
  int get remainingScanCount => _maxGuestScanCount - _guestScanCount;

  // ===============================
  // 기존 기능
  // ===============================

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void toggleSmishingAlert() {
    _smishingAlert = !_smishingAlert;
    notifyListeners();
  }

  void toggleCautionAlert() {
    _cautionAlert = !_cautionAlert;
    notifyListeners();
  }

  // ===============================
  // 🔥 추가 기능
  // ===============================

  // 로그인 처리
  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  // 로그아웃 처리
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // 비회원 검사 횟수 증가
  void increaseGuestScan() {
    _guestScanCount++;
    notifyListeners();
  }

  // 검사 횟수 초기화 (필요할 때 사용)
  void resetGuestScan() {
    _guestScanCount = 0;
    notifyListeners();
  }
}
