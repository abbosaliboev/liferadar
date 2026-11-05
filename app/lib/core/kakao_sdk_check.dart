// Web'da Kakao JS SDK (window.kakao) yuklanganini tekshiradi.
// Android'da har doim true (native SDK).
export 'kakao_sdk_check_stub.dart' if (dart.library.js_interop) 'kakao_sdk_check_web.dart';
