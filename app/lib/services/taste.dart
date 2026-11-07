import '../models/models.dart';

/// Foydalanuvchi feedback'idan (👍 / 👎 / yashirish) o'rganilgan did.
///
/// Har bir baho o'sha eventning teglari va kategoriyasiga og'irlik qo'shadi. Keyin boshqa
/// eventlar [bias] orqali yuqoriga yoki pastga suriladi: masalan, 👎 bosilgan festivalga o'xshash
/// festivallar pastroq tushadi. Sof Dart, deterministik (testlanadi, serverga ko'chirsa bo'ladi).
class Taste {
  const Taste._(this._tags, this._categories, this.rated);

  static const none = Taste._({}, {}, {});

  final Map<String, double> _tags;
  final Map<EventCategory, double> _categories;

  /// Baho berilgan eventlar. Ularning o'z kartasi baholangan holida qoladi (bekor qilish mumkin).
  final Set<String> rated;

  /// Bitta baho qancha suradi va maksimal ta'sir.
  static const _step = 0.4;
  static const _cap = 1.0;

  /// [feedback]: insight id → baho. [events]: id → event.
  factory Taste.from(Map<String, InsightFeedback> feedback, Map<String, RadarEvent> events) {
    final tags = <String, double>{};
    final categories = <EventCategory, double>{};
    final rated = <String>{};
    for (final entry in feedback.entries) {
      final eventId = eventIdOf(entry.key);
      final e = eventId == null ? null : events[eventId];
      if (e == null) continue;
      final w = switch (entry.value) {
        InsightFeedback.like => 1.0,
        InsightFeedback.dislike => -1.0,
        InsightFeedback.hidden => -0.5,
      };
      rated.add(e.id);
      for (final t in e.tags) {
        tags[t] = (tags[t] ?? 0) + w;
      }
      categories[e.category] = (categories[e.category] ?? 0) + w;
    }
    double clamp(double v) => (v * _step).clamp(-_cap, _cap);
    return Taste._(
      {for (final e in tags.entries) e.key: clamp(e.value)},
      {for (final e in categories.entries) e.key: clamp(e.value)},
      rated,
    );
  }

  bool get isEmpty => _tags.isEmpty && _categories.isEmpty;

  /// −1..1: o'xshash eventlarga berilgan baholar. Teglar o'rtachasi 60%, kategoriya 40%.
  double bias(RadarEvent e) {
    if (isEmpty) return 0;
    final tagAvg = e.tags.isEmpty ? 0.0 : e.tags.map((t) => _tags[t] ?? 0).reduce((a, b) => a + b) / e.tags.length;
    return (0.6 * tagAvg + 0.4 * (_categories[e.category] ?? 0)).clamp(-1.0, 1.0);
  }

  /// Qiziqish mosligi (0..1) + did. Qiziqishga umuman mos kelmasa 0 qoladi, ya'ni did yangi
  /// mavzu qo'shmaydi, faqat tartibni o'zgartiradi. Baholangan eventning o'zi jim surilmaydi.
  double score(RadarEvent e, Set<String> interests) {
    if (e.tags.isEmpty) return 0;
    final interest = e.tags.where(interests.contains).length / e.tags.length;
    if (interest == 0 || rated.contains(e.id)) return interest;
    return (interest + bias(e)).clamp(0.0, 1.0);
  }

  /// Insight id'dan event id: `nearby:<plan>:<event>`, `crowd:…`, `deadline:<event>`, `opportunity:<event>`.
  static String? eventIdOf(String insightId) {
    final kind = insightId.split(':').first;
    if (!const {'nearby', 'crowd', 'deadline', 'opportunity'}.contains(kind)) return null;
    return insightId.substring(insightId.lastIndexOf(':') + 1);
  }
}
