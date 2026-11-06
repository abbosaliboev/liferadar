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

enum EventCategory { conference, hackathon, concert, festival, meetup, job, scholarship }

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
  final String source;

  bool get isSample => source == 'sample';
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
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String locationText;
  final String city;
  final GeoPoint? location;
  final String source;
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

  Insight copyWith({InsightFeedback? feedback}) => Insight(
        id: id,
        kind: kind,
        title: title,
        body: body,
        why: why,
        confidence: confidence,
        planId: planId,
        eventIds: eventIds,
        signals: signals,
        sources: sources,
        feedback: feedback ?? this.feedback,
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
