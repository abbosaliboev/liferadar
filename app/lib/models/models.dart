/// LifeRadar domain models (docs/PLAN.*.md §4 bilan mos).
library;

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

/// Ko/En matn. UI tiliga qarab tanlanadi.
class LocalizedText {
  const LocalizedText({required this.ko, required this.en});
  final String ko;
  final String en;

  String of(String languageCode) => languageCode == 'ko' ? ko : en;
}

enum EventCategory {
  conference,
  hackathon,
  concert,
  festival,
  meetup,
  job,
  scholarship,
  performance, // teatr, myuzikl, raqs, kino
  exhibition,
  classes, // ta'lim / tajriba
  startupSupport, // startap qo'llab-quvvatlash e'lonlari (K-Startup)
}

class RadarEvent {
  const RadarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.start,
    required this.end,
    required this.venue,
    required this.city,
    required this.location,
    this.url,
    this.registerUrl,
    this.deadline,
    this.source = 'sample',
    this.sourceName,
    this.imageUrl,
    this.isFree,
    this.price,
    this.placeless = false,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final EventCategory category;
  final List<String> tags;
  final DateTime start;
  final DateTime end;
  final String venue;
  final String city;
  final GeoPoint location;
  final String? url;
  final String? registerUrl;
  final DateTime? deadline;

  /// 'sample' yoki ma'lumot manbasi kaliti (masalan 'seoul-culture').
  final String source;

  /// Foydalanuvchiga ko'rsatiladigan manba nomi (ochiq ma'lumot litsenziyasi talabi — atribut).
  final String? sourceName;
  final String? imageUrl;
  final bool? isFree;
  final String? price;

  /// Aniq manzili yo'q (masalan, butun mamlakat bo'yicha e'lon). [location] — faqat hudud markazi:
  /// xaritaga, yo'nalishga va "yaqinda" kartalariga chiqmaydi; [start]–[end] = ariza muddati.
  final bool placeless;

  bool get isSample => source == 'sample';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': {'ko': title.ko, 'en': title.en},
        'description': {'ko': description.ko, 'en': description.en},
        'category': category.name,
        'tags': tags,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'venue': venue,
        'city': city,
        'lat': location.lat,
        'lng': location.lng,
        if (url != null) 'url': url,
        if (registerUrl != null) 'registerUrl': registerUrl,
        if (deadline != null) 'deadline': deadline!.toIso8601String(),
        'source': source,
        if (sourceName != null) 'sourceName': sourceName,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (isFree != null) 'isFree': isFree,
        if (price != null) 'price': price,
        if (placeless) 'placeless': true,
      };

  static RadarEvent fromJson(Map<String, dynamic> j) {
    LocalizedText lt(Object? v) {
      final m = (v as Map?)?.cast<String, dynamic>() ?? const {};
      final ko = m['ko'] as String? ?? '';
      return LocalizedText(ko: ko, en: m['en'] as String? ?? ko);
    }

    return RadarEvent(
      id: j['id'] as String,
      title: lt(j['title']),
      description: lt(j['description']),
      category: EventCategory.values.asNameMap()[j['category']] ?? EventCategory.festival,
      tags: [for (final t in (j['tags'] as List? ?? const [])) t as String],
      start: DateTime.parse(j['start'] as String),
      end: DateTime.parse(j['end'] as String),
      venue: j['venue'] as String? ?? '',
      city: j['city'] as String? ?? '',
      location: GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
      url: j['url'] as String?,
      registerUrl: j['registerUrl'] as String?,
      deadline: j['deadline'] == null ? null : DateTime.parse(j['deadline'] as String),
      source: j['source'] as String? ?? 'unknown',
      sourceName: j['sourceName'] as String?,
      imageUrl: j['imageUrl'] as String?,
      isFree: j['isFree'] as bool?,
      price: j['price'] as String?,
      placeless: j['placeless'] as bool? ?? false,
    );
  }
}

