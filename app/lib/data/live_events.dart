import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/env.dart';
import 'event_feed.dart';

/// Haqiqiy eventlar jonli bo'lishi uchun:
/// 1) ilova darhol APK ichidagi (yoki oldin yuklangan, keshdagi) feed bilan ochiladi — internetsiz ham;
/// 2) keyin [Env.eventsUrl] dan eng yangi `events.json` yuklanadi (GitHub Actions uni har kuni yangilaydi);
/// 3) yangisi tekshiriladi va yangiroq bo'lsa ekranga chiqadi va keshga yoziladi.
abstract final class LiveEvents {
  static const prefsKey = 'events_feed_cache';

  /// main() da: asset va keshdagidan yangirog'i.
  static Future<EventFeed> initial(SharedPreferences prefs, {AssetBundle? bundle}) async {
    final bundled = await EventFeed.load(bundle);
    final raw = prefs.getString(prefsKey);
    if (raw == null) return bundled;
    try {
      return EventFeed.newest(bundled, EventFeed.parse(raw));
    } catch (_) {
      return bundled;
    }
  }

  /// Internetdan yangi feed. Yangiroq va to'g'ri bo'lsa — qaytaradi va keshlaydi, aks holda null.
  static Future<EventFeed?> fetch(
    SharedPreferences prefs,
    EventFeed current, {
    http.Client? client,
    String url = Env.eventsUrl,
  }) async {
    if (url.isEmpty) return null;
    final c = client ?? http.Client();
    try {
      final res = await c.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        debugPrint('LiveEvents: HTTP ${res.statusCode}');
        return null;
      }
      final raw = utf8.decode(res.bodyBytes);
      final feed = EventFeed.parse(raw);
      if (!feed.isUsable || !feed.isNewerThan(current)) return null;
      await prefs.setString(prefsKey, raw);
      return feed;
    } catch (e) {
      debugPrint('LiveEvents: $e'); // internet yo'q — mavjud feed bilan davom etamiz
      return null;
    } finally {
      if (client == null) c.close();
    }
  }
}
