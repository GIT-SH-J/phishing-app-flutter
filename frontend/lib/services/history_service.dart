//내부 저장소에 저장/불러오기/전체 삭제하기
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history.dart';

class HistoryService {
  static const String _historyKey = 'scan_history';

  static Future<void> saveHistory(ScanHistory newItem) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList = prefs.getStringList(_historyKey) ?? [];

    historyList.insert(0, jsonEncode(newItem.toJson()));

    if (historyList.length > 20) {
      historyList.removeRange(20, historyList.length);
    }

    await prefs.setStringList(_historyKey, historyList);
  }

  static Future<List<ScanHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList = prefs.getStringList(_historyKey) ?? [];

    return historyList
        .map(
          (item) =>
              ScanHistory.fromJson(jsonDecode(item) as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
