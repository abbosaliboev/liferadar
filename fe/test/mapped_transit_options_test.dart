import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liferadar/data/transit_journey.dart';
import 'package:liferadar/services/google_api.dart';
import 'package:liferadar/services/kakao_transit_api.dart';
import 'package:liferadar/services/mapped_transit_options.dart';
import 'package:liferadar_core/liferadar_core.dart';

class Primary extends GoogleApi {
  Primary(this.choices);
  final List<TransitJourney> choices;
  @override
  Future<List<TransitJourney>> googleTransitJourneys(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  }) async => choices;
  @override
  Future<List<TransitJourney>> transitJourneys(
    GeoPoint origin,
    GeoPoint destination, {
    required DateTime departure,
  }) async => throw StateError('Unscheduled facade must not be used');
}

void main() {
  final departure = DateTime.utc(2026, 11, 27, 3);
  const origin = GeoPoint(37.64183333311373, 127.0775057868646),
      destination = GeoPoint(36.653087976365434, 127.49512976914777);
  final raw = File(
    'test/fixtures/google_scheduled_seoul_cheongju.json',
  ).readAsStringSync();
  GoogleApi google(String fixture) => GoogleApi(
    apiKey: 'test',
    client: MockClient((r) async {
      expect(jsonDecode(r.body)['departureTime'], departure.toIso8601String());
      return http.Response.bytes(utf8.encode(fixture), 200);
    }),
  );
  Future<List<TransitJourney>> search(GoogleApi api, {DateTime? deadline}) =>
      MappedTransitOptions(
        primary: api,
      ).search(origin, destination, departure: departure, arriveBy: deadline);

  test(
    'real date-specific schedules remain selectable when express bus shape has only endpoints',
    () async {
      final result = await search(
        google(raw),
        deadline: DateTime.utc(2026, 11, 27, 8),
      );
      expect(result, hasLength(3));
      expect(
        result.every(
          (j) => MappedTransitOptions.hasUsableTimetable(j, departure),
        ),
        isTrue,
      );
      expect(
        result.any((j) => j.boardings.any((b) => !b.hasDetailedMapGeometry)),
        isTrue,
      );
      for (final j in result) {
        expect(
          j.route.durationSeconds,
          j.arrival!.difference(departure).inSeconds,
        );
        expect(
          j.boardings.every(
            (b) => b.departureTime != null && b.arrivalTime != null,
          ),
          isTrue,
        );
        expect(
          j.route.transitLines.any(
            (l) => l.contains('8308') || l.contains('4401'),
          ),
          isFalse,
        );
      }
    },
  );
  test(
    'Kakao real coordinates are not accepted as a departure-date timetable',
    () async {
      final kakao = KakaoTransitApi.parseJourneys(
        jsonDecode(
          File('test/fixtures/kakao_seoul_cheongju.json').readAsStringSync(),
        ),
      );
      expect(
        kakao.first.boardings
            .singleWhere((b) => b.line.contains('8308'))
            .mapPoints
            .length,
        471,
      );
      await expectLater(
        search(Primary(kakao)),
        throwsA(isA<NoScheduledTransitRoute>()),
      );
    },
  );
  test('journeys arriving after the next appointment are excluded', () async {
    await expectLater(
      search(google(raw), deadline: departure.add(const Duration(minutes: 30))),
      throwsA(isA<NoScheduledTransitRoute>()),
    );
  });
  test('missing timetable never becomes a selectable route', () async {
    final data = jsonDecode(raw);
    for (final r in data['routes']) {
      for (final leg in r['legs']) {
        for (final step in leg['steps']) {
          step['transitDetails']?['stopDetails']?.remove('departureTime');
        }
      }
    }
    await expectLater(
      search(google(jsonEncode(data))),
      throwsA(isA<NoScheduledTransitRoute>()),
    );
  });
  test('transfer walk that misses the next departure is rejected', () async {
    final data = jsonDecode(raw);
    final r = data['routes'][0];
    data['routes'] = [r];
    var boarded = false;
    for (final step in r['legs'][0]['steps']) {
      if (step['transitDetails'] != null) {
        boarded = true;
        continue;
      }
      if (boarded) {
        step['staticDuration'] = '86400s';
        break;
      }
    }
    await expectLater(
      search(google(jsonEncode(data))),
      throwsA(isA<NoScheduledTransitRoute>()),
    );
  });
  test('TMAP operating flag alone does not establish a timetable', () async {
    const j = TransitJourney(
      provider: 'tmap',
      route: TravelRoute(distanceMeters: 100, durationSeconds: 100),
      boardings: [
        TransitBoarding(line: 'BUS', mode: 'bus', serviceActive: true),
      ],
    );
    await expectLater(
      search(Primary([j])),
      throwsA(isA<NoScheduledTransitRoute>()),
    );
  });
}
