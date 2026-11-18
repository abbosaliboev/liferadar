import 'package:liferadar_core/liferadar_core.dart';

import '../data/transit_journey.dart';
import 'google_api.dart';

/// Select by the requested day's timetable, independently of map detail.
class MappedTransitOptions {
  MappedTransitOptions({required this.primary});
  final GoogleApi primary;

  static bool hasUsableTimetable(
    TransitJourney journey,
    DateTime departure, {
    DateTime? arriveBy,
  }) {
    if (journey.provider != 'google' ||
        !journey.transferTimesValid ||
        journey.boardings.isEmpty ||
        journey.arrival == null) {
      return false;
    }
    var ready = departure;
    for (final b in journey.boardings) {
      final leaves = b.departureTime, arrives = b.arrivalTime;
      if (b.serviceActive == false ||
          b.line.isEmpty ||
          b.mode == null ||
          leaves == null ||
          arrives == null ||
          leaves.isBefore(ready) ||
          arrives.isBefore(leaves)) {
        return false;
      }
      ready = arrives;
    }
    return !journey.arrival!.isBefore(ready) &&
        (arriveBy == null || !journey.arrival!.isAfter(arriveBy));
  }

  Future<List<TransitJourney>> search(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
    DateTime? arriveBy,
  }) async {
    // Kakao publictraffic has no departure-time parameter. TMAP service flags
    // have no per-leg timetable. Neither substitutes for a scheduled journey.
    final choices = await primary.googleTransitJourneys(
      origin,
      destination,
      departure: departure,
    );
    final usable = <TransitJourney>[];
    for (final j in choices) {
      if (!hasUsableTimetable(j, departure, arriveBy: arriveBy)) continue;
      final r = j.route;
      usable.add(
        TransitJourney(
          provider: j.provider,
          boardings: j.boardings,
          arrival: j.arrival,
          transferTimesValid: j.transferTimesValid,
          route: TravelRoute(
            distanceMeters: r.distanceMeters,
            durationSeconds: j.arrival!.difference(departure).inSeconds,
            mode: r.mode,
            transitLines: r.transitLines,
            transportModes: r.transportModes,
            facilityIds: r.facilityIds,
            points: r.points,
          ),
        ),
      );
    }
    if (usable.isEmpty) throw const NoScheduledTransitRoute();
    usable.sort((a, b) => a.arrival!.compareTo(b.arrival!));
    return compactTransitJourneys(usable);
  }
}

class NoScheduledTransitRoute implements Exception {
  const NoScheduledTransitRoute();
}
