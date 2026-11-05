import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/data/providers.dart';
import 'package:liferadar/data/sample_data.dart';
import 'package:liferadar/main.dart';

void main() {
  test('interestScore: mos teglar ulushi', () {
    final expo = sampleEvents.firstWhere((e) => e.id == 'ev-busan-ai-expo'); // ai, startup
    final concert = sampleEvents.firstWhere((e) => e.id == 'ev-busan-concert'); // music
    expect(interestScore(expo, {'ai'}), 0.5);
    expect(interestScore(expo, {'ai', 'startup'}), 1.0);
    expect(interestScore(concert, {'ai'}), 0.0);
  });

  testWidgets('Home insightlarni ko\'rsatadi va til almashadi', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LifeRadarApp()));
    await tester.pumpAndSettle();

    expect(find.text('Signals for you'), findsOneWidget);
    expect(find.text('Busan trip on Nov 20'), findsOneWidget);

    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    expect(find.text('나를 위한 신호'), findsOneWidget);
    expect(find.text('11월 20일 부산 방문'), findsOneWidget);
  });

  testWidgets('Kalit yo\'q bo\'lsa Map tab xabar ko\'rsatadi', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LifeRadarApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.map_outlined).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Kakao Map key is missing'), findsOneWidget);
  });
}
