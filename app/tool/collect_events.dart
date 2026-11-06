// Ochiq API'lardan haqiqiy eventlarni yig'ib, ilova o'qiydigan JSON'ga yozadi.
//
//   cd app && dart run tool/collect_events.dart [--days=90]
//
// Natija: assets/data/events.json (ilova ichiga asset sifatida qo'shiladi).
// Kalitlar faqat shu skriptda ishlatiladi — ilova bundle'iga tushmaydi.
//
// Manbalar (kalit env.json'da):
//   SEOUL_OPEN_API_KEY — 서울 열린데이터광장, 문화행사 (bo'lmasa 'sample' → atigi 5 qator)
//   DATA_GO_KR_KEY     — 공공데이터포털 (Decoding kalit): TourAPI 축제 (butun Koreya) + K-Startup 사업공고
//
// Faqat rasmiy ochiq API'lar. Foydalanish shartlari scraping'ni taqiqlagan saytlar (masalan Dev-Event)
// ishlatilmaydi.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:liferadar/models/models.dart';
import 'package:liferadar/services/sources/kstartup.dart';
import 'package:liferadar/services/sources/seoul_culture.dart';
import 'package:liferadar/services/sources/tour_festival.dart';

const _out = 'assets/data/events.json';
const _userAgent = 'LifeRadar-collector/0.1 (hackathon MVP)';

