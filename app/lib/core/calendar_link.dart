import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

const _googleCalendar = 'com.google.android.calendar';

/// Kalendarni ochadi. Android'da brauzer emas, Google Calendar ilovasi:
/// 1) aynan shu event ([htmlLink]) Google Calendar ilovasida;
/// 2) Google Calendar [at] sanasida;
/// 3) telefondagi istalgan kalendar ilovasi [at] sanasida;
/// 4) oxirgi chora — brauzer. Web'da doim brauzer.
Future<void> openCalendar({String? htmlLink, DateTime? at}) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final day = at ?? DateTime.now();
    final timeUri = 'content://com.android.calendar/time/${day.millisecondsSinceEpoch}';
    final attempts = [
      if (htmlLink != null) AndroidIntent(action: 'action_view', data: htmlLink, package: _googleCalendar),
      AndroidIntent(action: 'action_view', data: timeUri, package: _googleCalendar),
      AndroidIntent(action: 'action_view', data: timeUri),
    ];
    for (final intent in attempts) {
      try {
        if (await intent.canResolveActivity() ?? false) {
          await intent.launch();
          return;
        }
      } catch (e) {
        debugPrint('openCalendar: $e');
      }
    }
  }
  await launchUrl(
    Uri.parse(htmlLink ?? 'https://calendar.google.com/calendar/r/month'),
    mode: LaunchMode.externalApplication,
  );
}
