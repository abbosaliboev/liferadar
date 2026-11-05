// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'LifeRadar';

  @override
  String get tabHome => '홈';

  @override
  String get tabMap => '지도';

  @override
  String get tabPlans => '내 일정';

  @override
  String get tabDiscover => '발견';

  @override
  String get homeGreeting => '나를 위한 신호';

  @override
  String get homeSubtitle => '내 일정과 관심사 주변에서 일어난 변화';

  @override
  String get whyItMatters => '중요한 이유';

  @override
  String get sources => '출처';

  @override
  String confidence(int percent) {
    return '신뢰도 $percent%';
  }

  @override
  String get showOnMap => '지도에서 보기';

  @override
  String get feedbackThanks => '감사합니다! 추천에 반영할게요.';

  @override
  String get layerPlans => '내 일정';

  @override
  String get layerRecommended => '추천';

  @override
  String get layerRoute => '경로';

  @override
  String get modeExplore => '탐색';

  @override
  String get modeMyMap => '내 지도';

  @override
  String get modeRoute => '경로';

  @override
  String get routeComingSoon =>
      '경로 기반 발견 기능이 곧 추가됩니다. 출발지와 목적지를 설정하면 경로 주변 이벤트를 찾아드려요.';

  @override
  String get mapKeyMissing =>
      '카카오 지도 키가 없습니다.\n--dart-define-from-file=env.json 으로 실행하세요';

  @override
  String mapError(String message) {
    return '지도를 불러오지 못했습니다: $message';
  }

  @override
  String get plansEmpty => '예정된 일정이 없습니다. Google 캘린더를 연결해 가져오세요.';

  @override
  String get connectCalendar => 'Google 캘린더 연결';

  @override
  String get comingSoon => '준비 중';

  @override
  String get discoverAll => '전체';

  @override
  String get whyForYou => '추천 이유';

  @override
  String get register => '참가 신청';

  @override
  String get addToCalendar => '캘린더에 추가';

  @override
  String get noRegisterLink => '아직 신청 링크가 없습니다';

  @override
  String get sampleData => '샘플 데이터';

  @override
  String matchesInterests(String tags) {
    return '관심사와 일치: $tags';
  }

  @override
  String get language => '언어';

  @override
  String get categoryConference => '컨퍼런스';

  @override
  String get categoryHackathon => '해커톤';

  @override
  String get categoryConcert => '공연';

  @override
  String get categoryFestival => '축제';

  @override
  String get categoryMeetup => '밋업';

  @override
  String get categoryJob => '채용';

  @override
  String get categoryScholarship => '장학금';

  @override
  String mapSdkNotLoaded(String origin) {
    return '카카오 지도 SDK를 불러오지 못했습니다.\nKakao Developers에 아래 주소를 Web 도메인으로 등록하세요:\n$origin';
  }
}
