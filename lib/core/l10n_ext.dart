import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'package:liferadar_core/liferadar_core.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
  String tr(LocalizedText t) => t.of(lang);
  String transitSourceFor(String provider) => switch (provider) {
    'tmap' => l10n.transitSourceTmap,
    'kakao' => l10n.transitSourceKakao,
    _ => l10n.transitSource,
  };

  String formatDate(DateTime d) => DateFormat.MMMEd(lang).format(d);
  String formatDateTime(DateTime d) =>
      DateFormat.MMMEd(lang).add_Hm().format(d);

  String categoryLabel(EventCategory c) => switch (c) {
    EventCategory.contest => l10n.categoryContest,
    EventCategory.conference => l10n.categoryConference,
    EventCategory.hackathon => l10n.categoryHackathon,
    EventCategory.concert => l10n.categoryConcert,
    EventCategory.festival => l10n.categoryFestival,
    EventCategory.meetup => l10n.categoryMeetup,
    EventCategory.job => l10n.categoryJob,
    EventCategory.scholarship => l10n.categoryScholarship,
    EventCategory.performance => l10n.categoryPerformance,
    EventCategory.exhibition => l10n.categoryExhibition,
    EventCategory.classes => l10n.categoryClasses,
    EventCategory.startupSupport => l10n.categoryStartupSupport,
  };
}
