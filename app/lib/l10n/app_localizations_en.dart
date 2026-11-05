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
  String get routeComingSoon =>
      'Route discovery is coming next: set origin and destination to find events along the way.';

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
}
