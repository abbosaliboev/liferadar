import '../models/models.dart';
import '../models/traffic.dart';
import 'route_matcher.dart';

/// Rasmiy yo'l ta'siri × foydalanuvchi rejasi → qaror.
///
/// "집회·마라톤·축제 뉴스의 이동 영향 판별 로직" hujjatining (§6–§9) soddalashtirilgan qismi:
/// - vaqt: `[start, end)` yarim ochiq oraliq; marshrut ma'lumoti yo'q → reja boshlanishidan oldingi
///   [windowHours] soat (WINDOW_MATCH), kun bo'yi reja → faqat sana (DATE_MATCH);
/// - joy: e'lon qilingan nuqtadan [nearbyKm] km ichida (NEARBY), aks holda NO_MATCH;
/// - transport turi: rejalarda saqlanmaydi → UNKNOWN, shuning uchun eng yuqori natija CAUTION.
///   RECOMMEND faqat transport turi ma'lum bo'lganda (masalan, Route'dagi avtomobil yo'li) — keyingi bosqich.
/// Bir xil kirish → bir xil natija (tashqi chaqiruv yo'q). "Hech narsa taxmin qilinmaydi".
enum TimeMatch { exact, window, date, possible, none, unknown }

enum SpaceMatch { nearby, none, unknown }

enum TrafficDecision { recommend, caution, reference, needsReview, ignore }

class TrafficMatch {
  const TrafficMatch(this.decision, this.time, this.space, this.distanceKm, this.reasons);
  final TrafficDecision decision;
  final TimeMatch time;
  final SpaceMatch space;
  final double? distanceKm;
  final List<String> reasons;
}

class TrafficMatcher {
  const TrafficMatcher({this.windowHours = 2, this.nearbyKm = 1});

  /// Marshrut yo'q bo'lganda qidiruv oralig'i (hujjat: "일정 시작 - 2시간"). Bu tavsiya emas,
  /// "2 soat oldin chiqing" deb ko'rsatilmaydi.
  final int windowHours;

  /// "Yaqin" chegarasi — aniqlash sozlamasi, tirbandlik radiusi emas.
  final double nearbyKm;

  static const ruleVersion = '1.0';

  TrafficMatch evaluate(Plan plan, TrafficNotice n, DateTime now) {
    // Hujjat §9, 2-qator: reja boshlangan bo'lsa — yangi oldindan ogohlantirish yo'q.
    if (!plan.start.isAfter(now)) {
      return const TrafficMatch(TrafficDecision.ignore, TimeMatch.none, SpaceMatch.unknown, null, ['SCHEDULE_INELIGIBLE']);
    }
    final time = matchTime(plan, n);
    final (space, km) = matchSpace(plan, n);
    if (time == TimeMatch.none || space == SpaceMatch.none) {
      return TrafficMatch(TrafficDecision.ignore, time, space, km, const ['NO_OVERLAP']);
    }
    if (time == TimeMatch.unknown || space == SpaceMatch.unknown) {
      return TrafficMatch(TrafficDecision.needsReview, time, space, km, const ['INSUFFICIENT_MATCH_DATA']);
    }
    // Transport turi noma'lum → CAUTION (hujjat §9, 9-qator). "Kechikish aniq" deyilmaydi.
    return TrafficMatch(
      TrafficDecision.caution,
      time,
      space,
      km,
      [
        time == TimeMatch.window ? 'WINDOW_MATCH' : time == TimeMatch.date ? 'DATE_MATCH' : 'POSSIBLE_MATCH',
        'NEARBY',
        'MODE_UNKNOWN',
      ],
    );
  }

  TimeMatch matchTime(Plan plan, TrafficNotice n) {
    if (plan.isAllDay) {
      // Faqat sanalar: reja kunlaridan birortasi ta'sir kunlariga to'g'ri keladimi.
      final days = <DateTime>[];
      for (var d = _day(plan.start); d.isBefore(plan.end); d = DateTime(d.year, d.month, d.day + 1)) {
        days.add(d);
      }
      return days.any((d) => _coversDay(n, d)) ? TimeMatch.date : TimeMatch.none;
    }
    final windowStart = plan.start.subtract(Duration(hours: windowHours));
    final windowEnd = plan.start;
    final end = n.end;
    if (end == null) {
      // Tugash noma'lum: muddatsiz faol qilinmaydi — faqat boshlanish kunida, boshlangan bo'lsa.
      if (_day(n.start) != _day(windowStart) && _day(n.start) != _day(windowEnd)) return TimeMatch.none;
      return n.start.isBefore(windowEnd) ? TimeMatch.possible : TimeMatch.none;
    }
    return overlaps(windowStart, windowEnd, n.start, end) ? TimeMatch.window : TimeMatch.none;
  }

  (SpaceMatch, double?) matchSpace(Plan plan, TrafficNotice n) {
    final at = plan.location;
    if (at == null) return (SpaceMatch.unknown, null);
    final km = RouteMatcher.haversineKm(at, n.location);
    return (km <= nearbyKm ? SpaceMatch.nearby : SpaceMatch.none, km);
  }

  /// Yarim ochiq oraliqlar: chegaralar tegib turishi kesishish emas.
  static bool overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) =>
      (aStart.isAfter(bStart) ? aStart : bStart).isBefore(aEnd.isBefore(bEnd) ? aEnd : bEnd);

  static bool _coversDay(TrafficNotice n, DateTime day) {
    final next = DateTime(day.year, day.month, day.day + 1);
    final end = n.end;
    if (end == null) return _day(n.start) == day;
    return overlaps(day, next, n.start, end);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
