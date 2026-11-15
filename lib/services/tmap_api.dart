import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:liferadar_core/liferadar_core.dart';

import '../core/env.dart';
import '../data/transit_journey.dart';
import 'timeout_client.dart';

class TmapApi {
  TmapApi({http.Client? client, String? appKey})
    : _client = TimeoutClient(
        client ?? http.Client(),
        timeout: const Duration(seconds: 12),
      ),
      _key = appKey ?? Env.tmapAppKey;
  final http.Client _client;
  final String _key;
  bool get configured => _key.isNotEmpty;

  Future<List<TransitJourney>> transitJourneys(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  }) async {
    if (!configured) throw const TmapApiException('TMAP key missing');
    final kst = departure.toUtc().add(const Duration(hours: 9));
    String two(int n) => n.toString().padLeft(2, '0');
    final response = await _client
        .post(
          Uri.parse('https://apis.openapi.sk.com/transit/routes'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'appKey': _key,
          },
          body: jsonEncode({
            'startX': '${origin.lng}',
            'startY': '${origin.lat}',
            'endX': '${destination.lng}',
            'endY': '${destination.lat}',
            'count': 3,
            'lang': 0,
            'format': 'json',
            'searchDttm':
                '${kst.year}${two(kst.month)}${two(kst.day)}${two(kst.hour)}${two(kst.minute)}',
          }),
        )
        .timeout(const Duration(seconds: 12));
    Map<String, dynamic> data;
    try {
      data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw TmapApiException(
        'TMAP HTTP ${response.statusCode}',
        quotaExceeded: response.statusCode == 429,
      );
    }
    if (response.statusCode != 200 || data['error'] != null) {
      final error = data['error'];
      final detail =
          '${error is Map ? error['code'] : ''} ${error is Map ? error['message'] : error}'
              .toUpperCase();
      throw TmapApiException(
        'TMAP HTTP ${response.statusCode}',
        quotaExceeded:
            response.statusCode == 429 ||
            detail.contains('QUOTA') ||
            detail.contains('한도') ||
            detail.contains('초과'),
      );
    }
    return parseJourneys(data);
  }

  static List<GeoPoint> parseShape(dynamic value) {
    if (value is! String || value.trim().isEmpty) return const [];
    final points = <GeoPoint>[];
    for (final pair in value.trim().split(RegExp(r'\s+'))) {
      final xy = pair.split(',');
      if (xy.length != 2) return const [];
      final lng = double.tryParse(xy[0]), lat = double.tryParse(xy[1]);
      if (lng == null ||
          lat == null ||
          !lng.isFinite ||
          !lat.isFinite ||
          lng.abs() > 180 ||
          lat.abs() > 90) {
        return const [];
      }
      final p = GeoPoint(lat, lng);
      if (points.isEmpty || points.last.lat != lat || points.last.lng != lng) {
        points.add(p);
      }
    }
    return List.unmodifiable(points);
  }

  static List<TransitJourney> parseJourneys(Map<String, dynamic> data) {
    final itineraries =
        data['metaData']?['plan']?['itineraries'] as List? ?? const [];
    final journeys = <TransitJourney>[];
    for (final raw in itineraries) {
      final legs = raw['legs'] as List? ?? const [];
      final boardings = <TransitBoarding>[];
      final points = <GeoPoint>[];
      final modes = <String>{};
      var unknownMode = false;
      void append(List<GeoPoint> shape) {
        for (final p in shape) {
          if (points.isEmpty ||
              points.last.lat != p.lat ||
              points.last.lng != p.lng) {
            points.add(p);
          }
        }
      }

      GeoPoint? point(dynamic p) {
        final lat = double.tryParse('${p?['lat'] ?? ''}'),
            lng = double.tryParse('${p?['lon'] ?? ''}');
        return lat == null || lng == null || !lat.isFinite || !lng.isFinite
            ? null
            : GeoPoint(lat, lng);
      }

      for (final leg in legs) {
        final shape = parseShape(leg['passShape']?['linestring']);
        if (leg['mode'] == 'WALK') {
          for (final step in leg['steps'] as List? ?? const []) {
            append(parseShape(step['linestring']));
          }
          append(shape);
          continue;
        }
        final mode = switch (leg['mode']) {
          'BUS' || 'EXPRESSBUS' => 'bus',
          'SUBWAY' => 'subway',
          'TRAIN' => 'rail',
          _ => null,
        };
        if (mode == null) {
          unknownMode = true;
        } else {
          modes.add(mode);
        }
        final stations = leg['passStopList']?['stations'] as List? ?? const [];
        final line = '${leg['route'] ?? ''}'.trim();
        boardings.add(
          TransitBoarding(
            line: line,
            mode: mode,
            provider: 'tmap',
            providerRouteId: leg['routeId']?.toString(),
            serviceActive: switch (leg['service']) {
              1 || '1' => true,
              0 || '0' => false,
              _ => null,
            },
            departureStop: leg['start']?['name'] as String?,
            arrivalStop: leg['end']?['name'] as String?,
            departureLocation: point(leg['start']),
            arrivalLocation: point(leg['end']),
            stopCount: stations.length >= 2 ? stations.length - 1 : null,
            mapPoints: shape,
            mapGeometryLoaded: true,
          ),
        );
        append(shape);
      }
      final seconds = (raw['totalTime'] as num?)?.ceil();
      if (boardings.isEmpty || seconds == null || seconds <= 0) continue;
      journeys.add(
        TransitJourney(
          provider: 'tmap',
          boardings: List.unmodifiable(boardings),
          // sectionTime is a duration, not a published departure/arrival timetable.
          route: TravelRoute(
            mode: TravelMode.transit,
            durationSeconds: seconds,
            distanceMeters: (raw['totalDistance'] as num?)?.toInt() ?? 0,
            transitLines: [
              for (final b in boardings)
                if (b.line.isNotEmpty) b.line,
            ],
            transportModes: unknownMode ? const {} : modes,
            points: points,
          ),
        ),
      );
    }
    if (journeys.isEmpty) {
      throw const TmapApiException('No transit route');
    }
    return journeys;
  }
}

class TmapApiException implements Exception {
  const TmapApiException(this.message, {this.quotaExceeded = false});
  final String message;
  final bool quotaExceeded;
  @override
  String toString() => message;
}
