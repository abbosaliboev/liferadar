import '../models/models.dart';
import 'route_matcher.dart';

/// "Connect the dots" — rejalar × eventlar × ob-havo × qiziqishlar → Insight kartalari.
///
/// Deterministik (AI emas): har bir karta aniq qoidadan chiqadi va id barqaror,
/// shuning uchun foydalanuvchi feedback'i qayta hisoblashda ham saqlanadi.
/// Keyin Gemini faqat [Insight.body]/[Insight.why] matnini boyitadi — faktlarni emas.
class InsightEngine {
  const InsightEngine({
    this.nearbyKm = 15,
    this.deadlineWindowDays = 14,
    this.opportunityWindowDays = 45,
    this.maxGeneralOpportunities = 2,
    this.maxNearbyPerPlan = 2,
    this.crowdKmReal = 3,
    this.maxDeadlines = 3,
  });

  /// Reja joyidan shu masofadagi eventlar "yaqin" hisoblanadi.
  final double nearbyKm;

  /// Registratsiya muddati shu kun ichida bo'lsa ogohlantiramiz.
  final int deadlineWindowDays;

  /// Rejaga bog'liq bo'lmagan imkoniyatlar uchun oldinga qarash oralig'i.
  final int opportunityWindowDays;
  final int maxGeneralOpportunities;

  /// Bitta reja uchun "yaqinda" imkoniyat kartalari soni.
  final int maxNearbyPerPlan;

  /// Bir vaqtda ko'rsatiladigan muddat kartalari.
  final int maxDeadlines;

  /// Haqiqiy eventlarda "olomon" ogohlantirishi faqat shu masofada (sample'da hajm ma'lum).
  final double crowdKmReal;

