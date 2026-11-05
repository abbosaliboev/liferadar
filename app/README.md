# LifeRadar — Flutter app

## Ishga tushirish (Chrome — asosiy dev usuli)
1. `cp env.example.json env.json` va kalitlarni yozing.
2. `dart run tool/gen_web_env.dart` → `web/kakao_config.js` yaratiladi (Kakao JS SDK).
3. Kakao Developers → 앱 → 플랫폼 키 / 플랫폼 → **Web 도메인**ga `http://localhost:8080` qo'shing
   (JavaScript 키 → JavaScript SDK 도메인). Kakao Map'ni yoqing (카카오맵 사용 설정 ON).
4. `flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json`
   (yoki VS Code → "LifeRadar (Chrome)"). Port **8080** bo'lishi shart — domen shunga ro'yxatdan o'tgan.

## Android (demo kuni)
- `KAKAO_NATIVE_APP_KEY` ni env.json ga yozing.
- 플랫폼 → Android: paket `com.liferadar.liferadar`, key hash:
  `keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | openssl sha1 -binary | openssl base64`
- Kakao native SDK faqat ARM qurilmada (haqiqiy telefon) ishlaydi.

## Kalitlar
| Kalit | Ishlatilishi |
|---|---|
| KAKAO_JS_KEY | Web xarita (domen bilan cheklangan) |
| KAKAO_NATIVE_APP_KEY | Android xarita |
| KAKAO_REST_API_KEY | Joy qidirish / geocoding |
| TMAP_APP_KEY | Jamoat transporti yo'nalishi |

⚠️ REST/TMAP kalitlari hozir client'da — keyinroq Cloud Functions'ga ko'chiriladi.

## Tuzilma
```
lib/
  core/       theme, router, env, l10n extension, kakao_sdk_check
  data/       providers (Riverpod), sample_data (keyin Firestore)
  models/     domain modellar
  features/   home · map · plans · discover · event · shell
  l10n/       app_en.arb, app_ko.arb (+ generatsiya qilingan fayllar)
tool/         gen_web_env.dart
```
