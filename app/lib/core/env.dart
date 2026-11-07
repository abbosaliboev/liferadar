import 'package:flutter/foundation.dart';

/// Kalitlar `flutter run --dart-define-from-file=env.json` orqali beriladi.
/// env.json gitga tushmaydi (env.example.json ga qarang).
///
/// ⚠️ REST/TMAP kalitlari hozircha client'da (demo uchun). D4+ da
/// Cloud Functions'ga ko'chiriladi, shunda kalitlar ilovadan chiqib ketmaydi.
abstract final class Env {
  static const kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
  static const kakaoJsKey = String.fromEnvironment('KAKAO_JS_KEY');
  static const kakaoRestApiKey = String.fromEnvironment('KAKAO_REST_API_KEY');
  static const tmapAppKey = String.fromEnvironment('TMAP_APP_KEY');
  static const googleApiKey = String.fromEnvironment('GOOGLE_API_KEY');
  static const googleOAuthWebClientId = String.fromEnvironment('GOOGLE_OAUTH_WEB_CLIENT_ID');

  /// Home insight matnlari uchun (bo'sh bo'lsa — faqat qoida matni). Demo uchun client'da.
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Har kuni yangilanadigan haqiqiy eventlar (GitHub Actions → ochiq `liferadar-data` repo).
  /// Bo'sh qilinsa — faqat APK ichidagi eventlar.
  static const eventsUrl = String.fromEnvironment(
    'EVENTS_URL',
    defaultValue: 'https://raw.githubusercontent.com/abbosaliboev/liferadar-data/main/events.json',
  );

  /// Rasmiy yo'l ta'siri (TOPIS) — GitHub Actions har 3 soatda yangilaydi.
  static const trafficUrl = String.fromEnvironment(
    'TRAFFIC_URL',
    defaultValue: 'https://raw.githubusercontent.com/abbosaliboev/liferadar-data/main/traffic.json',
  );

  /// Web'da JS SDK index.html orqali (kakao_config.js), Android'da native key bilan.
  static bool get hasKakaoMapKey => kIsWeb ? kakaoJsKey.isNotEmpty : kakaoNativeAppKey.isNotEmpty;
}
