import 'dart:convert';

import 'package:http/http.dart' as http;

import 'timeout_client.dart';
import 'tmap_api.dart';

import '../core/env.dart';
import '../data/transit_journey.dart';
import 'package:liferadar_core/liferadar_core.dart';

/// Google Maps Platform: Routes (TRANSIT)와 Weather.
/// 한국에서 Google은 자동차 길찾기를 제공하지 않아 자동차는 Kakao를 사용한다.
class GoogleApi {
  GoogleApi({http.Client? client, String? apiKey, TmapApi? tmap})
    : _client = TimeoutClient(client ?? http.Client()),
      _key = apiKey ?? Env.googleApiKey,
      _tmap = tmap ?? TmapApi();

  final http.Client _client;
  final String _key;
  final TmapApi _tmap;
  DateTime? _quotaRetryAt;

  /// 대중교통 (KTX, SRT, 버스, 지하철) 경로.
  Future<TravelRoute> transit(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  }) async {
    return (await transitJourneys(
      origin,
      destination,
      departure: departure,
    )).first.route;
  }

  /// Alternatives retain the boarding order, stops and provider timetable.
  Future<List<TransitJourney>> transitJourneys(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  }) async {
    String? fallback;
    if (_tmap.configured) {
      if (_quotaRetryAt != null && DateTime.now().isBefore(_quotaRetryAt!)) {
        fallback = 'quota';
      } else {
        try {
          return await _tmap.transitJourneys(
            origin,
            destination,
            departure: departure,
          );
        } catch (e) {
          final quota = e is TmapApiException && e.quotaExceeded;
          fallback = quota ? 'quota' : 'unavailable';
          if (quota) {
            _quotaRetryAt = DateTime.now().add(const Duration(minutes: 1));
          }
        }
      }
    }
    final choices = await googleTransitJourneys(
      origin,
      destination,
      departure: departure,
    );
    return [
      for (final j in choices)
        TransitJourney(
          route: j.route,
          boardings: j.boardings,
          arrival: j.arrival,
          provider: j.provider,
          fallbackReason: fallback,
        ),
    ];
  }

  /// Explicit Google lookup for old saved Google services; never changes provider.
  Future<List<TransitJourney>> googleTransitJourneys(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  }) async {
    if (_key.isEmpty) throw const GoogleApiException('GOOGLE_API_KEY missing');
    Map<String, dynamic> loc(GeoPoint p) => {
      'location': {
        'latLng': {'latitude': p.lat, 'longitude': p.lng},
      },
    };
    final res = await _client.post(
      Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _key,
        'X-Goog-FieldMask':
            'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,'
            'routes.legs.steps.travelMode,routes.legs.steps.staticDuration,routes.legs.steps.polyline.encodedPolyline,routes.legs.steps.transitDetails.transitLine.name,'
            'routes.legs.steps.transitDetails.transitLine.nameShort,'
            'routes.legs.steps.transitDetails.transitLine.vehicle.type,'
            'routes.legs.steps.transitDetails.transitLine.agencies.name,'
            'routes.legs.steps.transitDetails.stopDetails,'
            'routes.legs.steps.transitDetails.headsign,'
            'routes.legs.steps.transitDetails.stopCount',
      },
      body: jsonEncode({
        'origin': loc(origin),
        'destination': loc(destination),
        'travelMode': 'TRANSIT',
        'computeAlternativeRoutes': true,
        'departureTime': departure.toUtc().toIso8601String(),
        'polylineQuality': 'HIGH_QUALITY',
        'languageCode': 'ko',
      }),
    );
    if (res.statusCode != 200) {
      throw GoogleApiException('HTTP ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw const GoogleApiException('No transit route found');
    }
    return [
      for (final r in routes)
        _parseJourney(r as Map<String, dynamic>, departure: departure),
    ];
  }

  static TransitJourney _parseJourney(
    Map<String, dynamic> r, {
    required DateTime departure,
  }) {
    final lines = <String>[];
    final boardings = <TransitBoarding>[];
    final modes = <String>{};
    DateTime? arrival;
    DateTime? readyAt = departure;
    var transferTimesValid = true;
    var unknownTransitMode = false;
    for (final leg in (r['legs'] as List? ?? const [])) {
      for (final step in (leg['steps'] as List? ?? const [])) {
        final details = step['transitDetails'];
        if (details != null) {
          final leaves = DateTime.tryParse(
            '${details['stopDetails']?['departureTime'] ?? ''}',
          );
          arrival = DateTime.tryParse(
            '${details['stopDetails']?['arrivalTime'] ?? ''}',
          );
          if (leaves == null ||
              arrival == null ||
              readyAt == null ||
              leaves.isBefore(readyAt) ||
              arrival.isBefore(leaves)) {
            transferTimesValid = false;
          }
          readyAt = arrival;
        } else if (arrival != null) {
          final seconds = double.tryParse(
            '${step['staticDuration'] ?? ''}'.replaceAll('s', ''),
          );
          arrival = seconds == null
              ? null
              : arrival.add(Duration(seconds: seconds.ceil()));
          if (seconds == null || seconds < 0) transferTimesValid = false;
          readyAt = arrival;
        } else {
          final seconds = double.tryParse(
            '${step['staticDuration'] ?? ''}'.replaceAll('s', ''),
          );
          if (seconds == null || seconds < 0 || readyAt == null) {
            transferTimesValid = false;
            readyAt = null;
          } else {
            readyAt = readyAt.add(Duration(seconds: seconds.ceil()));
          }
        }
        final line = details?['transitLine'];
        final vehicle = line?['vehicle']?['type'];
        final mode = switch (vehicle) {
          'BUS' || 'INTERCITY_BUS' || 'TROLLEYBUS' => 'bus',
          'SUBWAY' || 'METRO_RAIL' || 'TRAM' || 'MONORAIL' => 'subway',
          'RAIL' ||
          'HEAVY_RAIL' ||
          'HIGH_SPEED_TRAIN' ||
          'COMMUTER_TRAIN' ||
          'LONG_DISTANCE_TRAIN' => 'rail',
          _ => null,
        };
        if (mode != null) modes.add(mode);
        if (details != null && mode == null) unknownTransitMode = true;
        String? nonEmpty(dynamic value) =>
            value is String && value.trim().isNotEmpty ? value.trim() : null;
        final name = nonEmpty(line?['nameShort']) ?? nonEmpty(line?['name']);
        // Keep repeated boardings: A → B → A is not the same trip as A → B.
        if (name != null) lines.add(name);
        if (details != null) {
          final stops = details['stopDetails'];
          GeoPoint? location(dynamic stop) {
            final p = stop?['location']?['latLng'];
            return p?['latitude'] is num && p?['longitude'] is num
                ? GeoPoint(
                    (p['latitude'] as num).toDouble(),
                    (p['longitude'] as num).toDouble(),
                  )
                : null;
          }

          final agencies = line?['agencies'] as List? ?? const [];
          boardings.add(
            TransitBoarding(
              line: name ?? '',
              mapPoints: decodePolyline(
                step['polyline']?['encodedPolyline'] as String? ?? '',
              ),
              mapGeometryLoaded: true,
              departureLocation: location(stops?['departureStop']),
              arrivalLocation: location(stops?['arrivalStop']),
              lineName: nonEmpty(line?['name']),
              mode: mode,
              departureStop: nonEmpty(stops?['departureStop']?['name']),
              arrivalStop: nonEmpty(stops?['arrivalStop']?['name']),
              departureTime: DateTime.tryParse(
                '${stops?['departureTime'] ?? ''}',
              ),
              arrivalTime: DateTime.tryParse('${stops?['arrivalTime'] ?? ''}'),
              headsign: nonEmpty(details['headsign']),
              stopCount: (details['stopCount'] as num?)?.toInt(),
              agency: agencies.isEmpty
                  ? null
                  : nonEmpty(agencies.first['name']),
            ),
          );
        }
      }
    }
    return TransitJourney(
      transferTimesValid: transferTimesValid,
      arrival: arrival,
      boardings: List.unmodifiable(boardings),
      route: TravelRoute(
        mode: TravelMode.transit,
        distanceMeters: (r['distanceMeters'] as num?)?.toInt() ?? 0,
        durationSeconds: double.parse(
          (r['duration'] as String).replaceAll('s', ''),
        ).ceil(),
        points: decodePolyline(
          r['polyline']?['encodedPolyline'] as String? ?? '',
        ),
        transitLines: lines,
        transportModes: unknownTransitMode ? const {} : modes,
      ),
    );
  }

  /// 일별 예보 (오늘부터 약 10일). [lang]: 'ko' 또는 'en'.
  Future<List<DailyWeather>> dailyForecast(
    GeoPoint p, {
    String lang = 'ko',
  }) async {
    if (_key.isEmpty) throw const GoogleApiException('GOOGLE_API_KEY missing');
    final uri =
        Uri.https('weather.googleapis.com', '/v1/forecast/days:lookup', {
          'key': _key,
          'location.latitude': '${p.lat}',
          'location.longitude': '${p.lng}',
          'days': '10',
          'pageSize': '10',
          'languageCode': lang,
        });
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw GoogleApiException('HTTP ${res.statusCode}: ${res.body}');
    }
    return parseForecast(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  static List<DailyWeather> parseForecast(Map<String, dynamic> json) {
    int? deg(dynamic t) => (t?['degrees'] as num?)?.round();
    return [
      for (final d in (json['forecastDays'] as List? ?? const []))
        () {
          final date = d['displayDate'] as Map<String, dynamic>;
          // 낮 시간 예보가 있으면 그것을, 없으면 하루 전체 예보를 사용한다.
          final f =
              (d['daytimeForecast'] ?? d['fullDayForecast'] ?? const {})
                  as Map<String, dynamic>;
          final cond =
              f['weatherCondition'] as Map<String, dynamic>? ?? const {};
          return DailyWeather(
            date: DateTime(
              date['year'] as int,
              date['month'] as int,
              date['day'] as int,
            ),
            condition: (cond['description']?['text'] as String?) ?? '',
            type: (cond['type'] as String?) ?? 'UNKNOWN',
            maxC: deg(d['maxTemperature']),
            minC: deg(d['minTemperature']),
            rainChance: (f['precipitation']?['probability']?['percent'] as num?)
                ?.round(),
          );
        }(),
    ];
  }

  /// Google Encoded Polyline Algorithm.
  static List<GeoPoint> decodePolyline(String s) {
    final pts = <GeoPoint>[];
    var i = 0, lat = 0, lng = 0;
    while (i < s.length) {
      for (var which = 0; which < 2; which++) {
        var shift = 0, result = 0, b = 0;
        do {
          b = s.codeUnitAt(i++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20);
        // ~x 대신 -(x + 1): 웹(dart2js)에서 `~`는 부호 없는 32비트를 반환한다.
        final delta = (result & 1) != 0 ? -((result >> 1) + 1) : (result >> 1);
        if (which == 0) {
          lat += delta;
        } else {
          lng += delta;
        }
      }
      pts.add(GeoPoint(lat / 1e5, lng / 1e5));
    }
    return pts;
  }
}

class GoogleApiException implements Exception {
  const GoogleApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
