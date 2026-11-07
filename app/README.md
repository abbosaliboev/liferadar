# LifeRadar — Flutter app

이 폴더는 LifeRadar Flutter 앱입니다.

- 설치·키 설정·구조·테스트 → [개발자 가이드](../docs/DEVELOPER.md)
- 제품 소개 → [README](../README.md)
- 사용법 → [사용자 가이드](../docs/USER_GUIDE.md)

```bash
cp env.example.json env.json
dart run tool/gen_web_env.dart
dart run tool/collect_events.dart   # (선택) 실제 행사 데이터 갱신
flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json \
  --web-browser-flag="--user-data-dir=$PWD/.dart_tool/chrome-profile"   # 로그인·관심사·일정 유지
```
