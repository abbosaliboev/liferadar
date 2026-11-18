import 'package:liferadar_core/liferadar_core.dart';

/// Provider facts for one boarding. Optional fields stay absent when unavailable.
class TransitBoarding {
  const TransitBoarding({
    required this.line,
    this.lineName,
    this.mode,
    this.departureStop,
    this.arrivalStop,
    this.departureTime,
    this.arrivalTime,
    this.headsign,
    this.stopCount,
    this.agency,
    this.departureLocation,
    this.arrivalLocation,
    this.mapPoints = const [],
    this.mapGeometryLoaded = false,
    this.provider = 'google',
    this.providerRouteId,
    this.serviceActive,
  });

  final String line;
  final String? lineName, mode, departureStop, arrivalStop, headsign, agency;
  final DateTime? departureTime, arrivalTime;
  final int? stopCount;
  final GeoPoint? departureLocation, arrivalLocation;
  final List<GeoPoint> mapPoints;
  final bool mapGeometryLoaded;
  final String provider;
  final String? providerRouteId;
  final bool? serviceActive;

  /// Two endpoints are a connection, not a supplied detailed route shape.
  bool get hasDetailedMapGeometry {
    if (mapPoints.length < 3) return false;
    for (var i = 1; i < mapPoints.length; i++) {
      if (RouteMatcher.haversineKm(mapPoints[i - 1], mapPoints[i]) > 5) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'line': line,
    if (lineName != null) 'lineName': lineName,
    if (mode != null) 'mode': mode,
    if (departureStop != null) 'departureStop': departureStop,
    if (arrivalStop != null) 'arrivalStop': arrivalStop,
    if (departureTime != null)
      'departureTime': departureTime!.toIso8601String(),
    if (arrivalTime != null) 'arrivalTime': arrivalTime!.toIso8601String(),
    if (headsign != null) 'headsign': headsign,
    if (stopCount != null) 'stopCount': stopCount,
    if (agency != null) 'agency': agency,
    if (departureLocation != null)
      'departureLocation': [departureLocation!.lat, departureLocation!.lng],
    if (arrivalLocation != null)
      'arrivalLocation': [arrivalLocation!.lat, arrivalLocation!.lng],
    'mapPoints': [
      for (final p in mapPoints) [p.lat, p.lng],
    ],
    'mapGeometryLoaded': mapGeometryLoaded,
    'provider': provider,
    if (providerRouteId != null) 'providerRouteId': providerRouteId,
    if (serviceActive != null) 'serviceActive': serviceActive,
  };

  factory TransitBoarding.fromJson(Map<String, dynamic> j) => TransitBoarding(
    line: j['line'] as String,
    lineName: j['lineName'] as String?,
    mode: j['mode'] as String?,
    departureStop: j['departureStop'] as String?,
    arrivalStop: j['arrivalStop'] as String?,
    departureTime: DateTime.tryParse(j['departureTime'] as String? ?? ''),
    arrivalTime: DateTime.tryParse(j['arrivalTime'] as String? ?? ''),
    headsign: j['headsign'] as String?,
    stopCount: (j['stopCount'] as num?)?.toInt(),
    agency: j['agency'] as String?,
    departureLocation: _point(j['departureLocation']),
    arrivalLocation: _point(j['arrivalLocation']),
    mapPoints: [
      for (final p in j['mapPoints'] as List? ?? const []) _point(p)!,
    ],
    mapGeometryLoaded: j['mapGeometryLoaded'] == true,
    provider: j['provider'] as String? ?? 'google',
    providerRouteId: j['providerRouteId'] as String?,
    serviceActive: j['serviceActive'] as bool?,
  );

  static GeoPoint? _point(dynamic value) => value is List && value.length == 2
      ? GeoPoint((value[0] as num).toDouble(), (value[1] as num).toDouble())
      : null;
}

/// Refresh geometry only for the exact saved service, never a different trip.
bool sameTransitBoardings(List<TransitBoarding> a, List<TransitBoarding> b) {
  if (a.isEmpty || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].provider != b[i].provider ||
        a[i].mode != b[i].mode ||
        a[i].line != b[i].line ||
        a[i].departureStop != b[i].departureStop ||
        a[i].arrivalStop != b[i].arrivalStop ||
        a[i].departureTime != b[i].departureTime ||
        a[i].arrivalTime != b[i].arrivalTime) {
      return false;
    }
  }
  return true;
}

class TransitJourney {
  const TransitJourney({
    required this.route,
    this.boardings = const [],
    this.arrival,
    this.provider = 'google',
    this.fallbackReason,
    this.transferTimesValid = true,
  });
  final TravelRoute route;
  final List<TransitBoarding> boardings;
  final DateTime? arrival;
  final String provider;
  final String? fallbackReason;
  final bool transferTimesValid;
}

/// Prefer distinct journeys over successive departures on the same lines.
/// Keep provider ordering and fill remaining slots with timetable alternatives.
List<TransitJourney> compactTransitJourneys(List<TransitJourney> journeys) {
  final selected = <TransitJourney>[];
  final laterDepartures = <TransitJourney>[];
  final seen = <String>{};
  for (final j in journeys) {
    final signature = j.boardings.isEmpty
        ? j.route.transitLines.join('|')
        : j.boardings
              .map(
                (b) =>
                    '${b.mode}:${b.line}:${b.departureStop}:${b.arrivalStop}',
              )
              .join('|');
    if (seen.add(signature)) {
      selected.add(j);
    } else {
      laterDepartures.add(j);
    }
  }
  return [...selected, ...laterDepartures].take(3).toList(growable: false);
}
