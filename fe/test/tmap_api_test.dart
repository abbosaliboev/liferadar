import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liferadar/data/transit_journey.dart';
import 'package:liferadar/services/google_api.dart';
import 'package:liferadar/services/tmap_api.dart';
import 'package:liferadar_core/liferadar_core.dart';

Map<String, dynamic> response({
  String shape = '127,37.5 127.01,37.51 127.02,37.52',
  int service = 1,
}) => {
  'metaData': {
    'plan': {
      'itineraries': [
        {
          'totalTime': 7200,
          'totalDistance': 100000,
          'legs': [
            {
              'mode': 'EXPRESSBUS',
              'route': '시외버스:동서울-청주대',
              'routeId': 'test-route',
              'service': service,
              'start': {'name': '동서울', 'lat': 37.5, 'lon': 127},
              'end': {'name': '청주대', 'lat': 37.52, 'lon': 127.02},
              'passShape': {'linestring': shape},
              'passStopList': {
                'stations': [{}, {}, {}],
              },
            },
          ],
        },
      ],
    },
  },
};

http.Response googleResponse() => http.Response(
  jsonEncode({
    'routes': [
      {
        'duration': '3600s',
        'distanceMeters': 10000,
        'polyline': {'encodedPolyline': ''},
        'legs': [
          {
            'steps': [
              {
                'transitDetails': {
                  'transitLine': {
                    'name': '101',
                    'vehicle': {'type': 'BUS'},
                  },
                },
              },
            ],
          },
        ],
      },
    ],
  }),
  200,
);

void main() {
  const start = GeoPoint(37.5, 127), end = GeoPoint(36.6, 127.4);
  final departure = DateTime.utc(2026, 11, 27, 3);

  test(
    'TMAP receives KST requested date and retains detailed intercity shape without inventing timetable',
    () async {
      var googleCalls = 0;
      final api = GoogleApi(
        apiKey: 'google-test',
        client: MockClient((_) async {
          googleCalls++;
          return googleResponse();
        }),
        tmap: TmapApi(
          appKey: 'tmap-test',
          client: MockClient((request) async {
            expect(request.headers['appKey'], 'tmap-test');
            final body = jsonDecode(request.body);
            expect(body['searchDttm'], '202611271200');
            expect(body['count'], 3);
            return http.Response.bytes(
              utf8.encode(jsonEncode(response())),
              200,
            );
          }),
        ),
      );
      final journeys = await api.transitJourneys(
        start,
        end,
        departure: departure,
      );
      final j = journeys.single, b = j.boardings.single;
      expect(googleCalls, 0);
      expect(j.provider, 'tmap');
      expect(j.route.transportModes, {'bus'});
      expect(b.provider, 'tmap');
      expect(b.providerRouteId, 'test-route');
      expect(b.hasDetailedMapGeometry, isTrue);
      expect(b.mapPoints.first.lat, 37.5);
      expect(b.mapPoints.last.lng, 127.02);
      expect(b.stopCount, 2);
      expect(b.departureTime, isNull);
      expect(b.arrivalTime, isNull);
      expect(j.arrival, isNull);
      expect(TransitBoarding.fromJson(b.toJson()).provider, 'tmap');
    },
  );

  test(
    'quota exceeded falls back to Google and prevents repeated quota requests within a minute',
    () async {
      var tmapCalls = 0, googleCalls = 0;
      final api = GoogleApi(
        apiKey: 'google-test',
        client: MockClient((_) async {
          googleCalls++;
          return googleResponse();
        }),
        tmap: TmapApi(
          appKey: 'tmap-test',
          client: MockClient((_) async {
            tmapCalls++;
            return http.Response(
              '{"error":{"code":"QUOTA_EXCEEDED","message":"limit"}}',
              429,
            );
          }),
        ),
      );
      for (var i = 0; i < 2; i++) {
        final j = (await api.transitJourneys(
          start,
          end,
          departure: departure,
        )).single;
        expect(j.provider, 'google');
        expect(j.fallbackReason, 'quota');
        expect(j.route.transitLines, ['101']);
      }
      expect(tmapCalls, 1);
      expect(googleCalls, 2);
    },
  );

  test(
    'non-quota failure falls back without reporting quota exceeded',
    () async {
      final api = GoogleApi(
        apiKey: 'google-test',
        client: MockClient((_) async => googleResponse()),
        tmap: TmapApi(
          appKey: 'tmap-test',
          client: MockClient((_) async => http.Response('unavailable', 503)),
        ),
      );
      final j = (await api.transitJourneys(
        start,
        end,
        departure: departure,
      )).single;
      expect(j.fallbackReason, 'unavailable');
      expect(j.provider, 'google');
    },
  );

  test(
    'endpoint-only intercity data stays available as an option but is not a detailed route line',
    () {
      final j = TmapApi.parseJourneys(
        response(shape: '127,37.5 127.4,36.6', service: 0),
      ).single;
      final b = j.boardings.single;
      expect(j.route.transitLines, ['시외버스:동서울-청주대']);
      expect(b.hasDetailedMapGeometry, isFalse);
      expect(b.serviceActive, isFalse);
      expect(TransitBoarding.fromJson(b.toJson()).serviceActive, isFalse);
    },
  );

  test('malformed coordinates never become a connecting route', () {
    expect(TmapApi.parseShape('127,37.5 broken 127.4,36.6'), isEmpty);
    expect(TmapApi.parseShape('NaN,37.5'), isEmpty);
    expect(TmapApi.parseShape('127,37.5 127,37.5 127.01,37.51').length, 2);
  });
}