  List<Insight> build({
    required List<Plan> plans,
    required List<RadarEvent> events,
    required Set<String> interests,
    required DateTime now,
    Map<String, DailyWeather> weatherByPlanId = const {},
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final out = <Insight>[];
    final usedEventIds = <String>{};

    for (final plan in plans) {
      if (plan.end.isBefore(today)) continue;
      final where = plan.locationText.isNotEmpty ? plan.locationText : plan.title;

      // 1) Reja kunlari + yaqin joydagi eventlar.
      // Haqiqiy ma'lumotda bir hududda o'nlab event bo'ladi — har reja uchun eng muhimlari:
      // 1 ta "olomon" ogohlantirishi (eng yaqin) + [maxNearbyPerPlan] ta imkoniyat (eng mos).
      if (plan.location != null) {
        final crowdCandidates = <(RadarEvent, double)>[];
        final nearbyCandidates = <(RadarEvent, double, double)>[];
        for (final e in events) {
          if (e.placeless) continue; // manzili yo'q e'lon "yaqinda" bo'lolmaydi
          if (!_overlaps(plan.start, plan.end, e.start, e.end)) continue;
          final km = RouteMatcher.haversineKm(plan.location!, e.location);
          if (km > nearbyKm) continue;
          final interest = _interest(e, interests);
          if (_isCrowd(e, km)) {
            crowdCandidates.add((e, km));
          } else if (interest > 0) {
            nearbyCandidates.add((e, km, interest));
          }
        }
        crowdCandidates.sort((a, b) => a.$2.compareTo(b.$2));
        nearbyCandidates.sort((a, b) => b.$3 != a.$3 ? b.$3.compareTo(a.$3) : a.$2.compareTo(b.$2));

        for (final (e, km) in crowdCandidates.take(1)) {
          usedEventIds.add(e.id);
          out.add(
            Insight(
              id: 'crowd:${plan.id}:${e.id}',
              kind: InsightKind.planAlert,
              planId: plan.id,
              eventIds: [e.id],
              title: LocalizedText(
                ko: '${_dateKo(_on(e, plan.start))} $where 일정',
                en: '$where on ${_dateEn(_on(e, plan.start))}',
              ),
              body: LocalizedText(
                ko:
                    '같은 날 약 ${km.toStringAsFixed(1)} km 거리에서 "${e.title.ko}" 행사가 열립니다. '
                    '교통편과 숙소를 미리 확인하세요.',
                en:
                    '"${e.title.en}" takes place about ${km.toStringAsFixed(1)} km away the same day. '
                    'Check transport and lodging early.',
              ),
              why: const LocalizedText(
                ko: '방문 일정과 대규모 행사가 겹치면 교통·숙소 수요가 몰리고 혼잡해질 수 있습니다.',
                en: 'When your visit overlaps a large event, transport and lodging demand can spike.',
              ),
              confidence: _round(0.6 + 0.3 * (1 - km / nearbyKm)),
              signals: [
                Signal(SignalType.event, LocalizedText(ko: e.venue, en: e.venue)),
                const Signal(SignalType.traffic, LocalizedText(ko: '혼잡 예상', en: 'Crowds expected')),
              ],
              sources: [_source(e)],
            ),
          );
        }
        for (final (e, km, interest) in nearbyCandidates.take(maxNearbyPerPlan)) {
          usedEventIds.add(e.id);
          out.add(
            Insight(
              id: 'nearby:${plan.id}:${e.id}',
              kind: InsightKind.opportunity,
              planId: plan.id,
              eventIds: [e.id],
              title: LocalizedText(ko: '$where에 있는 동안: ${e.title.ko}', en: 'While you are at $where: ${e.title.en}'),
              body: LocalizedText(
                ko: '${_dateKo(_on(e, plan.start))} ${e.venue}에서 열립니다. 일정 장소에서 약 ${km.toStringAsFixed(1)} km.',
                en: 'On ${_dateEn(_on(e, plan.start))} at ${e.venue}, about ${km.toStringAsFixed(1)} km from your plan.',
              ),
              why: LocalizedText(
                ko: '관심사(${_tags(e, interests)})와 맞고, 이미 그 지역에 계실 예정입니다.',
                en: 'It matches your interests (${_tags(e, interests)}) and you will already be nearby.',
              ),
              confidence: _round(0.45 + 0.35 * interest + 0.2 * (1 - km / nearbyKm)),
              signals: [
                Signal(SignalType.event, LocalizedText(ko: e.venue, en: e.venue)),
                if (e.deadline != null && !e.deadline!.isBefore(today))
                  Signal(
                    SignalType.deadline,
                    LocalizedText(
                      ko: '신청 마감 ${_dateKo(e.deadline!)}',
                      en: 'Registration closes ${_dateEn(e.deadline!)}',
                    ),
                  ),
              ],
              sources: [_source(e)],
            ),
          );
        }
      }

      // 2) Reja kuni yomg'ir
      final w = weatherByPlanId[plan.id];
      if (w != null && w.likelyRain) {
        out.add(
          Insight(
            id: 'rain:${plan.id}:${_ymd(w.date)}',
            kind: InsightKind.planAlert,
            planId: plan.id,
            title: LocalizedText(
              ko: '${_dateKo(w.date)} $where — 비 예보',
              en: 'Rain expected at $where on ${_dateEn(w.date)}',
            ),
            body: LocalizedText(
              ko: '강수 확률 ${w.rainChance}%. 우산을 챙기고 야외 일정은 시간을 조정해 보세요.',
              en: '${w.rainChance}% chance of rain. Bring an umbrella and adjust outdoor plans.',
            ),
            why: const LocalizedText(
              ko: '일정 당일 해당 장소의 일별 예보에서 비 가능성이 높게 나타났습니다.',
              en: 'The daily forecast for your plan location shows a high chance of rain.',
            ),
            confidence: _round((w.rainChance ?? 60) / 100),
            signals: [
              Signal(
                SignalType.weather,
                LocalizedText(
                  ko: '${w.maxC ?? '-'}° / ${w.minC ?? '-'}° · ☔ ${w.rainChance}%',
                  en: '${w.maxC ?? '-'}° / ${w.minC ?? '-'}° · ☔ ${w.rainChance}%',
                ),
              ),
            ],
            sources: const [SourceLink('Google Weather', null)],
          ),
        );
      }
    }

    // 3) Qiziqishga mos event — registratsiya muddati yaqin.
    // Startap e'lonlari o'nlab bo'ladi — eng mos, keyin eng shoshilinch [maxDeadlines] tasi.
    final deadlineCandidates = <(RadarEvent, int)>[];
    for (final e in events) {
      final d = e.deadline;
      if (d == null || _interest(e, interests) == 0) continue;
      final left = DateTime(d.year, d.month, d.day).difference(today).inDays;
      if (left < 0 || left > deadlineWindowDays) continue;
      deadlineCandidates.add((e, left));
    }
    deadlineCandidates.sort((a, b) {
      final byInterest = _interest(b.$1, interests).compareTo(_interest(a.$1, interests));
      return byInterest != 0 ? byInterest : a.$2.compareTo(b.$2);
    });
    for (final (e, left) in deadlineCandidates.take(maxDeadlines)) {
      final d = e.deadline!;
      out.add(
        Insight(
          id: 'deadline:${e.id}',
          kind: InsightKind.deadline,
          eventIds: [e.id],
          title: LocalizedText(
            ko: '${left == 0 ? '오늘 신청 마감' : '신청 마감 D-$left'}: ${e.title.ko}',
            en:
                '${switch (left) {
                  0 => 'Registration closes today',
                  1 => 'Registration closes tomorrow',
                  _ => 'Registration closes in $left days',
                }}: ${e.title.en}',
          ),
          body: e.placeless
              ? LocalizedText(
                  ko: '${e.venue.isEmpty ? '' : '${e.venue} · '}${e.city} 공고의 접수가 ${_dateKo(d)}에 마감됩니다.',
                  en:
                      'Applications for this ${e.city} program${e.venue.isEmpty ? '' : ' by ${e.venue}'} '
                      'close on ${_dateEn(d)}.',
                )
              : LocalizedText(
                  ko: '${_dateKo(e.start)} ${e.city}에서 열리는 행사의 신청이 ${_dateKo(d)}에 마감됩니다.',
                  en: 'Registration for this ${_dateEn(e.start)} event in ${e.city} closes on ${_dateEn(d)}.',
                ),
          why: LocalizedText(
            ko: '관심사(${_tags(e, interests)})와 맞는 행사이며, 마감을 놓치면 참가할 수 없습니다.',
            en: 'It matches your interests (${_tags(e, interests)}); missing the deadline means missing it.',
          ),
          confidence: _round(0.5 + 0.4 * _interest(e, interests)),
          signals: [
            Signal(
              SignalType.deadline,
              LocalizedText(
                ko: left == 0 ? 'D-DAY' : 'D-$left',
                en: switch (left) {
                  0 => 'Today',
                  1 => '1 day left',
                  _ => '$left days left',
                },
              ),
            ),
            Signal(SignalType.event, LocalizedText(ko: e.venue, en: e.venue)),
          ],
          sources: [_source(e)],
        ),
      );
      usedEventIds.add(e.id);
    }

