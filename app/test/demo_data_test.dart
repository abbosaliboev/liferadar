import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/data/sample_data.dart';
import 'package:liferadar/services/insight_engine.dart';

void main() {
  test('demo sanalari: 11-14 gacha o\'zgarmaydi, keyin butun haftalarga suriladi', () {
    expect(demoShift(DateTime(2026, 11, 7)), Duration.zero);
    expect(demoShift(DateTime(2026, 11, 14, 23)), Duration.zero); // 6 kun oldin — hali joyida
    expect(demoShift(DateTime(2026, 11, 15)), const Duration(days: 7));
    final jan = demoShift(DateTime(2027, 1, 15));
    expect(jan.inDays % 7, 0);
    final trip = samplePlansAt(DateTime(2027, 1, 15)).firstWhere((p) => p.id == 'plan-busan-trip');
    final lead = trip.start.difference(DateTime(2027, 1, 15)).inDays;
    expect(lead, inInclusiveRange(6, 12));
  });

  for (final now in [DateTime(2026, 11, 13, 9), DateTime(2027, 3, 2, 9)]) {
    test('demo hikoyasi ishlaydi ($now)', () {
      final events = sampleEventsAt(now);
      final plans = samplePlansAt(now);
      final ids = [
        for (final i in const InsightEngine().build(
          plans: plans,
          events: events,
          interests: {'ai', 'startup', 'music'},
          now: now,
        ))
          i.id,
      ];
      // 2-qadam: Busan safari + katta konsert
      expect(ids, contains('crowd:plan-busan-trip:ev-busan-concert'));
      // 5-qadam: seminar muddati yaqin (push 2 kun ichida chiqadi)
      expect(ids, contains('deadline:ev-daejeon-ai-seminar'));
    });
  }

  test('11-13 da seminar muddati D-2 — push mezoniga tushadi', () {
    final seminar = sampleEventsAt(DateTime(2026, 11, 13)).firstWhere((e) => e.id == 'ev-daejeon-ai-seminar');
    expect(seminar.deadline!.difference(DateTime(2026, 11, 13)).inDays, 2);
  });
}
