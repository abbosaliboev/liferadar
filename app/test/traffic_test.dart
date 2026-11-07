import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/models/models.dart';
import 'package:liferadar/models/traffic.dart';
import 'package:liferadar/services/insight_engine.dart';
import 'package:liferadar/services/route_matcher.dart';
import 'package:liferadar/services/sources/seoul_traffic.dart';
import 'package:liferadar/services/traffic_matcher.dart';

// Testlar "집회·마라톤·축제 뉴스의 이동 영향 판별 로직" hujjatidagi D-holatlarga tayanadi.
// Rejalarda transport turi yo'q → "mode UNKNOWN" → eng yuqori natija CAUTION (§9, 9-qator).

const _cityHall = GeoPoint(37.5663, 126.9779);
final _now = DateTime(2026, 11, 7, 8);

Plan _plan({DateTime? start, DateTime? end, GeoPoint? at = _cityHall}) {
  final s = start ?? DateTime(2026, 11, 8, 10);
  return Plan(
    id: 'p1',
    title: 'Meeting',
    start: s,
    end: end ?? s.add(const Duration(hours: 1)),
    locationText: '서울시청',
    city: 'Seoul',
    location: at,
  );
}

TrafficNotice _notice({
  required DateTime start,
  DateTime? end,
  GeoPoint at = const GeoPoint(37.5690, 126.9779), // ~300 m shimolda
  TrafficKind kind = TrafficKind.rally,
}) =>
    TrafficNotice(
      id: 'topis-1',
      kind: kind,
      title: '[통제] 세종대로 집회',
      detail: '[통제] 세종대로 집회\n- 양방향 일부 통제',
      start: start,
      end: end,
      location: at,
      source: SeoulTraffic.source,
      sourceName: SeoulTraffic.sourceName,
      sourceUrl: SeoulTraffic.sourceUrl,
    );

