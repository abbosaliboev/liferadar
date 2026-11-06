import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/env.dart';
import '../models/models.dart';
import '../services/calendar_api.dart';
import 'providers.dart';

enum CalendarStatus { disconnected, connecting, syncing, connected, error }

class CalendarState {
  const CalendarState({this.status = CalendarStatus.disconnected, this.error, this.lastSync});

  final CalendarStatus status;
  final String? error;
  final DateTime? lastSync;

  bool get isConnected => status == CalendarStatus.connected || status == CalendarStatus.syncing;
  bool get isBusy => status == CalendarStatus.connecting || status == CalendarStatus.syncing;
}

/// Google Sign-In ni ilova boshida bir marta ishga tushiramiz (web: GIS SDK yuklanadi).
Future<void> initGoogleSignIn() async {
  if (!isGoogleSignInConfigured) return;
  await GoogleSignIn.instance.initialize(clientId: Env.googleOAuthWebClientId);
}

/// Hozircha faqat web uchun OAuth client sozlangan. Android client keyin qo'shiladi.
bool get isGoogleSignInConfigured => kIsWeb && Env.googleOAuthWebClientId.isNotEmpty;

final calendarProvider = NotifierProvider<CalendarController, CalendarState>(CalendarController.new);

/// Google Calendar ulanishi: ruxsat → eventlarni o'qish → joyni geocode qilish → Plans.
/// Access token faqat xotirada (1 soat). Muddati tugasa, foydalanuvchi qayta "ulash"ni bosadi.
class CalendarController extends Notifier<CalendarState> {
  String? _token;
  final Map<String, Place?> _geocodeCache = {};

  @override
  CalendarState build() => const CalendarState();

  /// Tugma bosilganda chaqiriladi (web'da popup faqat foydalanuvchi harakatida ochiladi).
  Future<void> connect() async {
    if (!isGoogleSignInConfigured) {
      state = const CalendarState(status: CalendarStatus.error, error: 'not-configured');
      return;
    }
    state = const CalendarState(status: CalendarStatus.connecting);
    try {
      await _authorize();
      await sync();
    } catch (e) {
      state = CalendarState(status: CalendarStatus.error, error: e.toString());
    }
  }

  Future<void> _authorize() async {
    final authz = await GoogleSignIn.instance.authorizationClient.authorizeScopes([CalendarApi.scope]);
    _token = authz.accessToken;
  }

  Future<void> sync() async {
    final token = _token;
    if (token == null) return;
    state = CalendarState(status: CalendarStatus.syncing, lastSync: state.lastSync);
    try {
      final events = await CalendarApi(token).upcoming();
      final plans = await Future.wait(events.map(_toPlan));
      ref.read(plansProvider.notifier).setPlans(plans);
      state = CalendarState(status: CalendarStatus.connected, lastSync: DateTime.now());
    } on CalendarAuthExpired {
      _token = null;
      state = const CalendarState(status: CalendarStatus.error, error: 'expired');
    } catch (e) {
      state = CalendarState(status: CalendarStatus.error, error: e.toString(), lastSync: state.lastSync);
    }
  }

  /// LifeRadar eventini kalendarga qo'shadi. Ulanmagan bo'lsa avval ruxsat so'raydi.
  Future<String?> addEvent(RadarEvent event, {required String title}) async {
    if (!isGoogleSignInConfigured) throw const CalendarApiException('not-configured');
    if (_token == null) await _authorize();
    try {
      final link = await CalendarApi(_token!).insert(event, title: title);
      await sync();
      return link;
    } on CalendarAuthExpired {
      await _authorize(); // bir marta qayta urinamiz
      final link = await CalendarApi(_token!).insert(event, title: title);
      await sync();
      return link;
    }
  }

  /// Rejani Google Calendar'ga yozadi (yangi yoki mavjud eventni tahrirlash), so'ng sinxronlaydi.
  Future<void> savePlan(Plan plan) => _withApi((api) => api.savePlan(plan, eventId: plan.calendarEventId));

  /// Kalendardagi rejani o'chiradi.
  Future<void> deletePlan(Plan plan) async {
    final id = plan.calendarEventId;
    if (id != null) await _withApi((api) => api.delete(id));
  }

  /// Token bo'lmasa ruxsat so'raydi; muddati o'tgan bo'lsa bir marta qayta urinadi. Keyin sinxron.
  Future<void> _withApi(Future<void> Function(CalendarApi api) action) async {
    if (!isGoogleSignInConfigured) throw const CalendarApiException('not-configured');
    if (_token == null) await _authorize();
    try {
      await action(CalendarApi(_token!));
    } on CalendarAuthExpired {
      await _authorize();
      await action(CalendarApi(_token!));
    }
    await sync();
  }

  Future<void> disconnect() async {
    final token = _token;
    _token = null;
    if (token != null) {
      try {
        await GoogleSignIn.instance.authorizationClient.clearAuthorizationToken(accessToken: token);
      } catch (_) {}
    }
    ref.read(plansProvider.notifier).resetToSample();
    state = const CalendarState();
  }

  Future<Plan> _toPlan(CalendarEvent e) async {
    final place = await _geocode(e.location);
    return Plan(
      id: 'gcal-${e.id}',
      title: e.title,
      start: e.start,
      end: e.end,
      locationText: e.location ?? '',
      city: place == null ? '' : place.address.split(' ').first,
      location: place?.location,
      source: 'gcal',
      note: e.description?.isEmpty == true ? null : e.description,
      htmlLink: e.htmlLink,
    );
  }

  /// Kalendardagi joy matni → koordinata (Kakao Local). Topilmasa null — reja xaritada ko'rinmaydi.
  Future<Place?> _geocode(String? text) async {
    if (text == null || text.isEmpty) return null;
    if (_geocodeCache.containsKey(text)) return _geocodeCache[text];
    Place? result;
    try {
      final hits = await ref.read(kakaoApiProvider).searchPlaces(text, size: 1);
      // To'liq manzil bo'lsa ham keyword qidiruv odatda topadi; bo'lmasa birinchi so'z bilan urinamiz.
      result = hits.isNotEmpty
          ? hits.first
          : (await ref.read(kakaoApiProvider).searchPlaces(text.split(RegExp(r'[,\s]')).first, size: 1))
              .firstOrNull;
    } catch (_) {}
    return _geocodeCache[text] = result;
  }
}
