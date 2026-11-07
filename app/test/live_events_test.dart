import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liferadar/data/event_feed.dart';
import 'package:liferadar/data/live_events.dart';
import 'package:liferadar/data/sample_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [n] ta event bilan feed JSON'i (sample'lar takrorlanib, id'lari farqli).
String _feedJson(String generatedAt, {int n = 30}) => jsonEncode({
      'generatedAt': generatedAt,
      'sources': [
        {'name': 'TourAPI'},
      ],
      'events': [
        for (var i = 0; i < n; i++) {...sampleEvents[i % sampleEvents.length].toJson(), 'id': 'ev-$i'},
      ],
    });

class _Bundle extends CachingAssetBundle {
  _Bundle(this.raw);
  final String raw;
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(utf8.encode(raw));
}

http.Client _serve(String body, {int status = 200}) =>
    MockClient((_) async => http.Response.bytes(utf8.encode(body), status));

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final current = EventFeed.parse(_feedJson('2026-11-07T02:00:00'));

  test('yangiroq feed qabul qilinadi va keshlanadi', () async {
    final fresh = await LiveEvents.fetch(prefs, current, client: _serve(_feedJson('2026-11-08T06:00:00')), url: 'u');
    expect(fresh, isNotNull);
    expect(fresh!.generatedAt, DateTime(2026, 11, 8, 6));
    expect(prefs.getString(LiveEvents.prefsKey), isNotNull);
  });

  test('eski, juda kichik, buzuq, HTTP xato va internet yo\'q — o\'zgarmaydi', () async {
    Future<EventFeed?> get(http.Client c) => LiveEvents.fetch(prefs, current, client: c, url: 'u');
    expect(await get(_serve(_feedJson('2026-11-06T00:00:00'))), isNull); // eskiroq
    expect(await get(_serve(_feedJson('2026-11-09T00:00:00', n: 3))), isNull); // yarim fayl
    expect(await get(_serve('{"events": [')), isNull); // buzuq JSON
    expect(await get(_serve('not found', status: 404)), isNull);
    expect(await get(MockClient((_) => throw http.ClientException('Failed to fetch'))), isNull);
    expect(prefs.getString(LiveEvents.prefsKey), isNull);
  });

  test('ochilishda: asset va keshdan yangirog\'i', () async {
    final bundle = _Bundle(_feedJson('2026-11-07T02:00:00'));
    expect((await LiveEvents.initial(prefs, bundle: bundle)).generatedAt, DateTime(2026, 11, 7, 2));

    await prefs.setString(LiveEvents.prefsKey, _feedJson('2026-11-10T06:00:00'));
    expect((await LiveEvents.initial(prefs, bundle: bundle)).generatedAt, DateTime(2026, 11, 10, 6));

    // Yangi APK keshdagidan yangiroq bo'lsa — APK'dagisi.
    await prefs.setString(LiveEvents.prefsKey, _feedJson('2026-11-01T06:00:00'));
    expect((await LiveEvents.initial(prefs, bundle: bundle)).generatedAt, DateTime(2026, 11, 7, 2));
  });
}