    // 4) Rejaga bog'liq bo'lmagan, qiziqishga eng mos yaqin eventlar
    final horizon = today.add(Duration(days: opportunityWindowDays));
    final general =
        events
            .where((e) => !usedEventIds.contains(e.id))
            .where((e) => !e.end.isBefore(today) && e.start.isBefore(horizon))
            .where((e) => _interest(e, interests) > 0)
            .toList()
          ..sort((a, b) {
            final s = _interest(b, interests).compareTo(_interest(a, interests));
            return s != 0 ? s : a.start.compareTo(b.start);
          });
    for (final e in general.take(maxGeneralOpportunities)) {
      out.add(
        Insight(
          id: 'opportunity:${e.id}',
          kind: InsightKind.opportunity,
          eventIds: [e.id],
          title: LocalizedText(ko: '새로운 기회: ${e.title.ko}', en: 'New opportunity: ${e.title.en}'),
          body: LocalizedText(
            ko: '${_dateKo(_on(e, today))} ${e.city} ${e.venue}에서 열립니다.',
            en: '${_dateEn(_on(e, today))} at ${e.venue}, ${e.city}.',
          ),
          why: LocalizedText(
            ko: '관심사(${_tags(e, interests)})와 일치합니다.',
            en: 'Matches your interests (${_tags(e, interests)}).',
          ),
          confidence: _round(0.4 + 0.4 * _interest(e, interests)),
          signals: [Signal(SignalType.event, LocalizedText(ko: e.venue, en: e.venue))],
          sources: [_source(e)],
        ),
      );
    }

    return rank(out);
  }

  /// Avval rejaga oid ogohlantirishlar va muddatlar, keyin ishonch bo'yicha.
  static List<Insight> rank(List<Insight> list) {
    int priority(InsightKind k) => switch (k) {
      InsightKind.planAlert => 0,
      InsightKind.deadline => 1,
      InsightKind.opportunity => 2,
      InsightKind.route => 3,
    };
    return [...list]..sort((a, b) {
      final p = priority(a.kind).compareTo(priority(b.kind));
      return p != 0 ? p : b.confidence.compareTo(a.confidence);
    });
  }

  /// Olomon yig'adigan event: qisqa (≤ 3 kun; oylab davom etadigan ko'rgazma/katok emas).
  /// Sample'da hajm ma'lum (stadion konserti). Haqiqiy ma'lumotda zal sig'imi yo'q —
  /// kichik zaldagi konsert olomon emas, shuning uchun faqat yaqin festivallar.
  bool _isCrowd(RadarEvent e, double km) {
    if (e.end.difference(e.start).inDays > 3) return false;
    if (e.isSample) return e.category == EventCategory.concert || e.category == EventCategory.festival;
    return e.category == EventCategory.festival && km <= crowdKmReal;
  }

  /// Event shu kungacha boshlanib bo'lgan bo'lsa (oylab davom etadigan ko'rgazma) — [from] kuni,
  /// aks holda o'z boshlanish kuni. "1-may kuni" kabi o'tgan sana chiqmasin.
  static DateTime _on(RadarEvent e, DateTime from) {
    final day = DateTime(from.year, from.month, from.day);
    return e.start.isBefore(day) ? day : e.start;
  }

  static bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    final a0 = DateTime(aStart.year, aStart.month, aStart.day);
    final a1 = DateTime(aEnd.year, aEnd.month, aEnd.day, 23, 59);
    return !bEnd.isBefore(a0) && !bStart.isAfter(a1);
  }

  static double _interest(RadarEvent e, Set<String> interests) =>
      e.tags.isEmpty ? 0 : e.tags.where(interests.contains).length / e.tags.length;

  static String _tags(RadarEvent e, Set<String> interests) =>
      e.tags.where(interests.contains).map((t) => '#$t').join(' ');

  static SourceLink _source(RadarEvent e) =>
      SourceLink(e.isSample ? 'Sample data' : (e.sourceName ?? e.source), e.url ?? e.registerUrl);

  static double _round(double v) => (v.clamp(0.0, 0.99) * 100).round() / 100;

  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static String _dateKo(DateTime d) => '${d.month}월 ${d.day}일';
  static String _dateEn(DateTime d) => '${_monthsEn[d.month - 1]} ${d.day}';
  static String _ymd(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
