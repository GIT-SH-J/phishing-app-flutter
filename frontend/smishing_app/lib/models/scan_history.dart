// 검사기록 1개를 담는 설계도
class ScanHistory {
  final String url;
  final String result;
  final String checkedAt;

  ScanHistory({
    required this.url,
    required this.result,
    required this.checkedAt,
  });

  Map<String, dynamic> toJson() {
    return {'url': url, 'result': result, 'checkedAt': checkedAt};
  }

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      url: json['url'] ?? '',
      result: json['result'] ?? '',
      checkedAt: json['checkedAt'] ?? '',
    );
  }
}
