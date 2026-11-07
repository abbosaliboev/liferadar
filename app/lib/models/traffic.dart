import 'models.dart';

/// Rasmiy manbadagi yo'l/transport ta'siri (masalan, 서울시 TOPIS 돌발정보).
///
/// Faktlar manbadan o'zgarishsiz: [detail] — asl matn (dalil), vaqt va joy — manba maydonlaridan.
/// Hech narsa taxmin qilinmaydi: tugash vaqti noma'lum bo'lsa [end] = null.
enum TrafficKind { rally, event, drill, construction, weather, other }

class TrafficNotice {
  const TrafficNotice({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.start,
    required this.location,
    required this.source,
    required this.sourceName,
    this.end,
    this.sourceUrl,
  });

  final String id;
  final TrafficKind kind;

  /// Asl matnning birinchi qatori (masalan "[통제] 청계천로 차 없는 거리 행사").
  final String title;

  /// Asl matn to'liq — foydalanuvchiga dalil sifatida ko'rsatiladi.
  final String detail;

  /// Ta'sir boshlanishi. Tugash — [end] (yarim ochiq oraliq `[start, end)`), noma'lum bo'lsa null.
  final DateTime start;
  final DateTime? end;
  final GeoPoint location;
  final String source;
  final String sourceName;
  final String? sourceUrl;

  /// Tadbir yoki yig'ilish sababli (do'stimizning hujjatidagi asosiy doira).
  bool get isGathering => kind == TrafficKind.rally || kind == TrafficKind.event;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'detail': detail,
        'start': start.toIso8601String(),
        if (end != null) 'end': end!.toIso8601String(),
        'lat': location.lat,
        'lng': location.lng,
        'source': source,
        'sourceName': sourceName,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
      };

  static TrafficNotice fromJson(Map<String, dynamic> j) => TrafficNotice(
        id: j['id'] as String,
        kind: TrafficKind.values.asNameMap()[j['kind']] ?? TrafficKind.other,
        title: j['title'] as String,
        detail: j['detail'] as String,
        start: DateTime.parse(j['start'] as String),
        end: j['end'] == null ? null : DateTime.parse(j['end'] as String),
        location: GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        source: j['source'] as String,
        sourceName: j['sourceName'] as String,
        sourceUrl: j['sourceUrl'] as String?,
      );
}
