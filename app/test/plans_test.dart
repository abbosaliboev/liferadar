import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liferadar/data/providers.dart';
import 'package:liferadar/data/session.dart';
import 'package:liferadar/models/models.dart';
import 'package:liferadar/services/calendar_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.dart' show pumpApp;

Future<ProviderContainer> _container(Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

const _google = '{"kind":"google","name":"Abbos","email":"Abbos@Example.com"}';

void main() {
  group('Qiziqishlar akkaunt bo\'yicha', () {
    test('chiqib, qayta Google bilan kirganda qiziqishlar qaytadi', () async {
      final c = await _container({'session': _google});
      await c.read(interestsProvider.notifier).save({'ai', 'music'});

      await c.read(sessionProvider.notifier).signOut();
      await c.read(sessionProvider.notifier).continueAsGuest();
      expect(c.read(interestsProvider), isEmpty, reason: 'mehmon boshqa odam — aralashmasin');

      // Ilova qayta ochilib, o'sha akkaunt bilan kirildi
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session', _google);
      final c2 = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(c2.dispose);
      expect(c2.read(interestsProvider), {'ai', 'music'});
    });

    test('eski (akkauntsiz) kalit bir marta ko\'chiriladi', () async {
      final c = await _container({
        'session': '{"kind":"guest"}',
        'interests': ['data'],
      });
      expect(c.read(interestsProvider), {'data'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('interests:guest'), ['data']);
      expect(prefs.getStringList('interests'), isNull);
    });
  });

  group('O\'z rejalar', () {
    Plan plan(String id, {String title = 'Gym'}) => Plan(
          id: id,
          title: title,
          start: DateTime(2026, 11, 10, 9),
          end: DateTime(2026, 11, 10, 10),
          locationText: '',
          city: '',
          note: 'bring shoes',
        );

    test('qo\'shish → saqlanadi → tahrirlash → o\'chirish', () async {
      final c = await _container({'session': '{"kind":"guest"}'});
      final n = c.read(plansProvider.notifier);
      final before = c.read(plansProvider).length;

      await n.saveLocal(plan('local-1'));
      expect(c.read(plansProvider).length, before + 1);

      // qayta ochilganda ham bor
      final prefs = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
      addTearDown(c2.dispose);
      final saved = c2.read(plansProvider).firstWhere((p) => p.id == 'local-1');
      expect(saved.source, 'local');
      expect(saved.note, 'bring shoes');

      await c2.read(plansProvider.notifier).saveLocal(plan('local-1', title: 'Gym (legs)'));
      expect(c2.read(plansProvider).where((p) => p.id == 'local-1').single.title, 'Gym (legs)');

      await c2.read(plansProvider.notifier).removeLocal('local-1');
      expect(c2.read(plansProvider).length, before);
    });

    test('tahrirlangan sample reja asl sample\'ni almashtiradi', () async {
      final c = await _container({'session': '{"kind":"guest"}'});
      final sample = c.read(plansProvider).first;
      await c.read(plansProvider.notifier).saveLocal(sample.copyWith(title: 'Mine'));
      final same = c.read(plansProvider).where((p) => p.id == sample.id).toList();
      expect(same.single.title, 'Mine');
      expect(same.single.isEditable, isTrue);
    });
  });

  group('Calendar API tanasi', () {
    test('vaqtli reja UTC dateTime, PATCH da date tozalanadi', () {
      final p = Plan(
        id: 'gcal-abc',
        title: 'Meeting',
        start: DateTime.utc(2026, 11, 10, 1),
        end: DateTime.utc(2026, 11, 10, 2),
        locationText: 'COEX',
        city: 'Seoul',
        source: 'gcal',
      );
      expect(p.calendarEventId, 'abc');
      final post = CalendarApi.planBody(p);
      expect(post['start'], {'dateTime': '2026-11-10T01:00:00.000Z'});
      expect(post['location'], 'COEX');
      final patch = CalendarApi.planBody(p, patch: true);
      expect((patch['start'] as Map).containsKey('date'), isTrue);
      expect((patch['start'] as Map)['date'], isNull);
    });

    test('butun kunlik reja — date (tugash eksklyuziv)', () {
      final p = Plan(
        id: 'local-2',
        title: 'Trip',
        start: DateTime(2026, 11, 20),
        end: DateTime(2026, 11, 22),
        locationText: '',
        city: '',
      );
      expect(p.isAllDay, isTrue);
      final body = CalendarApi.planBody(p);
      expect(body['start'], {'date': '2026-11-20'});
      expect(body['end'], {'date': '2026-11-22'});
    });
  });

  testWidgets('Plans: "+" bilan yangi reja qo\'shiladi', (tester) async {
    await pumpApp(tester, interests: ['ai']);
    await tester.tap(find.byIcon(Icons.event_note_outlined).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('New plan'));
    await tester.pumpAndSettle();
    // Sarlavhasiz saqlab bo'lmaydi
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Dentist');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Plan saved'), findsOneWidget);
    expect(find.text('Dentist'), findsOneWidget);
  });

  testWidgets('Profile: ko\'p qiziqish yig\'ilgan holda, "+N" bilan ochiladi', (tester) async {
    await pumpApp(tester, interests: ['ai', 'music', 'food', 'travel', 'pets', 'art', 'fitness']);
    await tester.tap(find.byIcon(Icons.person_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Pets'), findsNothing);
    await tester.tap(find.text('+3'));
    await tester.pumpAndSettle();
    expect(find.text('Pets'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });
}
