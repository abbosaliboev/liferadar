import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/google_api.dart';
import '../services/kakao_api.dart';
import 'sample_data.dart';

export 'interests.dart' show interestsProvider, interestOptions, InterestOption, sharedPrefsProvider;

final kakaoApiProvider = Provider<KakaoApi>((ref) => KakaoApi());
final googleApiProvider = Provider<GoogleApi>((ref) => GoogleApi());

/// null = qurilma tili.
final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void toggle(String currentLanguageCode) =>
      state = Locale(currentLanguageCode == 'ko' ? 'en' : 'ko');
}


// TODO(D3): Firestore stream'lari bilan almashtiriladi.
final eventsProvider = Provider<List<RadarEvent>>((ref) => sampleEvents);

/// Rejalar: Google Calendar ulanmaguncha sample, ulangandan keyin haqiqiy kalendar.
final plansProvider = NotifierProvider<PlansController, List<Plan>>(PlansController.new);

class PlansController extends Notifier<List<Plan>> {
  @override
  List<Plan> build() => samplePlans;

  void setPlans(List<Plan> plans) => state = plans;
  void resetToSample() => state = samplePlans;
}

final eventByIdProvider = Provider.family<RadarEvent?, String>((ref, id) {
  for (final e in ref.watch(eventsProvider)) {
    if (e.id == id) return e;
  }
  return null;
});

final insightsProvider =
    NotifierProvider<InsightsController, List<Insight>>(InsightsController.new);

class InsightsController extends Notifier<List<Insight>> {
  @override
  List<Insight> build() => sampleInsights;

  void setFeedback(String id, InsightFeedback feedback) {
    state = [
      for (final i in state)
        if (i.id == id) i.copyWith(feedback: feedback) else i,
    ];
  }
}

/// Home/Discover'dan "xaritada ko'rsatish" bosilganda Map shu eventga fokus qiladi.
final mapFocusProvider = NotifierProvider<MapFocusController, String?>(MapFocusController.new);

class MapFocusController extends Notifier<String?> {
  @override
  String? build() => null;

  void focus(String? eventId) => state = eventId;
}

/// Event qiziqishlarga qanchalik mos (0..1). D4 da server tomonda kengaytiriladi.
double interestScore(RadarEvent event, Set<String> interests) {
  if (event.tags.isEmpty) return 0;
  final hits = event.tags.where(interests.contains).length;
  return hits / event.tags.length;
}

/// Prognoz kaliti: koordinata ~1 km aniqlikkacha yaxlitlanadi (yaqin joylar bitta so'rovni ulashadi).
typedef ForecastKey = ({double lat, double lng, String lang});

ForecastKey forecastKey(GeoPoint p, String lang) =>
    (lat: (p.lat * 100).round() / 100, lng: (p.lng * 100).round() / 100, lang: lang);

/// 10 kunlik prognoz — Riverpod keshlaydi (bir joy uchun bitta so'rov).
final forecastProvider = FutureProvider.family<List<DailyWeather>, ForecastKey>((ref, k) {
  return ref.read(googleApiProvider).dailyForecast(GeoPoint(k.lat, k.lng), lang: k.lang);
});
