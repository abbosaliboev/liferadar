/// Gemini bilan Insight kartasining matnini yozish ("why for you").
///
/// Qoidalar ([InsightEngine]) faktni tanlaydi: qaysi reja, qaysi event, masofa, sana, ehtimollik.
/// Model faqat shu faktlardan [Insight.body] va [Insight.why] ni tabiiy tilda qayta yozadi.
/// Javob tekshiriladi: faktlarda yo'q raqam chiqsa yoki matn bo'sh bo'lsa, o'sha karta
/// qoida matnida qoladi. Shuning uchun AI xato qilsa ham karta noto'g'ri bo'lmaydi.
///
/// Sof Dart: Flutter va HTTP yo'q (prompt, sxema, kesh kaliti, validatsiya). Keyin `ai` repo'ga
/// yoki server proxy'ga ko'chirish uchun shu fayl yetarli. Transport: `services/gemini_api.dart`.
library;

import 'dart:convert';

import '../models/models.dart';

/// Prompt yoki sxema o'zgarsa, oshiring: eski kesh avtomatik eskiradi.
const insightPromptVersion = 3;

/// Model yozgan matn.
class InsightWriting {
  const InsightWriting({required this.body, required this.why, required this.model});

  final LocalizedText body;
  final LocalizedText why;
  final String model;

  Map<String, dynamic> toJson() => {'bk': body.ko, 'be': body.en, 'wk': why.ko, 'we': why.en, 'm': model};

  static InsightWriting fromJson(Map<String, dynamic> j) => InsightWriting(
        body: LocalizedText(ko: j['bk'] as String, en: j['be'] as String),
        why: LocalizedText(ko: j['wk'] as String, en: j['we'] as String),
        model: j['m'] as String,
      );
}

abstract final class InsightWriter {
  static const systemInstruction =
      'You write the text of insight cards for LifeRadar, a lifestyle assistant for people living in Korea. '
      'Each card connects the user\'s own plans and interests with events, deadlines or weather.\n'
      'For each input item write, in both Korean and English:\n'
      '- body: 1-2 short sentences. Say what is happening and one concrete thing the user can do.\n'
      '- why: 1 sentence. Explain why this matters to THIS user, linking their plan and/or interests '
      'to the event or weather. Be specific, not generic.\n'
      '"facts" is a plain rule-based summary: use it for facts only and do NOT copy its wording. '
      'Never write generic lines like "Matches your interests (...)". Mention the user\'s plan by its title or place '
      'when there is one, and say what the event actually is (from event.about / category).\n'
      'Strict rules:\n'
      '1. Use only facts in the item (facts, signals, plan, event, user_interests). Never invent dates, times, '
      'prices, distances, percentages, capacities or claims. Any number you write must appear in the item.\n'
      '2. Event names: use title_en in English and title_ko in Korean. In English text, write Korean place, '
      'venue and city names in their common English/romanized form (부산 해운대 → "Haeundae, Busan", '
      '대전컨벤션센터 → "Daejeon Convention Center"); no Hangul in English text. In Korean text keep them in Korean.\n'
      '3. Korean: natural, polite 해요체. English: friendly and plain. No emojis, no hashtags, no quotes around the whole text.\n'
      '4. Do not mention AI, confidence scores or data sources.';

  /// Bitta karta uchun modelga beriladigan faktlar (JSON). Kesh kaliti ham shundan olinadi.
  static Map<String, dynamic> facts(
    Insight insight, {
    Plan? plan,
    RadarEvent? event,
    Set<String> interests = const {},
    required DateTime today,
  }) =>
      {
        'id': insight.id,
        'kind': insight.kind.name,
        'today': _ymd(today),
        'facts': {
          'headline': insight.title.en,
          'en': insight.body.en,
          'ko': insight.body.ko,
          'rule': insight.why.en,
        },
        'signals': [for (final s in insight.signals) s.summary.en],
        if (plan != null)
          'plan': {
            'title': plan.title,
            if (plan.locationText.isNotEmpty) 'place': plan.locationText,
            'start': _ymd(plan.start),
            'end': _ymd(plan.end),
          },
        if (event != null)
          'event': {
            'title_ko': event.title.ko,
            'title_en': event.title.en,
            'category': event.category.name,
            'about': _clip(event.description.en, 280),
            if (event.venue.isNotEmpty) 'venue': event.venue,
            if (event.city.isNotEmpty) 'city': event.city,
            'start': _ymd(event.start),
            'end': _ymd(event.end),
            if (event.deadline != null) 'registration_deadline': _ymd(event.deadline!),
            'tags': event.tags,
          },
        'user_interests': [
          for (final t in event?.tags ?? const <String>[])
            if (interests.contains(t)) t,
        ],
      };

