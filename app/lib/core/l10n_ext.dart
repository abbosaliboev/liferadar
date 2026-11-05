import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
  String tr(LocalizedText t) => t.of(lang);

  String formatDate(DateTime d) => DateFormat.MMMEd(lang).format(d);
  String formatDateTime(DateTime d) => DateFormat.MMMEd(lang).add_Hm().format(d);

  String categoryLabel(EventCategory c) => switch (c) {
        EventCategory.conference => l10n.categoryConference,
        EventCategory.hackathon => l10n.categoryHackathon,
        EventCategory.concert => l10n.categoryConcert,
        EventCategory.festival => l10n.categoryFestival,
        EventCategory.meetup => l10n.categoryMeetup,
        EventCategory.job => l10n.categoryJob,
        EventCategory.scholarship => l10n.categoryScholarship,
      };
}
