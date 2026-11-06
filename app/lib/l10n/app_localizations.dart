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

  /// No description provided for @weatherLater.
  ///
  /// In en, this message translates to:
  /// **'Forecast appears ~10 days before'**
  String get weatherLater;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Finds the opportunities around your plans — before you search.'**
  String get onboardingTagline;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you into?'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a few. LifeRadar ranks events and route suggestions by these.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingPickOne.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one'**
  String get onboardingPickOne;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue ({count} selected)'**
  String onboardingContinue(int count);

  /// No description provided for @onboardingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Saved only on this device. You can change it anytime.'**
  String get onboardingPrivacy;

  /// No description provided for @interestsEdit.
  ///
  /// In en, this message translates to:
  /// **'My interests'**
  String get interestsEdit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No signals yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Connect your calendar or add more interests — LifeRadar will connect your plans with events and weather.'**
  String get homeEmptyBody;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get loginError;

  /// No description provided for @loginBenefitPlans.
  ///
  /// In en, this message translates to:
  /// **'Connects your calendar with events, weather and deadlines'**
  String get loginBenefitPlans;

  /// No description provided for @loginBenefitRoute.
  ///
  /// In en, this message translates to:
  /// **'Finds opportunities along the way — KTX or car'**
  String get loginBenefitRoute;

  /// No description provided for @loginBenefitSignals.
  ///
  /// In en, this message translates to:
  /// **'Explains why each signal matters, with sources'**
  String get loginBenefitSignals;

  /// No description provided for @loginNewUser.
  ///
  /// In en, this message translates to:
  /// **'New here? Your Google account is all you need to sign up.'**
  String get loginNewUser;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Look around as a guest'**
  String get continueAsGuest;

  /// No description provided for @loginPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your calendar is connected separately, only with your consent.'**
  String get loginPrivacy;

  /// No description provided for @guestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestName;

  /// No description provided for @guestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use your own account'**
  String get guestSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @sectionConnections.
  ///
  /// In en, this message translates to:
  /// **'Connected services'**
  String get sectionConnections;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @sectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sectionSettings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @exitGuest.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get exitGuest;

  /// No description provided for @homeHello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeHello;

  /// No description provided for @homeHelloName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String homeHelloName(String name);

  /// No description provided for @statPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get statPlans;

  /// No description provided for @statSignals.
  ///
  /// In en, this message translates to:
  /// **'Signals'**
  String get statSignals;

  /// No description provided for @statDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadlines'**
  String get statDeadlines;

  /// No description provided for @kindPlanAlert.
  ///
  /// In en, this message translates to:
  /// **'Plan alert'**
  String get kindPlanAlert;

  /// No description provided for @kindOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Opportunity'**
  String get kindOpportunity;

  /// No description provided for @kindDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get kindDeadline;

  /// No description provided for @kindRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get kindRoute;

  /// No description provided for @helpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get helpful;

  /// No description provided for @notForMe.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get notForMe;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sorted by how well they match your interests'**
  String get discoverSubtitle;

  /// No description provided for @matchBadge.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get matchBadge;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get eventDetails;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get openSource;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searching;

  /// No description provided for @rainChance.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rainChance;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @planNew.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get planNew;

  /// No description provided for @planEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get planEdit;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get planTitle;

  /// No description provided for @planTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Busan business trip'**
  String get planTitleHint;

  /// No description provided for @planTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get planTitleRequired;

  /// No description provided for @planDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get planDate;

  /// No description provided for @planStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get planStart;

  /// No description provided for @planEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get planEnd;

  /// No description provided for @planAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get planAllDay;

  /// No description provided for @planLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get planLocation;

  /// No description provided for @planLocationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get planLocationAdd;

  /// No description provided for @planLocationRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove place'**
  String get planLocationRemove;

  /// No description provided for @planNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get planNote;

  /// No description provided for @planNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Anything to remember'**
  String get planNoteHint;

  /// No description provided for @planSaveToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Also save to Google Calendar'**
  String get planSaveToCalendar;

  /// No description provided for @planCalendarSynced.
  ///
  /// In en, this message translates to:
  /// **'Changes are saved to your Google Calendar too.'**
  String get planCalendarSynced;

  /// No description provided for @planSampleHint.
  ///
  /// In en, this message translates to:
  /// **'Sample plan — saving makes it your own plan.'**
  String get planSampleHint;

  /// No description provided for @planDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get planDelete;

  /// No description provided for @planDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String planDeleteConfirm(String title);

  /// No description provided for @planSaved.
  ///
  /// In en, this message translates to:
  /// **'Plan saved'**
  String get planSaved;

  /// No description provided for @planDeleted.
  ///
  /// In en, this message translates to:
  /// **'Plan deleted'**
  String get planDeleted;

  /// No description provided for @planEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start'**
  String get planEndBeforeStart;

  /// No description provided for @planSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {message}'**
  String planSaveError(String message);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @openInCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Calendar'**
  String get openInCalendar;

  /// No description provided for @plansEmptyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add your first plan, or connect Google Calendar to import them.'**
  String get plansEmptyAdd;

  /// No description provided for @interestsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String interestsSelectedCount(int count);

  /// No description provided for @categoryPerformance.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get categoryPerformance;

  /// No description provided for @categoryExhibition.
  ///
  /// In en, this message translates to:
  /// **'Exhibition'**
  String get categoryExhibition;

  /// No description provided for @categoryClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get categoryClasses;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'Data: {name}'**
  String dataSource(String name);

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @eventsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Real events updated {date}'**
  String eventsUpdated(String date);

  /// No description provided for @realData.
  ///
  /// In en, this message translates to:
  /// **'Live data'**
  String get realData;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @categoryStartupSupport.
  ///
  /// In en, this message translates to:
  /// **'Startup programs'**
  String get categoryStartupSupport;

  /// No description provided for @applicationPeriod.
  ///
  /// In en, this message translates to:
  /// **'Applications {from} – {to}'**
  String applicationPeriod(String from, String to);

  /// No description provided for @nationwide.
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get nationwide;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyNow;

  /// No description provided for @aiTranslated.
  ///
  /// In en, this message translates to:
  /// **'Translated from Korean with Gemini'**
  String get aiTranslated;
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
