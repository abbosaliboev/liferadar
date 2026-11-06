import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/data/sample_data.dart';
import 'package:liferadar/models/models.dart';
import 'package:liferadar/services/insight_engine.dart';

void main() {
  const engine = InsightEngine();
  final now = DateTime(2026, 11, 6, 10);

  List<Insight> run({Set<String> interests = const {'ai', 'startup'}, Map<String, DailyWeather> weather = const {}}) =>
      engine.build(plans: samplePlans, events: sampleEvents, interests: interests, now: now, weatherByPlanId: weather);

  test('Busan safari + Asiad konserti → olomon ogohlantirishi birinchi', () {
    final list = run();
    expect(list.first.id, 'crowd:plan-busan-trip:ev-busan-concert');
    expect(list.first.kind, InsightKind.planAlert);
    expect(list.first.planId, 'plan-busan-trip');
  });

  test('Safar oralig\'idagi BEXCO AI ekspo → qiziqishga mos imkoniyat', () {
    final list = run();
    final expo = list.where((i) => i.id == 'nearby:plan-busan-trip:ev-busan-ai-expo');
    expect(expo, hasLength(1));
    expect(expo.first.kind, InsightKind.opportunity);
    expect(expo.first.body.en, contains('BEXCO'));
  });

  test('Qiziqish mos kelmasa imkoniyat chiqmaydi (konsert ogohlantirishi esa qoladi)', () {
    final list = run(interests: {'design'});
    expect(list.any((i) => i.id.startsWith('nearby:')), isFalse);
    expect(list.any((i) => i.id.startsWith('crowd:')), isTrue);
  });

  test('Muddat 14 kun ichida → deadline kartasi (ekspo: 18-noyabr, D-12)', () {
    final list = run();
    final d = list.firstWhere((i) => i.id == 'deadline:ev-busan-ai-expo');
    expect(d.title.ko, startsWith('신청 마감 D-12'));
  });

  test('Yomg\'irli prognoz → ob-havo ogohlantirishi', () {
    final list = run(weather: {
      'plan-gangnam-meeting': DailyWeather(
        date: DateTime(2026, 11, 10),
        condition: 'Rain',
        type: 'RAIN',
        maxC: 9,
        minC: 4,
        rainChance: 90,
      ),
    });
    final rain = list.firstWhere((i) => i.id.startsWith('rain:plan-gangnam-meeting'));
    expect(rain.confidence, 0.9);
    expect(rain.kind, InsightKind.planAlert);
  });

  test('Bir event bir necha marta takrorlanmaydi va id\'lar noyob', () {
    final list = run();
    final ids = list.map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
    // AI ekspo "nearby" sifatida chiqqan — umumiy "opportunity" sifatida qayta chiqmasligi kerak
    expect(ids, isNot(contains('opportunity:ev-busan-ai-expo')));
  });

  test('O\'tib ketgan rejalar e\'tiborga olinmaydi', () {
    final list = engine.build(
      plans: samplePlans,
      events: sampleEvents,
      interests: {'ai'},
      now: DateTime(2026, 12, 30),
    );
    expect(list.where((i) => i.planId != null), isEmpty);
  });
}
