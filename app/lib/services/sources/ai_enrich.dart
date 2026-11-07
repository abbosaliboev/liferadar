/// Gemini bilan event'larni boyitish (faqat `tool/collect_events.dart` da — kalit ilovaga tushmaydi):
/// - koreyscha nom/tavsif → tabiiy ingliz tili (UI inglizcha bo'lsa ham nom koreyscha qolmasin)
/// - mazmunga qarab qiziqish teglari (kalit so'z tagger'idan aniqroq)
///
/// Faktlar (sana, joy, narx) o'zgarmaydi — model faqat matn va teg beradi.
/// Sof Dart: prompt, JSON sxema, javobni o'qish va natijani qo'llash shu yerda (testlanadi).
library;

import 'dart:convert';

import '../../models/models.dart';

/// Ruxsat etilgan teglar (`data/interests.dart` bilan bir xil). Model faqat shulardan tanlaydi.
const allowedTags = [
  'ai', 'developer', 'data', 'startup', 'design', //
  'career', 'student', 'networking', 'finance', 'language', 'books',
  'music', 'culture', 'art', 'movie', 'photo', 'gaming',
  'sports', 'fitness', 'outdoor', 'travel',
  'food', 'family', 'pets', 'fashion', 'volunteer',
];

/// Bitta event uchun model natijasi.
class Enrichment {
  const Enrichment({required this.titleEn, required this.descriptionEn, required this.tags, this.model});

  final String titleEn;
  final String descriptionEn;
  final List<String> tags;
  final String? model;

  Map<String, dynamic> toJson() => {'t': titleEn, 'd': descriptionEn, 'g': tags, if (model != null) 'm': model};

  static Enrichment fromJson(Map<String, dynamic> j) => Enrichment(
        titleEn: j['t'] as String,
        descriptionEn: j['d'] as String,
        tags: [for (final t in (j['g'] as List)) t as String],
        model: j['m'] as String?,
      );
}

class AiEnrich {
  /// Kesh kaliti: koreyscha matn o'zgarmasa, qayta so'ralmaydi (FNV-1a 64, barqaror).
  static String cacheKey(RadarEvent e) {
    var h = 0xcbf29ce484222325;
    for (final b in utf8.encode('${e.title.ko}\n${e.description.ko}')) {
      h ^= b;
      h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  static const systemInstruction =
      'You prepare Korean event listings for an English-language lifestyle app used in Korea.\n'
      'For each item:\n'
      '1. title_en: a natural English title. Translate meaningful words (e.g. 구석구석 → "Every Corner"); '
      'keep proper nouns (venues, organizations, performers, festival brand names) in their common '
      'romanized/English form. No quotes or brackets that are not in the original meaning.\n'
      '2. description_en: a faithful, concise English version (max ~3 short sentences). '
      'Do not invent dates, prices, or facts that are not in the text.\n'
      '3. tags: 1-4 interest tags from the allowed list that a person with that interest would '
      'genuinely care about. Prefer fewer, accurate tags. A play is "culture", not "music", unless it is musical.';

  /// generateContent so'rov tanasi (strukturali JSON javob bilan).
  static Map<String, dynamic> requestBody(List<RadarEvent> batch) => {
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': jsonEncode([
                  for (final e in batch)
                    {
                      'id': e.id,
                      'category': e.category.name,
                      'title': e.title.ko,
                      'description': e.description.ko,
                    },
                ]),
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
          'responseSchema': {
            'type': 'ARRAY',
            'items': {
              'type': 'OBJECT',
              'properties': {
                'id': {'type': 'STRING'},
                'title_en': {'type': 'STRING'},
                'description_en': {'type': 'STRING'},
                'tags': {
                  'type': 'ARRAY',
                  'items': {'type': 'STRING', 'enum': allowedTags},
                },
              },
              'required': ['id', 'title_en', 'description_en', 'tags'],
            },
          },
        },
      };

  /// Model javobi → id bo'yicha natijalar. Noma'lum teglar, bo'sh tarjimalar tashlanadi.
  static Map<String, Enrichment> parseResponse(Map<String, dynamic> json, {String? model}) {
    final text = (((json['candidates'] as List?)?.firstOrNull as Map?)?['content'] as Map?)?['parts'] as List?;
    final raw = text?.map((p) => (p as Map)['text'] ?? '').join();
    if (raw == null || raw.isEmpty) return const {};
    final out = <String, Enrichment>{};
    for (final item in jsonDecode(raw) as List) {
      final m = (item as Map).cast<String, dynamic>();
      final title = (m['title_en'] as String? ?? '').trim();
      final desc = (m['description_en'] as String? ?? '').trim();
      // Sifat tekshiruvi: tarjima qilinmagan yoki boshqa yozuv aralashgan javob keshga tushmasin
      // (qayta so'raladi). Masalan "Guソk-Guソk Live" yoki koreyscha nomni o'zgarishsiz qaytarish.
      if (!isCleanEnglish(title, maxHangul: 0) || !isCleanEnglish(desc, maxHangul: 0.15)) continue;
      out[m['id'] as String] = Enrichment(
        titleEn: title,
        descriptionEn: desc,
        tags: {for (final t in (m['tags'] as List? ?? const [])) if (allowedTags.contains(t)) t as String}.toList(),
        model: model,
      );
    }
    return out;
  }

  /// Yapon kana/xitoy ieroglifi yo'q va hangul ulushi [maxHangul] dan oshmaydi.
  static bool isCleanEnglish(String text, {required double maxHangul}) {
    if (text.isEmpty) return maxHangul > 0; // tavsif bo'sh bo'lishi mumkin, nom — yo'q
    if (RegExp(r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]').hasMatch(text)) return false;
    final letters = RegExp(r'[A-Za-z\uac00-\ud7af]').allMatches(text).length;
    if (letters == 0) return false;
    final hangul = RegExp(r'[\uac00-\ud7af]').allMatches(text).length;
    return hangul / letters <= maxHangul;
  }

  /// Kategoriyaning "langar" tegi — model tashlab ketsa ham qoladi (filtr va tartib barqaror bo'lsin).
  static String? anchorTag(EventCategory c) => switch (c) {
        EventCategory.concert => 'music',
        EventCategory.exhibition => 'art',
        EventCategory.festival || EventCategory.performance => 'culture',
        EventCategory.startupSupport => 'startup',
        EventCategory.hackathon => 'developer',
        EventCategory.job => 'career',
        _ => null,
      };

  /// Natijani event'ga qo'llaydi: inglizcha matn + model teglari (+ langar teg).
  /// Model teg bermasa — eski (kalit so'z) teglar qoladi.
  static RadarEvent apply(RadarEvent e, Enrichment r) {
    final anchor = anchorTag(e.category);
    final tags = r.tags.isEmpty ? e.tags : {?anchor, ...r.tags}.toList();
    return RadarEvent.fromJson({
      ...e.toJson(),
      'title': {'ko': e.title.ko, 'en': r.titleEn},
      'description': {'ko': e.description.ko, 'en': r.descriptionEn.isEmpty ? e.description.ko : r.descriptionEn},
      'tags': tags,
    });
  }
}
