import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/google_api.dart';
import '../services/insight_engine.dart';
import '../services/kakao_api.dart';
import '../services/taste.dart';
import 'ai_insights.dart';
import 'event_feed.dart';
import 'interests.dart';
import 'live_events.dart';
import 'live_traffic.dart';
import 'sample_data.dart';
import 'session.dart';

export 'event_feed.dart' show EventFeed;
export 'seen.dart' show seenProvider;
export 'interests.dart'
    show interestsProvider, interestOptions, InterestOption, InterestGroup, interestByTag, sharedPrefsProvider, accountScope;

final kakaoApiProvider = Provider<KakaoApi>((ref) => KakaoApi());
final googleApiProvider = Provider<GoogleApi>((ref) => GoogleApi());



/// Ilova ochilgandagi eventlar — main()'da asset/keshdan yuklanib override qilinadi (testlarda bo'sh).
final initialEventFeedProvider = Provider<EventFeed>((ref) => EventFeed.empty);

/// Internetdan yangilash yoqilganmi (main()'da true; testlar tarmoqqa chiqmaydi).
final liveEventsEnabledProvider = Provider<bool>((ref) => false);

/// Haqiqiy eventlar: avval [initialEventFeedProvider], keyin internetdan yangirog'i (bo'lsa).
final eventFeedProvider = NotifierProvider<EventFeedController, EventFeed>(EventFeedController.new);

class EventFeedController extends Notifier<EventFeed> {
  @override
  EventFeed build() {
    final initial = ref.watch(initialEventFeedProvider);
    if (ref.watch(liveEventsEnabledProvider)) Future.microtask(refresh);
    return initial;
  }

  /// Yangi feed bo'lsa almashtiradi. Natija: yangilandimi.
  Future<bool> refresh() async {
    final fresh = await LiveEvents.fetch(ref.read(sharedPrefsProvider), state);
    if (fresh == null || !ref.mounted) return false;
    state = fresh;
    return true;
  }
}

/// Barcha eventlar: haqiqiy (ochiq API) + demo stsenariy uchun sample'lar ("Sample" belgisi bilan).
final eventsProvider = Provider<List<RadarEvent>>(
  (ref) => [...ref.watch(eventFeedProvider).events, ...sampleEventsAt(ref.watch(nowProvider))],
);

/// Rejalar = asosiy manba (Google Calendar ulanmaguncha sample, keyin kalendar)
/// + ilovada qo'lda qo'shilgan rejalar (qurilmada, akkaunt bo'yicha saqlanadi).
/// Bir xil id'li o'z reja asosiy manbadagini almashtiradi (masalan, tahrirlangan sample).
final plansProvider = NotifierProvider<PlansController, List<Plan>>(PlansController.new);

class PlansController extends Notifier<List<Plan>> {
  List<Plan> _base = samplePlans;
  List<Plan> _own = const [];
  late String _key;

  @override
  List<Plan> build() {
    _key = 'plans:${accountScope(ref.watch(sessionProvider))}';
    _base = samplePlansAt(ref.watch(nowProvider));
    _own = _load();
    return _merge();
  }

  List<Plan> _load() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return [for (final j in jsonDecode(raw) as List) Plan.fromJson(j as Map<String, dynamic>)];
    } catch (_) {
      return const [];
    }
  }

  List<Plan> _merge() {
    final ownIds = {for (final p in _own) p.id};
    return [..._base.where((p) => !ownIds.contains(p.id)), ..._own]..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<void> _persist() async {
    state = _merge();
    await ref.read(sharedPrefsProvider).setString(_key, jsonEncode([for (final p in _own) p.toJson()]));
  }

  void setPlans(List<Plan> plans) {
    _base = plans;
    state = _merge();
  }

  void resetToSample() => setPlans(samplePlansAt(ref.read(nowProvider)));

  /// Ilovadagi o'z rejani qo'shadi yoki yangilaydi (source = 'local').
  Future<void> saveLocal(Plan plan) async {
    final p = plan.copyWith(source: 'local');
    _own = [..._own.where((x) => x.id != p.id), p];
    await _persist();
  }

  Future<void> removeLocal(String id) async {
    _own = _own.where((x) => x.id != id).toList();
    await _persist();
  }
}

