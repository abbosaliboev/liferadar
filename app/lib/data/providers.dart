import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/google_api.dart';
import '../services/insight_engine.dart';
import '../services/kakao_api.dart';
import 'interests.dart';
import 'sample_data.dart';

export 'interests.dart' show interestsProvider, interestOptions, InterestOption, sharedPrefsProvider;

final kakaoApiProvider = Provider<KakaoApi>((ref) => KakaoApi());
final googleApiProvider = Provider<GoogleApi>((ref) => GoogleApi());



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

/// "Bugun" — testlarda aniq sana bilan override qilinadi.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// Foydalanuvchi feedback'i (insight id → like/dislike/hidden), qurilmada saqlanadi.
final insightFeedbackProvider =
    NotifierProvider<InsightFeedbackController, Map<String, InsightFeedback>>(InsightFeedbackController.new);

class InsightFeedbackController extends Notifier<Map<String, InsightFeedback>> {
  static const _key = 'insight_feedback';

  @override
  Map<String, InsightFeedback> build() {
    final raw = ref.read(sharedPrefsProvider).getStringList(_key) ?? const [];
    return {
      for (final r in raw)
        if (r.contains('|'))
          r.substring(0, r.lastIndexOf('|')): InsightFeedback.values.byName(r.substring(r.lastIndexOf('|') + 1)),
    };
  }

  Future<void> set(String id, InsightFeedback f) async {
    state = {...state, id: f};
    await ref
        .read(sharedPrefsProvider)
        .setStringList(_key, [for (final e in state.entries) '${e.key}|${e.value.name}']);
  }
}

/// Insight'lar = InsightEngine(rejalar, eventlar, qiziqishlar, ob-havo) + feedback.
/// Har qanday kirish o'zgarsa avtomatik qayta hisoblanadi.
final insightsProvider = Provider<List<Insight>>((ref) {
  final plans = ref.watch(plansProvider);
  final now = ref.watch(nowProvider);
  final today = DateTime(now.year, now.month, now.day);

  // 10 kunlik prognoz ichidagi rejalar uchun ob-havo (keshlangan provider orqali).
  final weather = <String, DailyWeather>{};
  for (final p in plans) {
    if (p.location == null) continue;
    final day = DateTime(p.start.year, p.start.month, p.start.day);
    final ahead = day.difference(today).inDays;
    if (ahead < 0 || ahead > 9) continue;
    final days = ref.watch(forecastProvider(forecastKey(p.location!, 'ko'))).value;
    final w = days?.where((d) => d.date == day).firstOrNull;
    if (w != null) weather[p.id] = w;
  }

  final list = const InsightEngine().build(
    plans: plans,
    events: ref.watch(eventsProvider),
    interests: ref.watch(interestsProvider),
    now: now,
    weatherByPlanId: weather,
  );
  final feedback = ref.watch(insightFeedbackProvider);
  final withFeedback = [for (final i in list) i.copyWith(feedback: feedback[i.id])];
  // 👎 bosilganlar pastga.
  return [
    ...withFeedback.where((i) => i.feedback != InsightFeedback.dislike),
    ...withFeedback.where((i) => i.feedback == InsightFeedback.dislike),
  ];
});

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
