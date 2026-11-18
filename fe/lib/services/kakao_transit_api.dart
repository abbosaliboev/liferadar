import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:liferadar_core/liferadar_core.dart';

import '../core/env.dart';
import '../data/transit_journey.dart';
import 'timeout_client.dart';

/// Current public-transit routes with provider-supplied shapes. This endpoint
/// does not accept a departure date or provide a future service timetable.
class KakaoTransitApi {
  KakaoTransitApi({http.Client? client, String? restKey})
    : _client = TimeoutClient(client ?? http.Client()),
      _key = restKey ?? Env.kakaoRestApiKey;

  final http.Client _client;
  final String _key;
  bool get configured => _key.isNotEmpty;

  Future<List<TransitJourney>> transitJourneys(
    GeoPoint origin,
    GeoPoint destination,
  ) async {
    if (!configured) throw StateError('KAKAO_REST_API_KEY missing');
    final response = await _client.get(
      Uri.https('dapi.kakao.com', '/v2/routing/publictraffic', {
        'start_x': '${origin.lng}',
        'start_y': '${origin.lat}',
        'end_x': '${destination.lng}',
        'end_y': '${destination.lat}',
        'input_coord': 'WGS84',
        'output_coord': 'WGS84',
      }),
      headers: {'Authorization': 'KakaoAK $_key'},
    );
    if (response.statusCode != 200) {
      throw StateError('Kakao transit HTTP ${response.statusCode}');
    }
    return parseJourneys(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  static List<GeoPoint> _shape(dynamic path) {
    final result = <GeoPoint>[];
    for (final pair in path?['points'] as List? ?? const []) {
      if (pair is! List ||
          pair.length != 2 ||
          pair[0] is! num ||
          pair[1] is! num) {
        return const [];
      }
      final x = (pair[0] as num).toDouble(), y = (pair[1] as num).toDouble();
      if (!x.isFinite || !y.isFinite || x.abs() > 180 || y.abs() > 90) {
        return const [];
      }
      if (result.isEmpty || result.last.lat != y || result.last.lng != x) {
        result.add(GeoPoint(y, x));
      }
    }
    return result;
  }

  static List<TransitJourney> parseJourneys(Map<String, dynamic> data) {
    if (data['status'] != 'OK') return const [];
    final result = <TransitJourney>[];
    for (final route in data['routes'] as List? ?? const []) {
      final info = route['properties'];
      final seconds = (info?['totalTime'] as num?)?.ceil();
      if (seconds == null || seconds <= 0) continue;
      final boardings = <TransitBoarding>[], points = <GeoPoint>[];
      var unsupported = false;
      for (final step in route['steps'] as List? ?? const []) {
        final properties = step['properties'];
        final type = properties?['type'];
        final shape = _shape(step['path']);
        points.addAll(shape);
        if (type == 'WALKING') continue;
        final mode = switch (type) {
          'BUS' => 'bus',
          'SUBWAY' => 'subway',
          _ => null,
        };
        if (mode == null) {
          unsupported = true;
          break;
        }
        final vehicles = properties?['vehicles'] as List? ?? const [];
        final stops = properties?['stops'] as List? ?? const [];
        // Keep provider alternatives explicit: e.g. 광역 9500 / M6457.
        final names = [
          for (final v in vehicles)
            '${v['type'] ?? ''} ${v['name'] ?? ''}'.trim(),
        ];
        boardings.add(
          TransitBoarding(
            line: names.join(' / '),
            mode: mode,
            provider: 'kakao',
            departureStop: stops.isEmpty
                ? null
                : stops.first['name'] as String?,
            arrivalStop: stops.isEmpty ? null : stops.last['name'] as String?,
            departureLocation: shape.firstOrNull,
            arrivalLocation: shape.lastOrNull,
            stopCount: stops.length >= 2 ? stops.length - 1 : null,
            mapPoints: shape,
            mapGeometryLoaded: true,
          ),
        );
      }
      if (unsupported || boardings.isEmpty) continue;
      result.add(
        TransitJourney(
          provider: 'kakao',
          boardings: List.unmodifiable(boardings),
          route: TravelRoute(
            mode: TravelMode.transit,
            durationSeconds: seconds,
            distanceMeters: (info?['totalDistance'] as num?)?.toInt() ?? 0,
            points: points,
            transitLines: [for (final b in boardings) b.line],
            transportModes: {for (final b in boardings) b.mode!},
          ),
        ),
      );
    }
    return result;
  }
}
