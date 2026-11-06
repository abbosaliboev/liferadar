import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/data/providers.dart';
import 'package:liferadar/data/sample_data.dart';
import 'package:liferadar/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, {List<String>? interests, DateTime? now}) async {
  SharedPreferences.setMockInitialValues({'interests': ?interests});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      nowProvider.overrideWithValue(now ?? DateTime(2026, 11, 6, 10)),
    ],
    child: const LifeRadarApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  test('interestScore: mos teglar ulushi', () {
    final expo = sampleEvents.firstWhere((e) => e.id == 'ev-busan-ai-expo'); // ai, startup
    final concert = sampleEvents.firstWhere((e) => e.id == 'ev-busan-concert'); // music, culture
    expect(interestScore(expo, {'ai'}), 0.5);
    expect(interestScore(expo, {'ai', 'startup'}), 1.0);
    expect(interestScore(concert, {'ai'}), 0.0);
  });

  testWidgets('Birinchi ochilishda onboarding → tanlash → Home', (tester) async {
    await pumpApp(tester);
    expect(find.text('What are you into?'), findsOneWidget);
    expect(find.text('Pick at least one'), findsOneWidget);

    await tester.tap(find.text('AI'));
    await tester.tap(find.text('Startups'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue (2 selected)'));
    await tester.pumpAndSettle();

    expect(find.text('Signals for you'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('interests'), containsAll(['ai', 'startup']));
  });

  testWidgets('Qiziqishlar saqlangan bo\'lsa Home ochiladi va til almashadi', (tester) async {
    await pumpApp(tester, interests: ['ai']);

    expect(find.text('Signals for you'), findsOneWidget);
    // InsightEngine: Busan safari + Asiad konserti → birinchi karta
    expect(find.textContaining('Large concert in Busan'), findsWidgets);

    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    expect(find.text('나를 위한 신호'), findsOneWidget);
    expect(find.textContaining('부산 대형 콘서트'), findsWidgets);
  });

  testWidgets('Discover qiziqishga mos eventni birinchi qo\'yadi', (tester) async {
    await pumpApp(tester, interests: ['music']);
    await tester.tap(find.byIcon(Icons.explore_outlined).last);
    await tester.pumpAndSettle();
    // musiqa qiziqishi → konsert ro'yxat boshida
    final first = tester.widget<ListTile>(find.byType(ListTile).first);
    expect((first.title as Text).data, 'Large concert in Busan (sample)');
  });

  testWidgets('Kalit yo\'q bo\'lsa Map tab xabar ko\'rsatadi', (tester) async {
    await pumpApp(tester, interests: ['ai']);
    await tester.tap(find.byIcon(Icons.map_outlined).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Kakao Map key is missing'), findsOneWidget);
  });

  testWidgets('Signal yo\'q bo\'lsa Home yo\'naltiruvchi karta ko\'rsatadi', (tester) async {
    await pumpApp(tester, interests: ['ai'], now: DateTime(2027, 1, 15));
    expect(find.text('No signals yet'), findsOneWidget);
    expect(find.text('Connect Google Calendar'), findsOneWidget);
  });

  testWidgets('👎 feedback saqlanadi', (tester) async {
    await pumpApp(tester, interests: ['ai', 'startup']);
    await tester.tap(find.byIcon(Icons.thumb_down_outlined).first);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('insight_feedback')!.single, endsWith('|dislike'));
  });
}
