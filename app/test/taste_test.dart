import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/models/models.dart';
import 'package:liferadar/services/insight_engine.dart';
import 'package:liferadar/services/taste.dart';

RadarEvent _e(String id, EventCategory c, List<String> tags, {int day = 20}) => RadarEvent(
      id: id,
      title: LocalizedText(ko: id, en: id),
      description: const LocalizedText(ko: '', en: ''),
      category: c,
      tags: tags,
      start: DateTime(2026, 11, day, 10),
      end: DateTime(2026, 11, day, 18),
      venue: 'Hall',
      city: 'Seoul',
      location: const GeoPoint(37.5, 127.0),
      source: 'test',
    );

final _jazz = _e('jazz', EventCategory.concert, ['music']);
final _rock = _e('rock', EventCategory.concert, ['music']);
final _aiTalk = _e('ai-talk', EventCategory.conference, ['ai']);
final _aiMeetup = _e('ai-meetup', EventCategory.meetup, ['ai', 'networking']);
final _blues = _e('blues', EventCategory.concert, ['music']);
final _events = {for (final e in [_jazz, _blues, _rock, _aiTalk, _aiMeetup]) e.id: e};

void main() {
  test('insight id → event id', () {
    expect(Taste.eventIdOf('nearby:plan-1:tour-123'), 'tour-123');
    expect(Taste.eventIdOf('deadline:kstartup-9'), 'kstartup-9');
    expect(Taste.eventIdOf('opportunity:ev-x'), 'ev-x');
    expect(Taste.eventIdOf('rain:plan-1:2026-11-8'), isNull);
  });

  test('👎 o\'xshash eventlarni pastga, 👍 yuqoriga suradi', () {
    final taste = Taste.from({'opportunity:jazz': InsightFeedback.dislike}, _events);
    expect(taste.bias(_rock), lessThan(0)); // bir xil teg + kategoriya
    expect(taste.bias(_aiTalk), 0); // aloqasi yo'q
    final interests = {'music', 'ai'};
    expect(taste.score(_rock, interests), lessThan(Taste.none.score(_rock, interests)));
    // Baholangan eventning o'zi jim surilmaydi (kartasi 👎 holatida qoladi, bekor qilsa bo'ladi).
    expect(taste.score(_jazz, interests), Taste.none.score(_jazz, interests));

    final liked = Taste.from({'deadline:ai-talk': InsightFeedback.like}, _events);
    expect(liked.score(_aiMeetup, {'ai', 'networking'}), 1.0);
    expect(liked.score(_aiMeetup, {'ai'}), greaterThan(Taste.none.score(_aiMeetup, {'ai'})));
  });

  test('did qiziqishga mos bo\'lmagan mavzuni qo\'shmaydi', () {
    final taste = Taste.from({'opportunity:jazz': InsightFeedback.like}, _events);
    expect(taste.score(_rock, {'ai'}), 0);
  });

  test('InsightEngine: 👎 dan keyin o\'xshash konsert tavsiyadan tushadi, AI chiqadi', () {
    const engine = InsightEngine(maxGeneralOpportunities: 1);
    final now = DateTime(2026, 11, 7);
    final events = [_rock, _aiMeetup];
    final interests = {'music', 'ai'};
    List<String> ids(Taste t) => [
          for (final i in engine.build(plans: const [], events: events, interests: interests, now: now, taste: t)) i.id,
        ];

    expect(ids(Taste.none), ['opportunity:rock']); // music 1.0 > ai 0.5
    // Bitta 👎 — konsert hali ham oldinda (to'liq mos), lekin bali tushadi.
    final once = Taste.from({'opportunity:jazz': InsightFeedback.dislike}, _events);
    expect(ids(once), ['opportunity:rock']);
    // Ikkinchi 👎 — konsertlar pastga, AI meetup chiqadi.
    final twice = Taste.from({
      'opportunity:jazz': InsightFeedback.dislike,
      'deadline:blues': InsightFeedback.dislike,
    }, _events);
    expect(ids(twice), ['opportunity:ai-meetup']);
  });
}