class Plan {
  const Plan({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.locationText,
    required this.city,
    this.location,
    this.source = 'sample',
    this.note,
    this.htmlLink,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String locationText;
  final String city;
  final GeoPoint? location;

  /// 'sample' | 'gcal' (Google Calendar) | 'local' (ilovada qo'lda qo'shilgan).
  final String source;
  final String? note;

  /// Google Calendar'dagi event sahifasi (faqat 'gcal').
  final String? htmlLink;

  /// Ilovada tahrirlash/o'chirish mumkinmi (kalendar eventlari Google Calendar'da tahrirlanadi).
  bool get isEditable => source == 'local' || source == 'gcal';

  /// Butun kunlik: 00:00 dan boshlanib, kamida 23 soat davom etadi.
  bool get isAllDay => start.hour == 0 && start.minute == 0 && end.difference(start).inHours >= 23;

  /// Google Calendar event id (`gcal-<id>` → `<id>`).
  String? get calendarEventId => source == 'gcal' && id.startsWith('gcal-') ? id.substring(5) : null;

  Plan copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    String? locationText,
    String? city,
    GeoPoint? Function()? location,
    String? source,
    String? Function()? note,
  }) =>
      Plan(
        id: id ?? this.id,
        title: title ?? this.title,
        start: start ?? this.start,
        end: end ?? this.end,
        locationText: locationText ?? this.locationText,
        city: city ?? this.city,
        location: location == null ? this.location : location(),
        source: source ?? this.source,
        note: note == null ? this.note : note(),
        htmlLink: htmlLink,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'locationText': locationText,
        'city': city,
        if (location != null) 'lat': location!.lat,
        if (location != null) 'lng': location!.lng,
        'source': source,
        if (note != null) 'note': note,
      };

  static Plan fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'] as String,
        title: j['title'] as String,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        locationText: j['locationText'] as String? ?? '',
        city: j['city'] as String? ?? '',
        location: j['lat'] == null ? null : GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble()),
        source: j['source'] as String? ?? 'local',
        note: j['note'] as String?,
      );
}

enum InsightKind { planAlert, opportunity, route, deadline }

enum SignalType { event, weather, traffic, deadline }

class Signal {
  const Signal(this.type, this.summary);
  final SignalType type;
  final LocalizedText summary;
}

class SourceLink {
  const SourceLink(this.title, this.url);
  final String title;
  final String? url;
}

enum InsightFeedback { like, dislike, hidden }

class Insight {
  const Insight({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.why,
    required this.confidence,
    this.planId,
    this.eventIds = const [],
    this.signals = const [],
    this.sources = const [],
    this.feedback,
    this.aiModel,
  });

  final String id;
  final InsightKind kind;
  final LocalizedText title;
  final LocalizedText body;
  final LocalizedText why;
  final double confidence;
  final String? planId;
  final List<String> eventIds;
  final List<Signal> signals;
  final List<SourceLink> sources;
  final InsightFeedback? feedback;

  /// [body]/[why] ni Gemini yozgan bo'lsa — model nomi (UI'da "AI" belgisi). Faktlar baribir qoidadan.
  final String? aiModel;

  Insight copyWith({InsightFeedback? feedback, LocalizedText? body, LocalizedText? why, String? aiModel}) => Insight(
        id: id,
        kind: kind,
        title: title,
        body: body ?? this.body,
        why: why ?? this.why,
        confidence: confidence,
        planId: planId,
        eventIds: eventIds,
        signals: signals,
        sources: sources,
        feedback: feedback ?? this.feedback,
        aiModel: aiModel ?? this.aiModel,
      );
}

/// Qidiruvdan topilgan joy (Kakao Local).
class Place {
  const Place({required this.name, required this.address, required this.location});
  final String name;
  final String address;
  final GeoPoint location;
}

enum TravelMode { car, transit }

/// Yo'nalish: avtomobil (Kakao Mobility) yoki jamoat transporti (Google Routes).
class TravelRoute {
  const TravelRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    this.points = const [],
    this.mode = TravelMode.car,
    this.transitLines = const [],
  });
  final int distanceMeters;
  final int durationSeconds;
  final List<GeoPoint> points;
  final TravelMode mode;

  /// Masalan ["KTX 경부"] — faqat transit uchun.
  final List<String> transitLines;
}

/// Yo'l bo'yidagi imkoniyat: event + yo'ldan uzoqligi + qo'shimcha yo'l.
class RouteOpportunity {
  const RouteOpportunity({
    required this.event,
    required this.distanceFromRouteKm,
    required this.score,
    this.detourKm,
    this.detourMinutes,
  });
  final RadarEvent event;
  final double distanceFromRouteKm;
  final double score;
  final double? detourKm;
  final int? detourMinutes;

  RouteOpportunity withDetour(double km, int minutes) => RouteOpportunity(
        event: event,
        distanceFromRouteKm: distanceFromRouteKm,
        score: score,
        detourKm: km,
        detourMinutes: minutes,
      );
}

/// Kunlik ob-havo prognozi (Google Weather, ~10 kun oldinga).
class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.condition,
    required this.type,
    this.maxC,
    this.minC,
    this.rainChance,
  });

  final DateTime date;

  /// Inson o'qiydigan holat ("구름 없음", "Sunny") — so'ralgan tilda.
  final String condition;

  /// Google WeatherCondition.type: CLEAR, CLOUDY, RAIN, SNOW, ...
  final String type;
  final int? maxC;
  final int? minC;

  /// Yog'ingarchilik ehtimoli, %.
  final int? rainChance;

  bool get likelyRain => (rainChance ?? 0) >= 60;
}