Future<void> main(List<String> args) async {
  final days = int.tryParse(
        args.firstWhere((a) => a.startsWith('--days='), orElse: () => '--days=90').split('=').last,
      ) ??
      90;
  final env = File('env.json').existsSync()
      ? (jsonDecode(File('env.json').readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final until = today.add(Duration(days: days));
  bool inWindow(RadarEvent e) => !e.end.isBefore(today) && e.start.isBefore(until);

  final client = http.Client();
  final events = <String, RadarEvent>{};
  final sources = <Map<String, dynamic>>[];

  // ── 서울시 문화행사 ──
  final seoulKey = (env['SEOUL_OPEN_API_KEY'] as String?)?.trim();
  final key = seoulKey == null || seoulKey.isEmpty ? 'sample' : seoulKey;
  if (key == 'sample') stderr.writeln('! SEOUL_OPEN_API_KEY yo\'q — sample kalit (5 qator) ishlatiladi');
  try {
    final found = await _collectSeoul(client, key, today, inWindow);
    for (final e in found) {
      events[e.id] = e;
    }
    sources.add({
      'id': SeoulCulture.source,
      'name': SeoulCulture.sourceName,
      'url': 'https://data.seoul.go.kr/dataList/OA-15486/S/1/datasetView.do',
      'license': '공공누리',
      'count': found.length,
    });
    stdout.writeln('✓ ${SeoulCulture.sourceName}: ${found.length} ta event');
  } catch (e) {
    stderr.writeln('✗ ${SeoulCulture.sourceName}: $e');
  }
  // ── TourAPI 축제 (butun Koreya) ──
  final dataKey = (env['DATA_GO_KR_KEY'] as String?)?.trim() ?? '';
  if (dataKey.isEmpty) {
    stderr.writeln('! DATA_GO_KR_KEY yo\'q — TourAPI o\'tkazib yuborildi');
  } else {
    try {
      final found = await _collectTour(client, dataKey, today, inWindow);
      for (final e in found) {
        events[e.id] = e;
      }
      sources.add({
        'id': TourFestival.source,
        'name': TourFestival.sourceName,
        'url': 'https://www.data.go.kr/data/15101578/openapi.do',
        'license': '공공누리',
        'count': found.length,
      });
      stdout.writeln('✓ ${TourFestival.sourceName}: ${found.length} ta event');
    } catch (e) {
      stderr.writeln('✗ ${TourFestival.sourceName}: $e');
    }
  }

  // ── K-Startup 사업공고 (qabul davom etayotgan e'lonlar) ──
  if (dataKey.isNotEmpty) {
    try {
      final found = await _collectKStartup(client, dataKey, today, until);
      for (final e in found) {
        events[e.id] = e;
      }
      sources.add({
        'id': KStartup.source,
        'name': KStartup.sourceName,
        'url': 'https://www.data.go.kr/data/15125364/openapi.do',
        'license': '공공누리',
        'count': found.length,
      });
      stdout.writeln('✓ ${KStartup.sourceName}: ${found.length} ta e\'lon');
    } catch (e) {
      stderr.writeln('✗ ${KStartup.sourceName}: $e');
    }
  }

  client.close();

  if (events.isEmpty) {
    stderr.writeln('Hech qanday event topilmadi — $_out o\'zgartirilmadi.');
    exitCode = 1;
    return;
  }

  final list = events.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  final file = File(_out)..createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent(' ').convert({
    'generatedAt': DateTime.now().toIso8601String(),
    'windowDays': days,
    'sources': sources,
    'events': [for (final e in list) e.toJson()],
  }));
  stdout.writeln('→ $_out: ${list.length} ta event (${(file.lengthSync() / 1024).round()} KB)');
}

/// Ro'yxat ro'yxatga olingan sanasi bo'yicha emas, boshlanish sanasi bo'yicha kamayib boradi.
/// Shuning uchun sahifalarni oxirgi sahifa juda eski bo'lguncha o'qiymiz
/// (uzoq davom etadigan ko'rgazmalar ancha oldin boshlangan bo'lishi mumkin).
Future<List<RadarEvent>> _collectSeoul(
  http.Client client,
  String key,
  DateTime today,
  bool Function(RadarEvent) inWindow,
) async {
  const pageSize = 1000;
  final maxRows = key == 'sample' ? 5 : 8000;
  final stopBefore = today.subtract(const Duration(days: 365));
  final out = <RadarEvent>[];
  var skipped = 0;

  for (var from = 1; from <= maxRows; from += pageSize) {
    final to = key == 'sample' ? 5 : from + pageSize - 1;
    final res = await client.get(SeoulCulture.pageUri(key, from, to), headers: {'User-Agent': _userAgent});
    if (res.statusCode != 200) throw SourceException('HTTP ${res.statusCode}');
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final rows = SeoulCulture.rows(json);
    if (rows.isEmpty) break;

    DateTime? newestInPage;
    for (final r in rows) {
      final e = SeoulCulture.parse(r);
      if (e == null) {
        skipped++;
        continue;
      }
      if (newestInPage == null || e.start.isAfter(newestInPage)) newestInPage = e.start;
      if (inWindow(e)) out.add(e);
    }
    stdout.writeln('  seoul $from–$to: ${rows.length} qator, mos: ${out.length}');
    if (to >= SeoulCulture.totalCount(json)) break;
    if (newestInPage != null && newestInPage.isBefore(stopBefore)) break;
    await Future<void>.delayed(const Duration(milliseconds: 400)); // serverga yumshoq
  }
  if (skipped > 0) stdout.writeln('  (koordinata/sana yo\'q: $skipped qator o\'tkazib yuborildi)');
  return out;
}

/// Festivallar ro'yxati → har biri uchun tavsif (detailCommon2) va vaqt/narx (detailIntro2).
/// Kunlik limit 1000 so'rov: ~110 festival × 2 tafsilot ≈ 230 so'rov.
Future<List<RadarEvent>> _collectTour(
  http.Client client,
  String key,
  DateTime today,
  bool Function(RadarEvent) inWindow,
) async {
  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final res = await client.get(uri, headers: {'User-Agent': _userAgent});
    if (res.statusCode != 200) throw SourceException('HTTP ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  // Oldin boshlanib, hali davom etayotganlar ham kirsin.
  final from = today.subtract(const Duration(days: 60));
  final list = <Map<String, dynamic>>[];
  for (var page = 1; page <= 10; page++) {
    final json = await getJson(TourFestival.listUri(key, from, page: page));
    final items = TourFestival.items(json);
    list.addAll(items);
    if (items.isEmpty || list.length >= TourFestival.totalCount(json)) break;
  }

  // Avval tafsilotsiz parse qilib, oynaga tushmaydiganlarga so'rov yubormaymiz.
  final candidates = [
    for (final item in list)
      if (TourFestival.parse(item) case final e? when inWindow(e)) item,
  ];
  stdout.writeln('  tour: ${list.length} ta festival, oynada: ${candidates.length} → tafsilotlar…');

  final out = <RadarEvent>[];
  var failed = 0;
  const parallel = 4;
  for (var i = 0; i < candidates.length; i += parallel) {
    final batch = candidates.skip(i).take(parallel);
    final parsed = await Future.wait(batch.map((item) async {
      final id = '${item['contentid']}';
      try {
        final (common, intro) = await (
          getJson(TourFestival.commonUri(key, id)),
          getJson(TourFestival.introUri(key, id)),
        ).wait;
        return TourFestival.parse(
          item,
          common: TourFestival.items(common).firstOrNull,
          intro: TourFestival.items(intro).firstOrNull,
        );
      } catch (_) {
        failed++;
        return TourFestival.parse(item); // tafsilotsiz bo'lsa ham ro'yxatda qolsin
      }
    }));
    out.addAll(parsed.whereType<RadarEvent>().where(inWindow));
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  if (failed > 0) stdout.writeln('  (tafsiloti olinmagan: $failed ta)');
  return out;
}

/// Muddati bugundan [until] gacha tugaydigan, qabul ochiq e'lonlar.
Future<List<RadarEvent>> _collectKStartup(http.Client client, String key, DateTime today, DateTime until) async {
  final out = <RadarEvent>[];
  for (var page = 1; page <= 5; page++) {
    final res = await client.get(KStartup.listUri(key, page: page), headers: {'User-Agent': _userAgent});
    if (res.statusCode != 200) throw SourceException('HTTP ${res.statusCode}');
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final rows = KStartup.rows(json);
    for (final r in rows) {
      final e = KStartup.parse(r);
      if (e != null && !e.deadline!.isBefore(today) && e.deadline!.isBefore(until)) out.add(e);
    }
    if (rows.isEmpty || page * 500 >= KStartup.matchCount(json)) break;
  }
  return out;
}
