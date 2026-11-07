import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/data/providers.dart';
import 'package:liferadar/data/sample_data.dart';
import 'package:liferadar/features/discover/discover_screen.dart';
import 'package:liferadar/features/home/home_screen.dart';
import 'package:liferadar/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [session] null bo'lsa — tizimga kirilmagan (login ekrani).
Future<void> pumpApp(
  WidgetTester tester, {
  List<String>? interests,
  DateTime? now,
  String? session = '{"kind":"guest"}',
  bool setupDone = true,
  String? name = 'Tester',
  String locale = 'en',
}) async {
  // "Animatsiyani kamaytirish" — cheksiz animatsiyalar (radar, shimmer) to'xtaydi;
  // shu bilan birga ilova bu sozlamani hurmat qilishini ham tekshiramiz.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  SharedPreferences.setMockInitialValues({
    'interests': ?interests,
    'session': ?session,
    'setup_done': setupDone,
    'name:guest': ?name,
    // Til tanlangan holat (welcome testida tanlovning o'zi tekshiriladi).
    if (setupDone) 'locale': locale,
  });
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

  testWidgets('Birinchi ishga tushirish: til → tema → login (tanlov saqlanadi)', (tester) async {
    await pumpApp(tester, session: null, setupDone: false, name: null);
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Pick a look'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Pick a look'))).brightness, Brightness.dark); // darhol qo'llanadi
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Look around as a guest'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('setup_done'), isTrue);
    expect(prefs.getString('locale'), 'en');
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testWidgets('Login → mehmon → ism → qiziqishlar → Home ("Hi, Abbos")', (tester) async {
    await pumpApp(tester, session: null, name: null);
    await tester.ensureVisible(find.text('Look around as a guest'));
    await tester.tap(find.text('Look around as a guest'));
    await tester.pumpAndSettle();

    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Abbos ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('What are you into?'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    await tester.tap(find.text('AI'));
    await tester.tap(find.text('Startups'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue (2 selected)'));
    await tester.tap(find.text('Continue (2 selected)'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Abbos'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('session'), contains('guest'));
    expect(prefs.getString('name:guest'), 'Abbos');
    expect(prefs.getStringList('interests:guest'), containsAll(['ai', 'startup']));
  });

  testWidgets('Ism va qiziqish saqlangan bo\'lsa — to\'g\'ri Home', (tester) async {
    await pumpApp(tester, interests: ['ai'], name: 'Abbos');
    expect(find.text('Hi, Abbos'), findsOneWidget);
  });

  testWidgets('Qiziqishlar saqlangan bo\'lsa Home ochiladi va til almashadi', (tester) async {
    await pumpApp(tester, interests: ['ai']);

    expect(find.text('Signals for you'), findsOneWidget);
    // InsightEngine: Busan safari + Asiad konserti → birinchi karta
    expect(find.textContaining('Large concert in Busan'), findsWidgets);

    // Til endi Profile'da
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('한국어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.radar_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('나를 위한 신호'), findsOneWidget);
    expect(find.textContaining('부산 대형 콘서트'), findsWidgets);
  });

  testWidgets('Discover qiziqishga mos eventni birinchi qo\'yadi', (tester) async {
    await pumpApp(tester, interests: ['music']);
    await tester.tap(find.byIcon(Icons.explore_outlined).last);
    await tester.pumpAndSettle();
    // musiqa qiziqishi → konsert ro'yxat boshida
    final first = find.byType(EventCard).first;
    expect(find.descendant(of: first, matching: find.text('Large concert in Busan (sample)')), findsOneWidget);
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
    expect(find.widgetWithText(FilledButton, 'Connect Google Calendar'), findsOneWidget);
  });

  testWidgets('Home: statistika = filtr, "Due soon" faqat muddatlarni ko\'rsatadi', (tester) async {
    await pumpApp(tester, interests: ['ai', 'startup', 'music']);
    // Standart — "All signals" tanlangan
    final allCell = find.bySemanticsLabel(RegExp(r'^All signals \d+'));
    expect(tester.getSemantics(allCell), isSemantics(isSelected: true, isButton: true));

    await tester.tap(find.text('Due soon'));
    await tester.pumpAndSettle();
    expect(find.text('Deadlines coming up'), findsOneWidget);
    expect(find.text('Plan alert'), findsNothing);
    expect(find.text('Deadline'), findsWidgets);
  });

  testWidgets('Home: yonga surish filtrlarni almashtiradi, filtr tepada qadalib qoladi', (tester) async {
    await pumpApp(tester, interests: ['ai', 'startup', 'music']);
    expect(find.text('Signals for you'), findsOneWidget);
    // chapga surish → keyingi filtr (Due soon)
    await tester.fling(find.byType(CustomScrollView), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Deadlines coming up'), findsOneWidget);
    // o'ngga ikki marta → My plans
    await tester.fling(find.byType(CustomScrollView), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(CustomScrollView), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Around your plans'), findsOneWidget);

    // Pastga aylantirilganda ham filtr ko'rinib turadi (pinned)
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Due soon'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Due soon')).dy, lessThan(120)); // ekranning yuqorisida
  });

  testWidgets('Signal oynasi baland ochiladi, tortilsa to\'liq ekran, orqaga tugmasi yopadi', (tester) async {
    await pumpApp(tester, interests: ['ai', 'startup', 'music']);
    await tester.tap(find.byType(InsightCard).first);
    await tester.pumpAndSettle();
    final back = find.byTooltip('Back');
    expect(back, findsOneWidget);
    final screenH = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final before = tester.getTopLeft(back).dy;
    expect(before, lessThan(screenH * 0.15)); // ~90% balandlikda ochildi

    await tester.drag(back, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(back).dy, lessThan(before)); // to'liq ekranga yoyildi

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('👍 qaytariladi (tasdiq bilan)', (tester) async {
    await pumpApp(tester, interests: ['ai', 'startup']);
    final prefs = await SharedPreferences.getInstance();
    await tester.ensureVisible(find.byIcon(Icons.thumb_up_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.thumb_up_outlined).first);
    await tester.pumpAndSettle();
    expect(prefs.getStringList('insight_feedback')!.single, endsWith('|like'));

    // Yana bosish → "Remove your like?" → Remove like
    await tester.tap(find.byIcon(Icons.thumb_up_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Remove your like?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove like'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('insight_feedback'), isEmpty);
    expect(find.byIcon(Icons.thumb_up_rounded), findsNothing);
  });

  testWidgets('Akkauntni o\'chirish: ichkarida + tasdiq → hammasi tozalanib welcome', (tester) async {
    await pumpApp(tester, interests: ['ai'], name: 'Abbos');
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Account & data'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Account & data'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete account'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget); // noldan
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('name:guest'), isNull);
    expect(prefs.getStringList('interests:guest'), isNull);
    expect(prefs.getBool('setup_done'), isNull);
  });

  testWidgets('Ochilgan signal kartasi xiralashadi va saqlanadi', (tester) async {
    await pumpApp(tester, interests: ['ai', 'startup', 'music']);
    double opacityOfFirst() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity;
    expect(opacityOfFirst(), 1);
    await tester.tap(find.byType(InsightCard).first);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // oynani yopish
    await tester.pumpAndSettle();
    expect(opacityOfFirst(), lessThan(1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('seen:guest'), isNotEmpty);
  });

  testWidgets('👎 feedback saqlanadi', (tester) async {
    await pumpApp(tester, interests: ['ai', 'startup']);
    await tester.ensureVisible(find.byIcon(Icons.thumb_down_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.thumb_down_outlined).first);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    // Avval tasdiqlash so'raladi — "Keep" bosilsa hech narsa saqlanmaydi.
    expect(find.text('Not for you?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('insight_feedback'), isNull);

    await tester.tap(find.byIcon(Icons.thumb_down_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Not for me'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('insight_feedback')!.single, endsWith('|dislike'));
    expect(find.text('Got it — fewer signals like this'), findsOneWidget); // toast
  });
}