/// Xaritadagi "Recommended" qatlami: 30 kun ichidagi, qiziqishga eng mos [mapEventLimit] ta event.
/// Sample'lar demo stsenariy uchun doim qoladi.
const mapEventLimit = 60;
final mapEventsProvider = Provider<List<RadarEvent>>((ref) {
  final now = ref.watch(nowProvider);
  final today = DateTime(now.year, now.month, now.day);
  final horizon = today.add(const Duration(days: 30));
  final interests = ref.watch(interestsProvider);
  final taste = ref.watch(tasteProvider);
  final all = ref.watch(eventsProvider);
  final real = all
      .where((e) => !e.isSample && !e.placeless && !e.end.isBefore(today) && e.start.isBefore(horizon))
      .toList()
    ..sort((a, b) {
      final s = taste.score(b, interests).compareTo(taste.score(a, interests));
      return s != 0 ? s : a.start.compareTo(b.start);
    });
  return [...all.where((e) => e.isSample), ...real.take(mapEventLimit)];
});

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
    await _persist();
  }

  /// Bahoni qaytarish (👍/👎 bekor qilinadi).
  Future<void> clear(String id) async {
    state = {...state}..remove(id);
    await _persist();
  }

  Future<void> _persist() => ref
      .read(sharedPrefsProvider)
      .setStringList(_key, [for (final e in state.entries) '${e.key}|${e.value.name}']);
}

/// Rasmiy yo'l ta'siri: avval keshdagisi, keyin internetdan yangirog'i.
final trafficFeedProvider = NotifierProvider<TrafficFeedController, TrafficFeed>(TrafficFeedController.new);

class TrafficFeedController extends Notifier<TrafficFeed> {
  @override
  TrafficFeed build() {
    final cached = LiveTraffic.cached(ref.read(sharedPrefsProvider));
    if (ref.watch(liveEventsEnabledProvider)) Future.microtask(refresh);
    return cached;
  }

  Future<bool> refresh() async {
    final fresh = await LiveTraffic.fetch(ref.read(sharedPrefsProvider), state);
    if (fresh == null || !ref.mounted) return false;
    state = fresh;
    return true;
  }
}

/// Feedback'dan o'rganilgan did: Home, Discover, Map va Route tartibiga ta'sir qiladi.
final tasteProvider = Provider<Taste>((ref) {
  final events = {for (final e in ref.watch(eventsProvider)) e.id: e};
  return Taste.from(ref.watch(insightFeedbackProvider), events);
});

/// Qoida asosidagi insight'lar = InsightEngine(rejalar, eventlar, qiziqishlar, ob-havo).
/// Har qanday kirish o'zgarsa avtomatik qayta hisoblanadi.
final baseInsightsProvider = Provider<List<Insight>>((ref) {
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

  return const InsightEngine().build(
    plans: plans,
    events: ref.watch(eventsProvider),
    interests: ref.watch(interestsProvider),
    now: now,
    weatherByPlanId: weather,
    taste: ref.watch(tasteProvider),
    traffic: ref.watch(trafficFeedProvider).activeAt(now),
  );
});

/// Home'dagi insight'lar = qoida kartalari + Gemini matni (bor bo'lsa) + feedback.
final insightsProvider = Provider<List<Insight>>((ref) {
  final ai = ref.watch(aiInsightTextProvider);
  final feedback = ref.watch(insightFeedbackProvider);
  final withFeedback = [
    for (final i in ref.watch(baseInsightsProvider))
      switch (ai[i.id]) {
        final w? => i.copyWith(feedback: feedback[i.id], body: w.body, why: w.why, aiModel: w.model),
        null => i.copyWith(feedback: feedback[i.id]),
      },
  ];
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
