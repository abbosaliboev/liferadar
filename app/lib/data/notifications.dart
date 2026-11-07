import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notify/notify.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'providers.dart';
import 'session.dart';

/// Bildirishnomalar yoqilganmi (Profile → Sozlamalar). Brauzer ruxsati ham bo'lishi shart.
final notificationsEnabledProvider =
    NotifierProvider<NotificationsController, bool>(NotificationsController.new);

class NotificationsController extends Notifier<bool> {
  static const _key = 'notify_enabled';

  @override
  bool build() => (ref.read(sharedPrefsProvider).getBool(_key) ?? false) && notifyPermission() == 'granted';

  /// Ruxsat so'rab yoqadi. Natija: 'granted' | 'denied' | 'default' | 'unsupported'.
  Future<String> enable() async {
    final r = notifyPermission() == 'granted' ? 'granted' : await requestNotifyPermission();
    if (r == 'granted') {
      state = true;
      await ref.read(sharedPrefsProvider).setBool(_key, true);
    }
    return r;
  }

  Future<void> disable() async {
    state = false;
    await ref.read(sharedPrefsProvider).setBool(_key, false);
  }
}

/// Yangi muhim signallarni tizim xabari sifatida yuboradi — har biri faqat bir marta.
/// Muhim = 2 kun ichida tugaydigan muddat yoki 3 kun ichidagi rejaga oid ogohlantirish.
class SignalNotifier {
  SignalNotifier(this.ref);
  final Ref ref;

  static const _maxPerRun = 3;
  static const _keep = 300;

  String get _key => 'notified:${accountScope(ref.read(sessionProvider))}';

  void dispatch(List<Insight> insights) {
    if (!ref.read(notificationsEnabledProvider)) return;
    final prefs = ref.read(sharedPrefsProvider);
    final sent = prefs.getStringList(_key) ?? const [];
    final now = ref.read(nowProvider);
    final today = DateTime(now.year, now.month, now.day);
    final plans = {for (final p in ref.read(plansProvider)) p.id: p};

    bool important(Insight i) {
      if (i.feedback == InsightFeedback.dislike || i.feedback == InsightFeedback.hidden) return false;
      if (i.kind == InsightKind.deadline) {
        final e = i.eventIds.isEmpty ? null : ref.read(eventByIdProvider(i.eventIds.first));
        final d = e?.deadline;
        if (d == null) return false;
        final left = DateTime(d.year, d.month, d.day).difference(today).inDays;
        return left >= 0 && left <= 2;
      }
      if (i.kind == InsightKind.planAlert) {
        final plan = plans[i.planId];
        if (plan == null) return false;
        final until = DateTime(plan.start.year, plan.start.month, plan.start.day).difference(today).inDays;
        return until >= 0 && until <= 3;
      }
      return false;
    }

    final fresh = insights.where((i) => !sent.contains(i.id) && important(i)).take(_maxPerRun).toList();
    if (fresh.isEmpty) return;

    final lang = _lang();
    final l10n = lookupAppLocalizations(Locale(lang));
    for (final i in fresh) {
      final kind = switch (i.kind) {
        InsightKind.deadline => l10n.kindDeadline,
        InsightKind.planAlert => l10n.kindPlanAlert,
        InsightKind.opportunity => l10n.kindOpportunity,
        InsightKind.route => l10n.kindRoute,
      };
      showSystemNotification('$kind · ${i.title.of(lang)}', i.body.of(lang), tag: i.id);
    }
    final all = [...sent, ...fresh.map((i) => i.id)];
    prefs.setStringList(_key, all.length > _keep ? all.sublist(all.length - _keep) : all);
  }

  /// Sinov xabari (Profile'dagi tugma).
  void test() {
    final l10n = lookupAppLocalizations(Locale(_lang()));
    showSystemNotification('LifeRadar', l10n.notifyTestBody, tag: 'test');
  }

  String _lang() {
    final code = ref.read(localeProvider)?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    return code == 'ko' ? 'ko' : 'en';
  }
}

final signalNotifierProvider = Provider<SignalNotifier>(SignalNotifier.new);
