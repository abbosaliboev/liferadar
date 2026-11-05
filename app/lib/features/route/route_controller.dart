import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../models/models.dart';
import '../../services/kakao_api.dart';
import '../../services/route_matcher.dart';

enum RouteStatus { idle, loading, done, error }

class RouteState {
  const RouteState({
    this.origin,
    this.destination,
    required this.date,
    this.mode = TravelMode.transit,
    this.status = RouteStatus.idle,
    this.route,
    this.opportunities = const [],
    this.error,
  });

  final Place? origin;
  final Place? destination;
  final DateTime date;
  final TravelMode mode;
  final RouteStatus status;
  final TravelRoute? route;
  final List<RouteOpportunity> opportunities;
  final String? error;

  bool get canSearch => origin != null && destination != null && status != RouteStatus.loading;

  RouteState copyWith({
    Place? origin,
    Place? destination,
    DateTime? date,
    TravelMode? mode,
    RouteStatus? status,
    TravelRoute? route,
    List<RouteOpportunity>? opportunities,
    String? error,
    bool clearResult = false,
  }) =>
      RouteState(
        origin: origin ?? this.origin,
        destination: destination ?? this.destination,
        date: date ?? this.date,
        mode: mode ?? this.mode,
        status: status ?? (clearResult ? RouteStatus.idle : this.status),
        route: clearResult ? null : (route ?? this.route),
        opportunities: clearResult ? const [] : (opportunities ?? this.opportunities),
        error: error,
      );
}

final routeProvider = NotifierProvider<RouteController, RouteState>(RouteController.new);

class RouteController extends Notifier<RouteState> {
  static const _matcher = RouteMatcher();

  /// Qo'shimcha yo'l (detour) faqat eng yaxshi N ta uchun hisoblanadi — API kvotasini tejash.
  static const detourTopN = 5;

  @override
  RouteState build() {
    final now = DateTime.now();
    return RouteState(date: DateTime(now.year, now.month, now.day));
  }

  void setOrigin(Place p) => state = state.copyWith(origin: p, clearResult: true);
  void setDestination(Place p) => state = state.copyWith(destination: p, clearResult: true);
  void setDate(DateTime d) => state = state.copyWith(date: DateTime(d.year, d.month, d.day), clearResult: true);
  void setMode(TravelMode m) => state = state.copyWith(mode: m, clearResult: true);

  void swap() {
    final o = state.origin, d = state.destination;
    state = RouteState(origin: d, destination: o, date: state.date, mode: state.mode);
  }

  /// Pitch demo: 서울역 → 부산역, 20-noyabr, KTX.
  void useDemo() {
    state = RouteState(
      origin: const Place(name: '서울역', address: '서울 용산구 한강대로 405', location: GeoPoint(37.5547, 126.9707)),
      destination: const Place(name: '부산역', address: '부산 동구 중앙대로 206', location: GeoPoint(35.1151, 129.0403)),
      date: DateTime(2026, 11, 20),
      mode: TravelMode.transit,
    );
  }

  Future<void> search() async {
    final origin = state.origin, dest = state.destination;
    if (origin == null || dest == null) return;
    final mode = state.mode;
    state = state.copyWith(status: RouteStatus.loading);
    final kakao = ref.read(kakaoApiProvider);
    try {
      final route = mode == TravelMode.car
          ? await kakao.directions(origin.location, dest.location)
          // 09:00 da jo'nash (KST)
          : await ref.read(googleApiProvider).transit(origin.location, dest.location,
              departure: state.date.add(const Duration(hours: 9)));
      final dayStart = state.date;
      final dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
      var opps = _matcher.match(
        route: route.points,
        events: ref.read(eventsProvider),
        interests: ref.read(interestsProvider),
        tripStart: dayStart,
        tripEnd: dayEnd,
        interestScore: interestScore,
      );
      // Avval yo'lni ko'rsatamiz, keyin detour'larni to'ldiramiz.
      state = state.copyWith(status: RouteStatus.done, route: route, opportunities: opps);

      final top = opps.take(detourTopN).toList();
      final detours = await Future.wait(top.map((o) => _detour(kakao, route, origin, dest, o)));
      opps = [...detours, ...opps.skip(detourTopN)];
      if (state.route == route) state = state.copyWith(opportunities: opps);
    } catch (e) {
      state = state.copyWith(status: RouteStatus.error, error: e.toString());
    }
  }

  /// Avtomobil: A→Event→B − A→B (Kakao waypoint).
  /// Transit: Google TRANSIT oraliq nuqtani qo'llamaydi, shuning uchun
  /// yo'ldagi eng yaqin nuqtadan (bekat) eventgacha borib-qaytish (Kakao, ×2).
  Future<RouteOpportunity> _detour(
      KakaoApi kakao, TravelRoute route, Place origin, Place dest, RouteOpportunity o) async {
    try {
      if (route.mode == TravelMode.car) {
        final via = await kakao.directions(origin.location, dest.location,
            waypoint: o.event.location, withGeometry: false);
        return o.withDetour(
          (via.distanceMeters - route.distanceMeters) / 1000,
          ((via.durationSeconds - route.durationSeconds) / 60).round(),
        );
      }
      final stop = RouteMatcher.nearestPointOnPolyline(o.event.location, route.points);
      final leg = await kakao.directions(stop, o.event.location, withGeometry: false);
      return o.withDetour(2 * leg.distanceMeters / 1000, (2 * leg.durationSeconds / 60).round());
    } catch (_) {
      return o; // detour bo'lmasa ham event ko'rinadi
    }
  }
}
