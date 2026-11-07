// Rasmiy yo'l ta'siri ma'lumotlarini yig'adi (hozircha: 서울시 TOPIS 돌발정보 — 집회·행사·공사·기상).
//
//   cd app && dart run tool/collect_traffic.dart [--out=tool/out/traffic.json]
//
// API faqat http/XML — shuning uchun ilova emas, GitHub Actions yig'adi va liferadar-data'ga joylaydi.
// Kalit: env.json → SEOUL_OPEN_API_KEY.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:liferadar/services/sources/seoul_traffic.dart';

/// Shundan uzoq kelajakdagi yozuvlar olinmaydi (do'stimiz hujjatidagi boshlang'ich sozlama: 28 kun).
const _horizonDays = 28;

Future<void> main(List<String> args) async {
  final out = args.firstWhere((a) => a.startsWith('--out='), orElse: () => '--out=tool/out/traffic.json').substring(6);
  final env = File('env.json').existsSync()
      ? (jsonDecode(File('env.json').readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};
  final key = (env['SEOUL_OPEN_API_KEY'] as String?)?.trim() ?? '';
  if (key.isEmpty) {
    stderr.writeln('SEOUL_OPEN_API_KEY yo\'q — yig\'ilmadi');
    exit(1);
  }

  final now = DateTime.now();
  final horizon = now.add(const Duration(days: _horizonDays));
  final res = await http.get(SeoulTraffic.uri(key)).timeout(const Duration(seconds: 60));
  if (res.statusCode != 200) {
    stderr.writeln('HTTP ${res.statusCode}');
    exit(1);
  }
  final rows = SeoulTraffic.rows(utf8.decode(res.bodyBytes));
  final notices = [
    for (final r in rows) ?SeoulTraffic.parse(r),
  ].where((n) => (n.end == null || n.end!.isAfter(now)) && n.start.isBefore(horizon)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  final file = File(out)..createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent(' ').convert({
    'generatedAt': now.toUtc().toIso8601String(),
    'horizonDays': _horizonDays,
    'sources': [
      {'id': SeoulTraffic.source, 'name': SeoulTraffic.sourceName, 'url': SeoulTraffic.sourceUrl, 'license': '공공누리'},
    ],
    'notices': [for (final n in notices) n.toJson()],
  }));
  stdout.writeln('→ $out: ${notices.length} ta (jami ${rows.length} qator)');
  for (final n in notices) {
    stdout.writeln('  ${n.kind.name.padRight(12)} ${n.start} → ${n.end ?? '?'}  '
        '(${n.location.lat.toStringAsFixed(5)}, ${n.location.lng.toStringAsFixed(5)})  ${n.title}');
  }
}
