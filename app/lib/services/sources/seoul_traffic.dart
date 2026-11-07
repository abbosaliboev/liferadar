/// 서울시 실시간 돌발 정보 (서울 열린데이터광장 `AccInfo`, 서울시 TOPIS).
/// 집회·행사·공사 등으로 인한 도로 통제. Litsenziya: 공공누리 — [sourceName].
/// Sof Dart — collector skript va testlar ishlatadi. API faqat XML va http qaytaradi,
/// shuning uchun ilova emas, GitHub Actions yig'adi.
library;

import 'dart:math' as math;

import '../../models/models.dart';
import '../../models/traffic.dart';
import 'seoul_culture.dart' show SourceException;
import 'tagger.dart' show unescapeHtml;

class SeoulTraffic {
  static const source = 'seoul-topis';
  static const sourceName = '서울시 TOPIS · 실시간 돌발정보';
  static const sourceUrl = 'https://topis.seoul.go.kr';

  static Uri uri(String key, {int from = 1, int to = 1000}) =>
      Uri.parse('http://openapi.seoul.go.kr:8088/$key/xml/AccInfo/$from/$to/');

  /// Rejalashtirishga aloqador turlar. Avariya, buzilgan mashina kabi qisqa hodisalar kunlik/soatlik
  /// yig'ishda eskirib qoladi — ular olinmaydi.
  static TrafficKind? kindOf(String type, String subtype) => switch (type) {
        'A10' => switch (subtype) {
            '10B02' => TrafficKind.rally,
            '10B03' => TrafficKind.event,
            '10B01' => TrafficKind.drill,
            _ => TrafficKind.event,
          },
        'A04' => TrafficKind.construction,
        'A09' => TrafficKind.weather,
        _ => null,
      };

  /// XML javob → qatorlar (oddiy, tekis tuzilma). Xato kodida [SourceException].
  static List<Map<String, String>> rows(String xml) {
    final code = RegExp(r'<CODE>([^<]*)</CODE>').firstMatch(xml)?.group(1) ?? '';
    if (code == 'INFO-200') return const []; // ma'lumot yo'q
    if (!code.startsWith('INFO-000')) {
      final msg = RegExp(r'<MESSAGE>([^<]*)</MESSAGE>').firstMatch(xml)?.group(1) ?? '';
      throw SourceException('$source: $code $msg'.trim());
    }
    return [
      for (final row in RegExp(r'<row>(.*?)</row>', dotAll: true).allMatches(xml))
        {
          for (final f in RegExp(r'<(\w+)>([^<]*)</\1>').allMatches(row.group(1)!)) f.group(1)!: f.group(2)!,
        },
    ];
  }

  /// Bitta qator → [TrafficNotice]. Turi kerak emas, joyi yoki boshlanishi yo'q bo'lsa null.
  static TrafficNotice? parse(Map<String, String> r) {
    final kind = kindOf(r['acc_type'] ?? '', r['acc_dtype'] ?? '');
    if (kind == null) return null;
    final start = _at(r['occr_date'], r['occr_time']);
    final x = double.tryParse(r['grs80tm_x'] ?? '');
    final y = double.tryParse(r['grs80tm_y'] ?? '');
    if (start == null || x == null || y == null) return null;
    final end = _at(r['exp_clr_date'], r['exp_clr_time']);

    final detail = unescapeHtml(r['acc_info'] ?? '')
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
    if (detail.isEmpty) return null;
    return TrafficNotice(
      id: 'topis-${r['acc_id']}',
      kind: kind,
      title: detail.split('\n').first,
      detail: detail,
      start: start,
      // Manbada tugash boshlanishdan oldin bo'lsa — noto'g'ri qiymat, taxmin qilmaymiz.
      end: end != null && end.isAfter(start) ? end : null,
      location: tmToWgs84(x, y),
      source: source,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
    );
  }

  /// "20261107" + "1400" | "220000" → mahalliy (KST) vaqt. Vaqt bo'lmasa — kun boshi.
  static DateTime? _at(String? date, String? time) {
    final d = (date ?? '').trim();
    if (!RegExp(r'^\d{8}$').hasMatch(d)) return null;
    final t = (time ?? '').trim().padRight(6, '0');
    final hh = int.tryParse(t.substring(0, 2)) ?? 0;
    final mm = int.tryParse(t.substring(2, 4)) ?? 0;
    return DateTime(int.parse(d.substring(0, 4)), int.parse(d.substring(4, 6)), int.parse(d.substring(6, 8)), hh, mm);
  }

  /// GRS80 TM (EPSG:5181, Korea 2000 / Central Belt: lat0 38°, lon0 127°, k0 1, FE 200 000, FN 500 000)
  /// → WGS84. Snyder'ning teskari Transverse Mercator formulasi (GRS80 ≈ WGS84, farq < 1 m).
  static GeoPoint tmToWgs84(double x, double y) {
    const a = 6378137.0;
    const f = 1 / 298.257222101;
    const k0 = 1.0;
    const lat0 = 38 * math.pi / 180;
    const lon0 = 127 * math.pi / 180;
    const fe = 200000.0;
    const fn = 500000.0;
    const e2 = f * (2 - f);
    final ep2 = e2 / (1 - e2);

    double meridian(double phi) =>
        a *
        ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * phi -
            (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * math.sin(2 * phi) +
            (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * math.sin(4 * phi) -
            (35 * e2 * e2 * e2 / 3072) * math.sin(6 * phi));

    final m = meridian(lat0) + (y - fn) / k0;
    final mu = m / (a * (1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256));
    final e1 = (1 - math.sqrt(1 - e2)) / (1 + math.sqrt(1 - e2));
    final phi1 = mu +
        (3 * e1 / 2 - 27 * math.pow(e1, 3) / 32) * math.sin(2 * mu) +
        (21 * e1 * e1 / 16 - 55 * math.pow(e1, 4) / 32) * math.sin(4 * mu) +
        (151 * math.pow(e1, 3) / 96) * math.sin(6 * mu) +
        (1097 * math.pow(e1, 4) / 512) * math.sin(8 * mu);

    final sin1 = math.sin(phi1);
    final cos1 = math.cos(phi1);
    final tan1 = math.tan(phi1);
    final n1 = a / math.sqrt(1 - e2 * sin1 * sin1);
    final t1 = tan1 * tan1;
    final c1 = ep2 * cos1 * cos1;
    final r1 = a * (1 - e2) / math.pow(1 - e2 * sin1 * sin1, 1.5);
    final d = (x - fe) / (n1 * k0);

    final lat = phi1 -
        (n1 * tan1 / r1) *
            (d * d / 2 -
                (5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * ep2) * math.pow(d, 4) / 24 +
                (61 + 90 * t1 + 298 * c1 + 45 * t1 * t1 - 252 * ep2 - 3 * c1 * c1) * math.pow(d, 6) / 720);
    final lon = lon0 +
        (d -
                (1 + 2 * t1 + c1) * math.pow(d, 3) / 6 +
                (5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * ep2 + 24 * t1 * t1) * math.pow(d, 5) / 120) /
            cos1;
    return GeoPoint(lat * 180 / math.pi, lon * 180 / math.pi);
  }
}
