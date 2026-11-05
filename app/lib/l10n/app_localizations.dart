import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LifeRadar'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabPlans.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get tabPlans;

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Signals for you'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What changed around your plans and interests'**
  String get homeSubtitle;

  /// No description provided for @whyItMatters.
  ///
  /// In en, this message translates to:
  /// **'Why it matters'**
  String get whyItMatters;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence {percent}%'**
  String confidence(int percent);

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get showOnMap;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! We\'ll tune your signals.'**
  String get feedbackThanks;

  /// No description provided for @layerPlans.
  ///
  /// In en, this message translates to:
  /// **'My Plans'**
  String get layerPlans;

  /// No description provided for @layerRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get layerRecommended;

  /// No description provided for @layerRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get layerRoute;

  /// No description provided for @modeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get modeExplore;

  /// No description provided for @modeMyMap.
  ///
  /// In en, this message translates to:
  /// **'My Map'**
  String get modeMyMap;

  /// No description provided for @modeRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get modeRoute;

  /// No description provided for @mapKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Kakao Map key is missing.\nRun with --dart-define-from-file=env.json'**
  String get mapKeyMissing;

  /// No description provided for @mapError.
  ///
  /// In en, this message translates to:
  /// **'Map failed to load: {message}'**
  String mapError(String message);

  /// No description provided for @plansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming plans yet. Connect Google Calendar to import them.'**
  String get plansEmpty;

  /// No description provided for @connectCalendar.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Calendar'**
  String get connectCalendar;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @discoverAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoverAll;

  /// No description provided for @whyForYou.
  ///
  /// In en, this message translates to:
  /// **'Why for you'**
  String get whyForYou;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @noRegisterLink.
  ///
  /// In en, this message translates to:
  /// **'No registration link yet'**
  String get noRegisterLink;

  /// No description provided for @sampleData.
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get sampleData;

  /// No description provided for @matchesInterests.
  ///
  /// In en, this message translates to:
  /// **'Matches your interests: {tags}'**
  String matchesInterests(String tags);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @categoryConference.
  ///
  /// In en, this message translates to:
  /// **'Conference'**
  String get categoryConference;

  /// No description provided for @categoryHackathon.
  ///
  /// In en, this message translates to:
  /// **'Hackathon'**
  String get categoryHackathon;

  /// No description provided for @categoryConcert.
  ///
  /// In en, this message translates to:
  /// **'Concert'**
  String get categoryConcert;

  /// No description provided for @categoryFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get categoryFestival;

  /// No description provided for @categoryMeetup.
  ///
  /// In en, this message translates to:
  /// **'Meetup'**
  String get categoryMeetup;

  /// No description provided for @categoryJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get categoryJob;

  /// No description provided for @categoryScholarship.
  ///
  /// In en, this message translates to:
  /// **'Scholarship'**
  String get categoryScholarship;

  /// No description provided for @mapSdkNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Kakao Map SDK did not load.\nRegister this address as a Web domain in Kakao Developers:\n{origin}'**
  String mapSdkNotLoaded(String origin);

  /// No description provided for @routeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get routeFrom;

  /// No description provided for @routeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get routeTo;

  /// No description provided for @routeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get routeDate;

  /// No description provided for @routeFind.
  ///
  /// In en, this message translates to:
  /// **'Find opportunities'**
  String get routeFind;

  /// No description provided for @routeDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo: Seoul St. → Busan St.'**
  String get routeDemo;

  /// No description provided for @routeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a place (e.g. 부산역, BEXCO)'**
  String get routeSearchHint;

  /// No description provided for @routeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get routeNoResults;

  /// No description provided for @routeSummary.
  ///
  /// In en, this message translates to:
  /// **'{distance} km · {duration} by car'**
  String routeSummary(String distance, String duration);

  /// No description provided for @routeAlongTheWay.
  ///
  /// In en, this message translates to:
  /// **'Along the way ({count})'**
  String routeAlongTheWay(int count);

  /// No description provided for @routeNoOpportunities.
  ///
  /// In en, this message translates to:
  /// **'No matching events within 15 km of this route on that day.'**
  String get routeNoOpportunities;

  /// No description provided for @routeDetour.
  ///
  /// In en, this message translates to:
  /// **'+{km} km · +{minutes} min'**
  String routeDetour(String km, int minutes);

  /// No description provided for @routeFromRoute.
  ///
  /// In en, this message translates to:
  /// **'{km} km from route'**
  String routeFromRoute(String km);

  /// No description provided for @routeError.
  ///
  /// In en, this message translates to:
  /// **'Route failed: {message}'**
  String routeError(String message);

  /// No description provided for @onYourWay.
  ///
  /// In en, this message translates to:
  /// **'On your way'**
  String get onYourWay;

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String hoursMinutes(int h, int m);

  /// No description provided for @travelCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get travelCar;

  /// No description provided for @travelTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get travelTransit;

  /// No description provided for @routeSummaryTransit.
  ///
  /// In en, this message translates to:
  /// **'{distance} km · {duration} · {lines}'**
  String routeSummaryTransit(String distance, String duration, String lines);

  /// No description provided for @calendarConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Google…'**
  String get calendarConnecting;

  /// No description provided for @calendarSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing calendar…'**
  String get calendarSyncing;

  /// No description provided for @calendarConnectedCount.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar · {count} upcoming plans'**
  String calendarConnectedCount(int count);

  /// No description provided for @calendarSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get calendarSync;

  /// No description provided for @calendarDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get calendarDisconnect;

  /// No description provided for @calendarExpired.
  ///
  /// In en, this message translates to:
  /// **'Google session expired. Please connect again.'**
  String get calendarExpired;

  /// No description provided for @calendarNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in isn\'t set up on this platform yet (web only for now).'**
  String get calendarNotConfigured;

  /// No description provided for @calendarError.
  ///
  /// In en, this message translates to:
  /// **'Calendar error: {message}'**
  String calendarError(String message);

  /// No description provided for @calendarPrivacy.
  ///
  /// In en, this message translates to:
  /// **'LifeRadar only reads upcoming events and adds events you choose. Disconnect anytime.'**
  String get calendarPrivacy;

  /// No description provided for @noLocation.
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noLocation;

  /// No description provided for @sourceCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get sourceCalendar;

  /// No description provided for @addedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Added to Google Calendar'**
  String get addedToCalendar;

  /// No description provided for @addingToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get addingToCalendar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