void main() {
  const m = TrafficMatcher();

  test('D07: reja oldidagi 2 soatlik oynada, 1 km ichida → CAUTION (transport noma\'lum)', () {
    // Reja 10:00, oyna [08:00, 10:00); ta'sir 09:00–12:00.
    final r = m.evaluate(_plan(), _notice(start: DateTime(2026, 11, 8, 9), end: DateTime(2026, 11, 8, 12)), _now);
    expect(r.decision, TrafficDecision.caution);
    expect(r.time, TimeMatch.window);
    expect(r.space, SpaceMatch.nearby);
    expect(r.reasons, contains('MODE_UNKNOWN'));
  });

  test('D02: vaqt mos emas → IGNORE', () {
    final r = m.evaluate(_plan(), _notice(start: DateTime(2026, 11, 8, 12), end: DateTime(2026, 11, 8, 14)), _now);
    expect(r.decision, TrafficDecision.ignore);
  });

  test('D03: chegaralar faqat tegib tursa kesishmaydi ([start, end))', () {
    // Ta'sir 06:00–08:00 tugaydi, oyna 08:00 da boshlanadi.
    final ends = m.evaluate(_plan(), _notice(start: DateTime(2026, 11, 8, 6), end: DateTime(2026, 11, 8, 8)), _now);
    expect(ends.decision, TrafficDecision.ignore);
    // Ta'sir aynan reja boshlanishida (10:00) boshlanadi — oyna 10:00 da yopiladi.
    final starts = m.evaluate(_plan(), _notice(start: DateTime(2026, 11, 8, 10), end: DateTime(2026, 11, 8, 12)), _now);
    expect(starts.decision, TrafficDecision.ignore);
  });

  test('1 km dan uzoq → IGNORE; reja joyi yo\'q → NEEDS_REVIEW', () {
    final far = _notice(start: DateTime(2026, 11, 8, 9), end: DateTime(2026, 11, 8, 12), at: const GeoPoint(37.5126, 127.0590));
    expect(m.evaluate(_plan(), far, _now).decision, TrafficDecision.ignore);
    final near = _notice(start: DateTime(2026, 11, 8, 9), end: DateTime(2026, 11, 8, 12));
    expect(m.evaluate(_plan(at: null), near, _now).decision, TrafficDecision.needsReview);
  });

  test('D06: kun bo\'yi reja — faqat sana (DATE_MATCH → CAUTION)', () {
    final allDay = _plan(start: DateTime(2026, 11, 8), end: DateTime(2026, 11, 9));
    final r = m.evaluate(allDay, _notice(start: DateTime(2026, 11, 8, 14), end: DateTime(2026, 11, 8, 18)), _now);
    expect(r.time, TimeMatch.date);
    expect(r.decision, TrafficDecision.caution);
    final otherDay = _notice(start: DateTime(2026, 11, 9, 14), end: DateTime(2026, 11, 9, 18));
    expect(m.evaluate(allDay, otherDay, _now).decision, TrafficDecision.ignore);
  });

  test('D14: tugash noma\'lum — faqat boshlanish kunida, muddatsiz faol emas', () {
    final sameDay = m.evaluate(_plan(), _notice(start: DateTime(2026, 11, 8, 7)), _now);
    expect(sameDay.time, TimeMatch.possible);
    expect(sameDay.decision, TrafficDecision.caution);
    final dayBefore = m.evaluate(_plan(), _notice(start: DateTime(2026, 11, 7, 7)), _now);
    expect(dayBefore.decision, TrafficDecision.ignore);
  });

  test('§9-2: boshlangan reja uchun yangi ogohlantirish yo\'q', () {
    final r = m.evaluate(
      _plan(start: DateTime(2026, 11, 7, 7)),
      _notice(start: DateTime(2026, 11, 7, 6), end: DateTime(2026, 11, 7, 12)),
      _now,
    );
    expect(r.decision, TrafficDecision.ignore);
  });

  test('InsightEngine: karta shablon matnda, manba va vaqt bilan; "kechikish" deyilmaydi', () {
    final list = const InsightEngine().build(
      plans: [_plan()],
      events: const [],
      interests: const {},
      now: _now,
      traffic: [_notice(start: DateTime(2026, 11, 8, 9), end: DateTime(2026, 11, 8, 12))],
    );
    final card = list.singleWhere((i) => i.id == 'traffic:p1:topis-1');
    expect(card.kind, InsightKind.planAlert);
    expect(card.why.ko, contains('서울시 TOPIS'));
    expect(card.why.ko, contains('세종대로 집회'));
    expect(card.signals.first.summary.ko, contains('09:00'));
    expect(card.body.ko, contains('확인해 주세요'));
    expect(card.body.en.toLowerCase(), isNot(contains('delay')));
    expect(card.sources.single.title, SeoulTraffic.sourceName);
  });

  group('SeoulTraffic parser', () {
    // Haqiqiy javobdan (2026-11-07) qisqartirilgan namuna.
    const xml = '<?xml version="1.0" encoding="UTF-8"?><AccInfo><list_total_count>2</list_total_count>'
        '<RESULT><CODE>INFO-000</CODE><MESSAGE>정상 처리되었습니다</MESSAGE></RESULT>'
        '<row><acc_id>1107886</acc_id><occr_date>20261107</occr_date><occr_time>1400</occr_time>'
        '<exp_clr_date>20261108</exp_clr_date><exp_clr_time>220000</exp_clr_time><acc_type>A10</acc_type>'
        '<acc_dtype>10B03</acc_dtype><grs80tm_x>198481.948238959</grs80tm_x><grs80tm_y>452136.8686872072</grs80tm_y>'
        '<acc_info>[통제] 청계천로 차 없는 거리 행사(청계광장~삼일교, 양방향) &#13;(토) 14:00 ~ (일) 22:00</acc_info></row>'
        '<row><acc_id>9</acc_id><occr_date>20261107</occr_date><occr_time>0900</occr_time><acc_type>A01</acc_type>'
        '<acc_dtype>01B01</acc_dtype><grs80tm_x>198000</grs80tm_x><grs80tm_y>452000</grs80tm_y><acc_info>추돌사고</acc_info></row>'
        '</AccInfo>';

    test('XML → e\'lon; avariya kabi qisqa hodisalar olinmaydi', () {
      final notices = [for (final r in SeoulTraffic.rows(xml)) ?SeoulTraffic.parse(r)];
      expect(notices, hasLength(1));
      final n = notices.single;
      expect(n.id, 'topis-1107886');
      expect(n.kind, TrafficKind.event);
      expect(n.start, DateTime(2026, 11, 7, 14));
      expect(n.end, DateTime(2026, 11, 8, 22));
      expect(n.title, '[통제] 청계천로 차 없는 거리 행사(청계광장~삼일교, 양방향)');
      expect(n.detail, contains('(토) 14:00 ~ (일) 22:00'));
      // Cheonggyecheon-ro, Cheonggye maydoni yaqini.
      expect(RouteMatcher.haversineKm(n.location, const GeoPoint(37.5688, 126.9829)), lessThan(0.2));
    });

    test('xato kodi → exception; ma\'lumot yo\'q → bo\'sh', () {
      expect(() => SeoulTraffic.rows('<RESULT><CODE>ERROR-500</CODE><MESSAGE>x</MESSAGE></RESULT>'), throwsException);
      expect(SeoulTraffic.rows('<RESULT><CODE>INFO-200</CODE></RESULT>'), isEmpty);
    });

    test('TM → WGS84: Seoul shahar hokimiyati', () {
      // EPSG:5181 da Seoul City Hall ≈ (198,000, 451,900) — ~ (37.566, 126.977).
      final p = SeoulTraffic.tmToWgs84(197990, 451880);
      expect(p.lat, closeTo(37.566, 0.003));
      expect(p.lng, closeTo(126.977, 0.003));
    });
  });
}
