import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String _scanUrlEndpoint =
      'https://api.maknae.synology.me/api/scans/url';

  static Future<Map<String, dynamic>> scanUrl({
    required String deviceId,
    required String url,
    required String sourceApp,
  }) async {
    final response = await http.post(
      Uri.parse(_scanUrlEndpoint),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_id': deviceId,
        'url': url,
        'source_app': sourceApp,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'scanUrl failed: status=${response.statusCode}, body=${response.body}',
    );
  }

  static Future<Map<String, dynamic>> checkUrl({
    required String url,
    required String sourceApp,
    required String messageText,
  }) {
    return scanUrl(
      deviceId: 'android-test-device',
      url: url,
      sourceApp: sourceApp,
    );
  }
}
