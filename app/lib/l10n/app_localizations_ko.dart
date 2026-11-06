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

  @override
  String get routeFrom => '출발';

  @override
  String get routeTo => '도착';

  @override
  String get routeDate => '날짜';

  @override
  String get routeFind => '경로 주변 기회 찾기';

  @override
  String get routeDemo => '데모: 서울역 → 부산역';

  @override
  String get routeSearchHint => '장소 검색 (예: 부산역, BEXCO)';

  @override
  String get routeNoResults => '검색 결과가 없습니다';

  @override
  String routeSummary(String distance, String duration) {
    return '자동차 $distance km · $duration';
  }

  @override
  String routeAlongTheWay(int count) {
    return '경로 주변 ($count)';
  }

  @override
  String get routeNoOpportunities => '해당 날짜에 경로 15km 이내의 관련 이벤트가 없습니다.';

  @override
  String routeDetour(String km, int minutes) {
    return '+$km km · +$minutes분';
  }

  @override
  String routeFromRoute(String km) {
    return '경로에서 $km km';
  }

  @override
  String routeError(String message) {
    return '경로 탐색 실패: $message';
  }

  @override
  String get onYourWay => '가는 길에';

  @override
  String hoursMinutes(int h, int m) {
    return '$h시간 $m분';
  }

  @override
  String get travelCar => '자동차';

  @override
  String get travelTransit => '대중교통';

  @override
  String routeSummaryTransit(String distance, String duration, String lines) {
    return '$distance km · $duration · $lines';
  }

  @override
  String get calendarConnecting => 'Google에 연결 중…';

  @override
  String get calendarSyncing => '캘린더 동기화 중…';

  @override
  String calendarConnectedCount(int count) {
    return 'Google 캘린더 · 예정 일정 $count개';
  }

  @override
  String get calendarSync => '동기화';

  @override
  String get calendarDisconnect => '연결 해제';

  @override
  String get calendarExpired => 'Google 세션이 만료되었습니다. 다시 연결해 주세요.';

  @override
  String get calendarNotConfigured =>
      '이 플랫폼에서는 아직 Google 로그인이 설정되지 않았습니다 (현재 웹 전용).';

  @override
  String calendarError(String message) {
    return '캘린더 오류: $message';
  }

  @override
  String get calendarPrivacy =>
      'LifeRadar는 예정된 일정만 읽고, 선택한 이벤트만 추가합니다. 언제든 연결을 해제할 수 있습니다.';

  @override
  String get noLocation => '장소 없음';

  @override
  String get sourceCalendar => 'Google 캘린더';

  @override
  String get addedToCalendar => 'Google 캘린더에 추가했습니다';

  @override
  String get addingToCalendar => '추가 중…';

  @override
  String get weatherLater => '예보는 약 10일 전부터 제공';

  @override
  String get onboardingTagline => '검색하기 전에, 내 일정 주변의 기회를 먼저 찾아드려요.';

  @override
  String get onboardingTitle => '어떤 분야에 관심 있으세요?';

  @override
  String get onboardingSubtitle => '몇 개만 골라 주세요. 행사와 경로 추천 순서에 반영돼요.';

  @override
  String get onboardingPickOne => '하나 이상 선택해 주세요';

  @override
  String onboardingContinue(int count) {
    return '계속 ($count개 선택)';
  }

  @override
  String get onboardingPrivacy => '이 기기에만 저장되며 언제든 바꿀 수 있어요.';

  @override
  String get interestsEdit => '내 관심사';

  @override
  String get save => '저장';

  @override
  String get homeEmptyTitle => '아직 신호가 없어요';

  @override
  String get homeEmptyBody => '캘린더를 연결하거나 관심사를 더 추가해 보세요. 일정과 행사·날씨를 연결해 드릴게요.';
}
