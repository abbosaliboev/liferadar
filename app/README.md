# LifeRadar — Flutter app

이 폴더는 LifeRadar Flutter 앱입니다.

- 설치·키 설정·구조·테스트 → [개발자 가이드](../docs/DEVELOPER.md)
- 제품 소개 → [README](../README.md)
- 사용법 → [사용자 가이드](../docs/USER_GUIDE.md)

```bash
cp env.example.json env.json
dart run tool/gen_web_env.dart
flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json
```
