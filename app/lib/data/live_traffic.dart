import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env.dart';
import '../models/traffic.dart';

/// Rasmiy yo'l ta'siri ro'yxati (`traffic.json`, GitHub Actions har 3 soatda yangilaydi).
class TrafficFeed {
  const TrafficFeed({this.notices = const [], this.generatedAt});

  static const empty = TrafficFeed();

  final List<TrafficNotice> notices;
  final DateTime? generatedAt;

  static TrafficFeed parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final notices = <TrafficNotice>[];
    for (final n in (j['notices'] as List? ?? const [])) {
      try {
        notices.add(TrafficNotice.fromJson((n as Map).cast<String, dynamic>()));
      } catch (_) {
        // Bitta buzuq yozuv butun ro'yxatni to'xtatmasin.
      }
    }
    return TrafficFeed(notices: notices, generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? ''));
  }

  /// [now] da hali tugamagan e'lonlar.
  List<TrafficNotice> activeAt(DateTime now) => [
        for (final n in notices)
          if (n.end == null ? !n.start.isBefore(DateTime(now.year, now.month, now.day)) : n.end!.isAfter(now)) n,
      ];
}

abstract final class LiveTraffic {
  static const prefsKey = 'traffic_feed_cache';

  static TrafficFeed cached(SharedPreferences prefs) {
    final raw = prefs.getString(prefsKey);
    if (raw == null) return TrafficFeed.empty;
    try {
      return TrafficFeed.parse(raw);
    } catch (_) {
      return TrafficFeed.empty;
    }
  }

  /// Yangiroq va to'g'ri bo'lsa — qaytaradi va keshlaydi. Bo'sh ro'yxat ham to'g'ri javob
  /// ("hozir e'lon yo'q"), lekin yuklab bo'lmasa eski ma'lumot saqlanadi — bu "ta'sir yo'q" degani emas.
  static Future<TrafficFeed?> fetch(
    SharedPreferences prefs,
    TrafficFeed current, {
    http.Client? client,
    String url = Env.trafficUrl,
  }) async {
    if (url.isEmpty) return null;
    final c = client ?? http.Client();
    try {
      final res = await c.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final raw = utf8.decode(res.bodyBytes);
      final feed = TrafficFeed.parse(raw);
      final at = feed.generatedAt;
      if (at == null || (current.generatedAt != null && !at.isAfter(current.generatedAt!))) return null;
      await prefs.setString(prefsKey, raw);
      return feed;
    } catch (e) {
      debugPrint('LiveTraffic: $e');
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
