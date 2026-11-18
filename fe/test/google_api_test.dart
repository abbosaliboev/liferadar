import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liferadar_core/liferadar_core.dart';
import 'package:liferadar/services/google_api.dart';

void main() {
  test(
    'arrival follows provider timetable plus final walk, including waits before boarding',
    () async {
      final api = GoogleApi(
        apiKey: 'fixture-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'routes': [
                {
                  'duration': '1200s',
                  'legs': [
                    {
                      'steps': [
                        {'travelMode': 'WALK', 'staticDuration': '60s'},
                        {
                          'transitDetails': {
                            'transitLine': {
                              'nameShort': '421',
                              'vehicle': {'type': 'BUS'},
                            },
                            'stopDetails': {
                              'departureTime': '2026-11-15T07:00:00Z',
                              'arrivalTime': '2026-11-15T07:20:00Z',
                            },
                          },
                        },
                        {'travelMode': 'WALK', 'staticDuration': '180s'},
                      ],
                    },
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      );
      final journeys = await api.transitJourneys(
        const GeoPoint(37.5, 127),
        const GeoPoint(37.6, 127),
        departure: DateTime.utc(2026, 11, 15, 6),
      );
      expect(journeys.single.arrival, DateTime.utc(2026, 11, 15, 7, 23));
      expect(journeys.single.route.durationSeconds, 1200);
    },
  );

  test(
    'alternatives preserve bus numbers, boarding order and timetable; missing details stay absent',
    () async {
      final api = GoogleApi(
        apiKey: 'fixture-key',
        client: MockClient((request) async {
          expect(jsonDecode(request.body)['computeAlternativeRoutes'], isTrue);
          expect(
            request.headers['X-Goog-FieldMask'],
            contains('steps.polyline.encodedPolyline'),
          );
          expect(
            request.headers['X-Goog-FieldMask'],
            contains('transitDetails.stopDetails'),
          );
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'routes': [
                  {
                    'duration': '1800.5s',
                    'legs': [
                      {
                        'steps': [
                          {
                            'polyline': {
                              'encodedPolyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
                            },
                            'transitDetails': {
                              'transitLine': {
                                'name': '간선버스 421번',
                                'nameShort': '421',
                                'vehicle': {'type': 'BUS'},
                              },
                              'headsign': '성수역',
                              'stopCount': 7,
                              'stopDetails': {
                                'departureStop': {'name': '강남역'},
                                'arrivalStop': {'name': '성수역'},
                                'departureTime': '2026-11-15T06:05:00Z',
                                'arrivalTime': '2026-11-15T06:25:00Z',
                              },
                            },
                          },
                          {
                            'transitDetails': {
                              'transitLine': {
                                'name': '2호선',
                                'vehicle': {'type': 'SUBWAY'},
                              },
                            },
                          },
                          {
                            'transitDetails': {
                              'transitLine': {
                                'nameShort': '421',
                                'vehicle': {'type': 'BUS'},
                              },
                            },
                          },
                        ],
                      },
                    ],
                  },
                  {
                    'duration': '3600s',
                    'legs': [
                      {
                        'steps': [
                          {
                            'transitDetails': {
                              'transitLine': {
                                'name': 'KTX',
                                'vehicle': {'type': 'HIGH_SPEED_TRAIN'},
                              },
                            },
                          },
                        ],
                      },
                    ],
                  },
                ],
              }),
            ),
            200,
          );
        }),
      );
      final journeys = await api.transitJourneys(
        const GeoPoint(37.5, 127),
        const GeoPoint(37.6, 127),
        departure: DateTime(2026, 11, 15),
      );
      expect(journeys.length, 2);
      expect(journeys.first.route.transitLines, ['421', '2호선', '421']);
      expect(journeys.first.route.durationSeconds, 1801);
      final bus = journeys.first.boardings.first;
      expect(bus.mapPoints.length, 3);
      expect(bus.mapGeometryLoaded, isTrue);
      expect(bus.hasDetailedMapGeometry, isFalse);
      expect(bus.departureStop, '강남역');
      expect(bus.arrivalStop, '성수역');
      expect(bus.departureTime, DateTime.utc(2026, 11, 15, 6, 5));
      expect(bus.stopCount, 7);
      expect(bus.lineName, '간선버스 421번');
      expect(journeys.last.route.transportModes, {'rail'});
      expect(journeys.last.boardings.single.departureTime, isNull);
      expect(journeys.last.boardings.single.departureStop, isNull);
    },
  );

  test(
    'no route and API errors are failures, never fabricated journeys',
    () async {
      for (final response in [
        http.Response('{"routes":[]}', 200),
        http.Response('denied', 403),
      ]) {
        final api = GoogleApi(
          apiKey: 'fixture-key',
          client: MockClient((_) async => response),
        );
        await expectLater(
          api.transitJourneys(
            const GeoPoint(37.5, 127),
            const GeoPoint(37.6, 127),
            departure: DateTime(2026, 11, 15),
          ),
          throwsA(isA<GoogleApiException>()),
        );
      }
    },
  );
  test(
    'transit vehicle types come from route provider, not line-name guessing',
    () async {
      final api = GoogleApi(
        apiKey: 'fixture-key',
        client: MockClient((request) async {
          expect(
            request.headers['X-Goog-FieldMask'],
            contains('transitLine.vehicle.type'),
          );
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'routes': [
                  {
                    'distanceMeters': 1000,
                    'duration': '1800s',
                    'polyline': {'encodedPolyline': ''},
                    'legs': [
                      {
                        'steps': [
                          {
                            'transitDetails': {
                              'transitLine': {
                                'name': '101번',
                                'vehicle': {'type': 'BUS'},
                              },
                            },
                          },
                          {
                            'transitDetails': {
                              'transitLine': {
                                'name': '2호선',
                                'vehicle': {'type': 'SUBWAY'},
                              },
                            },
                          },
                        ],
                      },
                    ],
                  },
                ],
              }),
            ),
            200,
          );
        }),
      );
      final route = await api.transit(
        const GeoPoint(37.5, 127),
        const GeoPoint(37.6, 127),
        departure: DateTime(2026, 11, 10),
      );
      expect(route.transportModes, {'bus', 'subway'});
      expect(route.facilityIds, isEmpty);
      expect(route.transitLines, ['101번', '2호선']);
    },
  );
  test('decodePolyline: Google rasmiy misoli', () {
    final pts = GoogleApi.decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(pts.length, 3);
    expect(pts[0].lat, closeTo(38.5, 1e-5));
    expect(pts[0].lng, closeTo(-120.2, 1e-5));
    expect(pts[2].lat, closeTo(43.252, 1e-5));
    expect(pts[2].lng, closeTo(-126.453, 1e-5));
  });

  test('nearestPointOnPolyline: 점이 드문 KTX 선에서 선분 위 투영', () {
    // 서울 → 부산 직선; 대전 근처의 점은 선분 중간으로 투영된다.
    const line = [GeoPoint(37.5547, 126.9707), GeoPoint(35.1151, 129.0403)];
    const dcc = GeoPoint(36.3754, 127.3913);
    final p = RouteMatcher.nearestPointOnPolyline(dcc, line);
    // 양 끝점이 아니라 중간 점이어야 한다
    expect(p.lat, inExclusiveRange(35.2, 37.5));
    expect(
      RouteMatcher.haversineKm(dcc, p),
      lessThan(RouteMatcher.haversineKm(dcc, line.first)),
    );
  });
}
