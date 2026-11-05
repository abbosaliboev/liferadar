import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/data/sample_data.dart';
import 'package:liferadar/models/models.dart';
import 'package:liferadar/services/route_matcher.dart';

void main() {
  // Soddalashtirilgan Seoul → Daejeon → Busan yo'li (KTX/Gyeongbu yo'nalishiga yaqin).
  const route = [
    GeoPoint(37.5547, 126.9707), // 서울역
    GeoPoint(36.8, 127.15),
    GeoPoint(36.3320, 127.4340), // 대전역
    GeoPoint(35.8, 128.6),
    GeoPoint(35.1151, 129.0403), // 부산역
  ];
  const matcher = RouteMatcher();

  test('haversine: Seoul–Busan ~325 km to\'g\'ri chiziq', () {
    final d = RouteMatcher.haversineKm(route.first, route.last);
    expect(d, closeTo(325, 5));
  });

  test('yo\'ldagi nuqta masofasi ~0', () {
    expect(RouteMatcher.distanceToPolylineKm(const GeoPoint(36.3320, 127.4340), route), lessThan(0.5));
  });

  test('20-noyabr: Daejeon AI seminar topiladi, Seoul COEX (dekabr) topilmaydi', () {
    final opps = matcher.match(
      route: route,
      events: sampleEvents,
      interests: {'ai'},
      tripStart: DateTime(2026, 11, 20),
      tripEnd: DateTime(2026, 11, 20, 23, 59),
    );
    final ids = opps.map((o) => o.event.id).toList();
    expect(ids, contains('ev-daejeon-ai-seminar'));
    expect(ids, isNot(contains('ev-coex-dev-conf'))); // sana mos emas
    expect(ids, isNot(contains('ev-busan-ai-expo'))); // 21-noyabr
    // AI qiziqishi bor seminar musiqa konsertidan yuqori turishi kerak
    expect(ids.first, 'ev-daejeon-ai-seminar');
  });

  test('koridordan tashqaridagi event chiqmaydi', () {
    final far = RadarEvent(
      id: 'far',
      title: const LocalizedText(ko: 'x', en: 'x'),
      description: const LocalizedText(ko: 'x', en: 'x'),
      category: EventCategory.meetup,
      tags: const ['ai'],
      start: DateTime(2026, 11, 20, 10),
      end: DateTime(2026, 11, 20, 12),
      venue: 'Gangneung',
      city: 'Gangneung',
      location: const GeoPoint(37.7519, 128.8761), // 강릉 — yo'ldan ~150 km
    );
    final opps = matcher.match(
      route: route,
      events: [far],
      interests: {'ai'},
      tripStart: DateTime(2026, 11, 20),
      tripEnd: DateTime(2026, 11, 21),
    );
    expect(opps, isEmpty);
  });
}