  /// Faktlar o'zgarmasa, qayta so'ralmaydi. Ikki xil boshlang'ich qiymatli FNV-1a 32 → 16 hex.
  /// Faqat 32-bit arifmetika: web (JS) va Android'da natija bir xil.
  static String cacheKey(Map<String, dynamic> facts) => hash('v$insightPromptVersion\n${jsonEncode(facts)}');

  static String hash(String text) {
    final bytes = utf8.encode(text);
    return _fnv32(bytes, 0x811c9dc5) + _fnv32(bytes, 0x050c5d1f);
  }

  static String _fnv32(List<int> bytes, int seed) {
    var h = seed;
    for (final b in bytes) {
      h ^= b;
      // h * 16777619 (= 2^24 + 403) — JS'da aniqlik yo'qolmasligi uchun bo'lib ko'paytiramiz.
      h = (((h << 24) & 0xFFFFFFFF) + h * 403) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static Map<String, dynamic> requestBody(List<Map<String, dynamic>> items) => {
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': jsonEncode(items)},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.4,
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'id': {'type': 'STRING'},
                'body_ko': {'type': 'STRING'},
                'body_en': {'type': 'STRING'},
                'why_ko': {'type': 'STRING'},
                'why_en': {'type': 'STRING'},
              },
              'required': ['id', 'body_ko', 'body_en', 'why_ko', 'why_en'],
            },
          },
        },
      };

  /// Model javobi → id bo'yicha matn. Tekshiruvdan o'tmaganlar tashlanadi (qoida matni qoladi).
  static Map<String, InsightWriting> parseResponse(
    Map<String, dynamic> json, {
    required Map<String, Map<String, dynamic>> factsById,
    required String model,
  }) {
    final parts = (((json['candidates'] as List?)?.firstOrNull as Map?)?['content'] as Map?)?['parts'] as List?;
    final raw = parts?.map((p) => (p as Map)['text'] ?? '').join();
    if (raw == null || raw.isEmpty) return const {};
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const {};
    }
    if (decoded is! List) return const {};
    final out = <String, InsightWriting>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      final id = item['id'];
      final facts = factsById[id];
      if (id is! String || facts == null) continue;
      String field(String k) => (item[k] is String ? item[k] as String : '').trim();
      final texts = [field('body_ko'), field('body_en'), field('why_ko'), field('why_en')];
      if (!texts.every((t) => isGrounded(t, facts))) continue;
      if (!_hangul.hasMatch(texts[0]) || !_hangul.hasMatch(texts[2])) continue; // ko matn koreyscha bo'lsin
      out[id] = InsightWriting(
        body: LocalizedText(ko: texts[0], en: texts[1]),
        why: LocalizedText(ko: texts[2], en: texts[3]),
        model: model,
      );
    }
    return out;
  }

  /// Matn ishlatsa bo'ladimi: bo'sh emas, juda uzun emas, har bir raqam faktlarda bor.
  static bool isGrounded(String text, Map<String, dynamic> facts) {
    if (text.isEmpty || text.length > 320) return false;
    final source = jsonEncode(facts);
    for (final m in _number.allMatches(text)) {
      if (!source.contains(m.group(0)!)) return false;
    }
    return true;
  }

  static final _number = RegExp(r'\d+(?:\.\d+)?');
  static final _hangul = RegExp(r'[가-힣]');

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _clip(String s, int max) => s.length <= max ? s : '${s.substring(0, max)}…';
}
