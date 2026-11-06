import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'calendar_controller.dart';
import 'interests.dart';
import 'providers.dart';

// ─────────────────────────── Theme / til (saqlanadi) ───────────────────────────

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() => ThemeMode.values.asNameMap()[ref.read(sharedPrefsProvider).getString(_key)] ?? ThemeMode.system;

  Future<void> set(ThemeMode m) async {
    state = m;
    await ref.read(sharedPrefsProvider).setString(_key, m.name);
  }
}

/// null = qurilma tili.
final localeProvider = NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  static const _key = 'locale';

  @override
  Locale? build() {
    final code = ref.read(sharedPrefsProvider).getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? l) async {
    state = l;
    final prefs = ref.read(sharedPrefsProvider);
    l == null ? await prefs.remove(_key) : await prefs.setString(_key, l.languageCode);
  }
}

// ─────────────────────────── Sessiya (mehmon / Google) ───────────────────────────

enum SessionKind { guest, google }

class Session {
  const Session({required this.kind, this.name, this.email, this.photoUrl});

  final SessionKind kind;
  final String? name;
  final String? email;
  final String? photoUrl;

  bool get isGuest => kind == SessionKind.guest;

  Map<String, dynamic> toJson() => {'kind': kind.name, 'name': name, 'email': email, 'photoUrl': photoUrl};

  static Session? fromJson(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return Session(
        kind: SessionKind.values.byName(j['kind'] as String),
        name: j['name'] as String?,
        email: j['email'] as String?,
        photoUrl: j['photoUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// null = tizimga kirilmagan (login ekrani).
/// Google identifikatsiyasi faqat profil uchun (ism/email/rasm) — parol yoki token saqlanmaydi.
final sessionProvider = NotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends Notifier<Session?> {
  static const _key = 'session';
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;

  @override
  Session? build() {
    ref.onDispose(() => _sub?.cancel());
    return Session.fromJson(ref.read(sharedPrefsProvider).getString(_key));
  }

  /// Google tugmasi (web: GIS renderButton) natijasini tinglaydi.
  /// Login ekrani ochilganda chaqiriladi; [onSignedIn] — keyingi ekranga o'tish.
  void listenForGoogle(void Function() onSignedIn, void Function(Object error) onError) {
    if (!isGoogleSignInConfigured) return;
    _sub?.cancel();
    _sub = GoogleSignIn.instance.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final u = event.user;
        await _save(Session(kind: SessionKind.google, name: u.displayName, email: u.email, photoUrl: u.photoUrl));
        onSignedIn();
      }
    }, onError: onError);
  }

  Future<void> continueAsGuest() => _save(const Session(kind: SessionKind.guest));

  Future<void> signOut() async {
    await ref.read(calendarProvider.notifier).disconnect();
    if (isGoogleSignInConfigured && state?.kind == SessionKind.google) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await ref.read(sharedPrefsProvider).remove(_key);
    state = null;
  }

  Future<void> _save(Session s) async {
    state = s;
    await ref.read(sharedPrefsProvider).setString(_key, jsonEncode(s.toJson()));
  }
}
