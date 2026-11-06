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

  @override
  String get weatherLater => 'Forecast appears ~10 days before';

  @override
  String get onboardingTagline =>
      'Finds the opportunities around your plans — before you search.';

  @override
  String get onboardingTitle => 'What are you into?';

  @override
  String get onboardingSubtitle =>
      'Pick a few. LifeRadar ranks events and route suggestions by these.';

  @override
  String get onboardingPickOne => 'Pick at least one';

  @override
  String onboardingContinue(int count) {
    return 'Continue ($count selected)';
  }

  @override
  String get onboardingPrivacy =>
      'Saved only on this device. You can change it anytime.';

  @override
  String get interestsEdit => 'My interests';

  @override
  String get save => 'Save';

  @override
  String get homeEmptyTitle => 'No signals yet';

  @override
  String get homeEmptyBody =>
      'Connect your calendar or add more interests — LifeRadar will connect your plans with events and weather.';

  @override
  String get tabProfile => 'Profile';

  @override
  String get loginError => 'Google sign-in failed. Please try again.';

  @override
  String get loginBenefitPlans =>
      'Connects your calendar with events, weather and deadlines';

  @override
  String get loginBenefitRoute =>
      'Finds opportunities along the way — KTX or car';

  @override
  String get loginBenefitSignals =>
      'Explains why each signal matters, with sources';

  @override
  String get loginNewUser =>
      'New here? Your Google account is all you need to sign up.';

  @override
  String get or => 'or';

  @override
  String get continueAsGuest => 'Look around as a guest';

  @override
  String get loginPrivacy =>
      'Your calendar is connected separately, only with your consent.';

  @override
  String get guestName => 'Guest';

  @override
  String get guestSubtitle => 'Sign in to use your own account';

  @override
  String get signIn => 'Sign in';

  @override
  String get edit => 'Edit';

  @override
  String get ok => 'OK';

  @override
  String get sectionConnections => 'Connected services';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get connect => 'Connect';

  @override
  String get sectionSettings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sectionAbout => 'About';

  @override
  String get privacy => 'Privacy';

  @override
  String get version => 'Version';

  @override
  String get logout => 'Sign out';

  @override
  String get exitGuest => 'Back to start';

  @override
  String get homeHello => 'Hello';

  @override
  String homeHelloName(String name) {
    return 'Hi, $name';
  }

  @override
  String get statPlans => 'Plans';

  @override
  String get statSignals => 'Signals';

  @override
  String get statDeadlines => 'Deadlines';

  @override
  String get kindPlanAlert => 'Plan alert';

  @override
  String get kindOpportunity => 'Opportunity';

  @override
  String get kindDeadline => 'Deadline';

  @override
  String get kindRoute => 'Route';

  @override
  String get helpful => 'Helpful';

  @override
  String get notForMe => 'Not for me';

  @override
  String get hide => 'Hide';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get discoverSubtitle => 'Sorted by how well they match your interests';

  @override
  String get matchBadge => 'Match';

  @override
  String get eventDetails => 'Details';

  @override
  String get openSource => 'Source';

  @override
  String get searching => 'Searching…';

  @override
  String get rainChance => 'Rain';

  @override
  String get showLess => 'Show less';

  @override
  String get planNew => 'New plan';

  @override
  String get planEdit => 'Edit plan';

  @override
  String get planTitle => 'Title';

  @override
  String get planTitleHint => 'e.g. Busan business trip';

  @override
  String get planTitleRequired => 'Enter a title';

  @override
  String get planDate => 'Date';

  @override
  String get planStart => 'Starts';

  @override
  String get planEnd => 'Ends';

  @override
  String get planAllDay => 'All day';

  @override
  String get planLocation => 'Location';

  @override
  String get planLocationAdd => 'Add a place';

  @override
  String get planLocationRemove => 'Remove place';

  @override
  String get planNote => 'Note';

  @override
  String get planNoteHint => 'Anything to remember';

  @override
  String get planSaveToCalendar => 'Also save to Google Calendar';

  @override
  String get planCalendarSynced =>
      'Changes are saved to your Google Calendar too.';

  @override
  String get planSampleHint => 'Sample plan — saving makes it your own plan.';

  @override
  String get planDelete => 'Delete plan';

  @override
  String planDeleteConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get planSaved => 'Plan saved';

  @override
  String get planDeleted => 'Plan deleted';

  @override
  String get planEndBeforeStart => 'End time must be after the start';

  @override
  String planSaveError(String message) {
    return 'Couldn\'t save: $message';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get openInCalendar => 'Open in Google Calendar';

  @override
  String get plansEmptyAdd =>
      'Add your first plan, or connect Google Calendar to import them.';

  @override
  String interestsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get categoryPerformance => 'Shows';

  @override
  String get categoryExhibition => 'Exhibition';

  @override
  String get categoryClasses => 'Classes';

  @override
  String get free => 'Free';

  @override
  String dataSource(String name) {
    return 'Data: $name';
  }

  @override
  String get showMore => 'Show more';

  @override
  String eventsUpdated(String date) {
    return 'Real events updated $date';
  }

  @override
  String get realData => 'Live data';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get categoryStartupSupport => 'Startup programs';

  @override
  String applicationPeriod(String from, String to) {
    return 'Applications $from – $to';
  }

  @override
  String get nationwide => 'Nationwide';

  @override
  String get applyNow => 'Apply';

  @override
  String get aiTranslated => 'Translated from Korean with Gemini';
}
