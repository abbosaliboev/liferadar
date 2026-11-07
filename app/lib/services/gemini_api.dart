import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/env.dart';

/// Gemini generateContent: asosiy model, band bo'lsa zaxira model.
///
/// ⚠️ Demo uchun kalit ilovada. `back` repo tayyor bo'lgach, bu klass server proxy'ga
/// so'rov yuboradigan qilib almashtiriladi (prompt va validatsiya `lib/ai/` da qoladi).
class GeminiApi {
  GeminiApi({http.Client? client, String? apiKey, this.models = defaultModels})
      : _client = client ?? http.Client(),
        _key = apiKey ?? Env.geminiApiKey;

  static const defaultModels = ['gemini-3.5-flash-lite', 'gemini-3.1-flash-lite'];

  final http.Client _client;
  final String _key;
  final List<String> models;

  bool get isConfigured => _key.isNotEmpty;

  /// Javob JSON'i va javob bergan model. UI kutib qolmasin: har model uchun bitta urinish.
  Future<(Map<String, dynamic>, String)> generate(Map<String, dynamic> body) async {
    if (!isConfigured) throw const GeminiException('GEMINI_API_KEY missing');
    final payload = jsonEncode(body);
    Object? lastError;
    for (final model in models) {
      try {
        final res = await _client
            .post(
              // "AQ." formatidagi yangi kalitlar faqat ?key= orqali ishlaydi (DEVELOPER.md).
              Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent')
                  .replace(queryParameters: {'key': _key}),
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 25));
        if (res.statusCode == 200) {
          return (jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>, model);
        }
        lastError = 'HTTP ${res.statusCode} ($model)';
      } catch (e) {
        lastError = e;
      }
    }
    throw GeminiException('$lastError');
  }
}

class GeminiException implements Exception {
  const GeminiException(this.message);
  final String message;
  @override
  String toString() => 'GeminiException: $message';
}
