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
