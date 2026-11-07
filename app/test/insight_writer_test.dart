import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liferadar/ai/insight_writer.dart';
import 'package:liferadar/data/ai_insights.dart';
import 'package:liferadar/data/providers.dart';
import 'package:liferadar/models/models.dart';
import 'package:liferadar/services/gemini_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 11, 6);

const _insight = Insight(
  id: 'nearby:p1:e1',
  kind: InsightKind.opportunity,
  planId: 'p1',
  eventIds: ['e1'],
  title: LocalizedText(ko: '부산에 있는 동안: 재즈 페스티벌', en: 'While you are at Busan: Jazz Festival'),
  body: LocalizedText(ko: '11월 8일 해운대에서 열립니다. 일정 장소에서 약 2.4 km.', en: 'On Nov 8 at Haeundae, about 2.4 km from your plan.'),
  why: LocalizedText(ko: '관심사(#music)와 맞습니다.', en: 'It matches your interests (#music).'),
  confidence: 0.8,
);

final _plan = Plan(
  id: 'p1',
  title: 'Busan trip',
  start: DateTime(2026, 11, 8),
  end: DateTime(2026, 11, 9),
  locationText: '부산역',
  city: '부산',
);

Map<String, dynamic> _facts() => InsightWriter.facts(_insight, plan: _plan, interests: {'music'}, today: _today);

Map<String, dynamic> _response(Object items) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': jsonEncode(items)},
            ],
          },
        },
      ],
    };

Map<String, String> _item({String bodyKo = '11월 8일 해운대에서 재즈 공연이 있어요. 부산 일정 중에 들러 보세요.', String bodyEn = 'Jazz at Haeundae on Nov 8, 2.4 km from your plan.'}) => {
      'id': _insight.id,
      'body_ko': bodyKo,
      'body_en': bodyEn,
      'why_ko': '음악을 좋아하시고 그날 부산에 계세요.',
      'why_en': 'You love music and will already be in Busan.',
    };

void main() {
  test('faktlar: reja va qiziqishlar kiradi, kesh kaliti barqaror', () {
    final f = _facts();
    expect(f['plan'], containsPair('title', 'Busan trip'));
    expect(f['facts'], containsPair('en', _insight.body.en));
    expect(InsightWriter.cacheKey(f), InsightWriter.cacheKey(_facts()));
    final other = InsightWriter.facts(_insight, interests: {'music'}, today: _today);
    expect(InsightWriter.cacheKey(other), isNot(InsightWriter.cacheKey(f)));
  });

  test('kesh kaliti web (JS) va VM\'da bir xil — 32-bit arifmetika', () {
    // `flutter test --platform chrome` bilan ham shu qiymat chiqishi kerak.
    expect(InsightWriter.hash('부산 x 2.4'), '7f66113e5bd3995c');
  });

  test('to\'g\'ri javob qabul qilinadi', () {
    final out = InsightWriter.parseResponse(
      _response([_item()]),
      factsById: {_insight.id: _facts()},
      model: 'm',
    );
    expect(out[_insight.id]!.body.en, contains('Haeundae'));
    expect(out[_insight.id]!.model, 'm');
  });

  test('faktlarda yo\'q raqam (to\'qilgan) — rad etiladi', () {
    final out = InsightWriter.parseResponse(
      _response([_item(bodyEn: 'Tickets cost 35000 won, 2.4 km away.')]),
      factsById: {_insight.id: _facts()},
      model: 'm',
    );
    expect(out, isEmpty);
  });

  test('koreyscha matn koreyscha bo\'lmasa, noma\'lum id, buzuq JSON — rad etiladi', () {
    final facts = {_insight.id: _facts()};
    expect(InsightWriter.parseResponse(_response([_item(bodyKo: 'Jazz on Nov 8')]), factsById: facts, model: 'm'), isEmpty);
    expect(InsightWriter.parseResponse(_response([{..._item(), 'id': 'x'}]), factsById: facts, model: 'm'), isEmpty);
    final broken = {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '[{"id": '},
            ],
          },
        },
      ],
    };
    expect(InsightWriter.parseResponse(broken, factsById: facts, model: 'm'), isEmpty);
  });

  group('aiInsightTextProvider', () {
    Future<(ProviderContainer, List<http.Request>)> setup(http.Response Function(http.Request) handler) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final calls = <http.Request>[];
      final c = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(DateTime(2026, 11, 6, 10)),
          baseInsightsProvider.overrideWithValue([_insight]),
          geminiApiProvider.overrideWithValue(
            GeminiApi(
              apiKey: 'test',
              client: MockClient((r) async {
                calls.add(r);
                return handler(r);
              }),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      return (c, calls);
    }

    test('Gemini matni kartaga qo\'yiladi va keshdan qayta ishlatiladi', () async {
      final (c, calls) = await setup((_) => http.Response.bytes(utf8.encode(jsonEncode(_response([_item()]))), 200));
      c.listen(insightsProvider, (_, _) {});
      expect(c.read(insightsProvider).single.aiModel, isNull); // avval qoida matni
      await pumpEventQueue();
      final i = c.read(insightsProvider).single;
      expect(i.aiModel, GeminiApi.defaultModels.first);
      expect(i.why.en, 'You love music and will already be in Busan.');
      expect(calls, hasLength(1));

      c.invalidate(aiInsightTextProvider);
      expect(c.read(insightsProvider).single.aiModel, isNotNull); // darhol keshdan
      await pumpEventQueue();
      expect(calls, hasLength(1)); // yangi so'rov yo'q
    });

    test('xato bo\'lsa qoida matni qoladi', () async {
      final (c, calls) = await setup((_) => http.Response('quota', 429));
      c.listen(insightsProvider, (_, _) {});
      await pumpEventQueue();
      expect(c.read(insightsProvider).single.body.en, _insight.body.en);
      expect(calls, hasLength(GeminiApi.defaultModels.length)); // zaxira model ham sinab ko'rildi
    });
  });
}
