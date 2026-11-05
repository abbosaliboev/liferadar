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

  /// Web'da JS SDK index.html orqali (kakao_config.js), Android'da native key bilan.
  static bool get hasKakaoMapKey => kIsWeb ? kakaoJsKey.isNotEmpty : kakaoNativeAppKey.isNotEmpty;
}
