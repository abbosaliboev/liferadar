import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';

/// `tool/collect_events.dart` yig'gan haqiqiy eventlar (assets/data/events.json).
class EventFeed {
  const EventFeed({this.events = const [], this.generatedAt, this.sources = const []});

  static const empty = EventFeed();
  static const asset = 'assets/data/events.json';

  final List<RadarEvent> events;
  final DateTime? generatedAt;

  /// Manba nomlari (atribut uchun).
  final List<String> sources;

  bool get isEmpty => events.isEmpty;

  static EventFeed parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final events = <RadarEvent>[];
    for (final e in (j['events'] as List? ?? const [])) {
      try {
        events.add(RadarEvent.fromJson((e as Map).cast<String, dynamic>()));
      } catch (_) {
        // Bitta buzuq yozuv butun ro'yxatni to'xtatmasin.
      }
    }
    return EventFeed(
      events: events,
      generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? ''),
      sources: [for (final s in (j['sources'] as List? ?? const [])) (s as Map)['name'] as String],
    );
  }

  /// Asset bo'lmasa yoki buzilgan bo'lsa — bo'sh (ilova sample bilan ishlayveradi).
  static Future<EventFeed> load([AssetBundle? bundle]) async {
    try {
      return parse(await (bundle ?? rootBundle).loadString(asset));
    } catch (e) {
      debugPrint('EventFeed: $e');
      return empty;
    }
  }

  /// Ishlatsa bo'ladigan feed: sanasi bor va yetarlicha event (yarim yozilgan/bo'sh fayl emas).
  bool get isUsable => generatedAt != null && events.length >= minEvents;
  static const minEvents = 20;

  /// [other] bundan yangiroqmi.
  bool isNewerThan(EventFeed other) =>
      generatedAt != null && (other.generatedAt == null || generatedAt!.isAfter(other.generatedAt!));

  /// Ikkisidan yangirog'i (ishlatsa bo'ladiganlar orasidan).
  static EventFeed newest(EventFeed a, EventFeed b) {
    if (!b.isUsable) return a;
    if (!a.isUsable) return b;
    return b.isNewerThan(a) ? b : a;
  }
}
