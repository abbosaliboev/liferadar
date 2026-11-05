// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LifeRadar';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMap => 'Map';

  @override
  String get tabPlans => 'My Plans';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get homeGreeting => 'Signals for you';

  @override
  String get homeSubtitle => 'What changed around your plans and interests';

  @override
  String get whyItMatters => 'Why it matters';

  @override
  String get sources => 'Sources';

  @override
  String confidence(int percent) {
    return 'Confidence $percent%';
  }

  @override
  String get showOnMap => 'Show on map';

  @override
  String get feedbackThanks => 'Thanks! We\'ll tune your signals.';

  @override
  String get layerPlans => 'My Plans';

  @override
  String get layerRecommended => 'Recommended';

  @override
  String get layerRoute => 'Route';

  @override
  String get modeExplore => 'Explore';

  @override
  String get modeMyMap => 'My Map';

  @override
  String get modeRoute => 'Route';

  @override
  String get mapKeyMissing =>
      'Kakao Map key is missing.\nRun with --dart-define-from-file=env.json';

  @override
  String mapError(String message) {
    return 'Map failed to load: $message';
  }

  @override
  String get plansEmpty =>
      'No upcoming plans yet. Connect Google Calendar to import them.';

  @override
  String get connectCalendar => 'Connect Google Calendar';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get discoverAll => 'All';

  @override
  String get whyForYou => 'Why for you';

  @override
  String get register => 'Register';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get noRegisterLink => 'No registration link yet';

  @override
  String get sampleData => 'Sample data';

  @override
  String matchesInterests(String tags) {
    return 'Matches your interests: $tags';
  }

  @override
  String get language => 'Language';

  @override
  String get categoryConference => 'Conference';

  @override
  String get categoryHackathon => 'Hackathon';

  @override
  String get categoryConcert => 'Concert';

  @override
  String get categoryFestival => 'Festival';

  @override
  String get categoryMeetup => 'Meetup';

  @override
  String get categoryJob => 'Job';

  @override
  String get categoryScholarship => 'Scholarship';

  @override
  String mapSdkNotLoaded(String origin) {
    return 'Kakao Map SDK did not load.\nRegister this address as a Web domain in Kakao Developers:\n$origin';
  }

  @override
  String get routeFrom => 'From';

  @override
  String get routeTo => 'To';

  @override
  String get routeDate => 'Date';

  @override
  String get routeFind => 'Find opportunities';

  @override
  String get routeDemo => 'Demo: Seoul St. → Busan St.';

  @override
  String get routeSearchHint => 'Search a place (e.g. 부산역, BEXCO)';

  @override
  String get routeNoResults => 'No places found';

  @override
  String routeSummary(String distance, String duration) {
    return '$distance km · $duration by car';
  }

  @override
  String routeAlongTheWay(int count) {
    return 'Along the way ($count)';
  }

  @override
  String get routeNoOpportunities =>
      'No matching events within 15 km of this route on that day.';

  @override
  String routeDetour(String km, int minutes) {
    return '+$km km · +$minutes min';
  }

  @override
  String routeFromRoute(String km) {
    return '$km km from route';
  }

  @override
  String routeError(String message) {
    return 'Route failed: $message';
  }

  @override
  String get onYourWay => 'On your way';

  @override
  String hoursMinutes(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String get travelCar => 'Car';

  @override
  String get travelTransit => 'Transit';

  @override
  String routeSummaryTransit(String distance, String duration, String lines) {
    return '$distance km · $duration · $lines';
  }

  @override
  String get calendarConnecting => 'Connecting to Google…';

  @override
  String get calendarSyncing => 'Syncing calendar…';

  @override
  String calendarConnectedCount(int count) {
    return 'Google Calendar · $count upcoming plans';
  }

  @override
  String get calendarSync => 'Sync';

  @override
  String get calendarDisconnect => 'Disconnect';

  @override
  String get calendarExpired => 'Google session expired. Please connect again.';

  @override
  String get calendarNotConfigured =>
      'Google sign-in isn\'t set up on this platform yet (web only for now).';

  @override
  String calendarError(String message) {
    return 'Calendar error: $message';
  }

  @override
  String get calendarPrivacy =>
      'LifeRadar only reads upcoming events and adds events you choose. Disconnect anytime.';

  @override
  String get noLocation => 'No location';

  @override
  String get sourceCalendar => 'Google Calendar';

  @override
  String get addedToCalendar => 'Added to Google Calendar';

  @override
  String get addingToCalendar => 'Adding…';
}
