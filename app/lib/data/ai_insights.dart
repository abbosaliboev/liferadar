import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/insight_writer.dart';
import '../models/models.dart';
import '../services/gemini_api.dart';
import 'providers.dart';

final geminiApiProvider = Provider<GeminiApi>((ref) => GeminiApi());

/// Faqat eng yuqoridagi shuncha karta AI bilan yoziladi (tezlik va bepul kvota uchun).
const aiInsightLimit = 6;

/// Insight id → Gemini yozgan matn. Kalit yo'q, xato yoki tekshiruvdan o'tmasa — bo'sh,
/// karta qoida matnida qoladi. Natija qurilmada keshlanadi: faktlar o'zgarmasa so'rov ketmaydi.
final aiInsightTextProvider =
    NotifierProvider<AiInsightTextController, Map<String, InsightWriting>>(AiInsightTextController.new);

class AiInsightTextController extends Notifier<Map<String, InsightWriting>> {
  static const _prefsKey = 'ai_insight_cache';
  static const _maxCached = 120;

  final _inflight = <String>{};
  final _rejected = <String>{}; // tekshiruvdan o'tmagan — shu sessiyada qayta so'ramaymiz
  DateTime? _cooldownUntil;
  Map<String, String> _keyById = const {};

  @override
  Map<String, InsightWriting> build() {
    final api = ref.watch(geminiApiProvider);
    if (!api.isConfigured) return const {};
    final base = ref.watch(baseInsightsProvider);
    if (base.isEmpty) return const {};

    final plans = {for (final p in ref.watch(plansProvider)) p.id: p};
    final events = {for (final e in ref.watch(eventsProvider)) e.id: e};
    final interests = ref.watch(interestsProvider);
    final hidden = ref.watch(insightFeedbackProvider);
    final now = ref.watch(nowProvider);
    final today = DateTime(now.year, now.month, now.day);

    final cache = _readCache();
    final keyById = <String, String>{};
    final todo = <String, Map<String, dynamic>>{};
    final out = <String, InsightWriting>{};
    // Rasmiy yo'l ta'siri kartalari shablon matnda qoladi (판별 로직 §12) — AI qayta yozmaydi.
    final candidates = base.where((i) => hidden[i.id] != InsightFeedback.hidden && !i.id.startsWith('traffic:'));
    for (final i in candidates.take(aiInsightLimit)) {
      final facts = InsightWriter.facts(
        i,
        plan: plans[i.planId],
        event: i.eventIds.isEmpty ? null : events[i.eventIds.first],
        interests: interests,
        today: today,
      );
      final key = InsightWriter.cacheKey(facts);
      keyById[i.id] = key;
      final hit = cache[key];
      if (hit != null) {
        out[i.id] = hit;
      } else if (!_inflight.contains(key) && !_rejected.contains(key)) {
        todo[i.id] = facts;
      }
    }
    _keyById = keyById;

    final cooling = _cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!);
    if (todo.isNotEmpty && !cooling) Future.microtask(() => _fetch(todo, Map.of(keyById)));
    return out;
  }

  Future<void> _fetch(Map<String, Map<String, dynamic>> todo, Map<String, String> keys) async {
    final requested = [for (final id in todo.keys) keys[id]!];
    _inflight.addAll(requested);
    try {
      final (json, model) = await ref.read(geminiApiProvider).generate(InsightWriter.requestBody([...todo.values]));
      final written = InsightWriter.parseResponse(json, factsById: todo, model: model);
      _rejected.addAll([for (final id in todo.keys) if (!written.containsKey(id)) keys[id]!]);
      if (written.isEmpty) return;

      final cache = _readCache();
      for (final e in written.entries) {
        cache[keys[e.key]!] = e.value;
      }
      await _writeCache(cache);

      if (!ref.mounted) return;
      final next = {...state};
      for (final e in written.entries) {
        if (_keyById[e.key] == keys[e.key]) next[e.key] = e.value; // shu orada faktlar o'zgarmagan bo'lsa
      }
      state = next;
    } catch (e) {
      _cooldownUntil = DateTime.now().add(const Duration(minutes: 2)); // tarmoq/kvota — bir oz kutamiz
      debugPrint('Gemini insight: $e');
    } finally {
      _inflight.removeAll(requested);
    }
  }

  Map<String, InsightWriting> _readCache() {
    final raw = ref.read(sharedPrefsProvider).getString(_prefsKey);
    if (raw == null) return {};
    try {
      return {
        for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
          e.key: InsightWriting.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeCache(Map<String, InsightWriting> cache) {
    final entries = cache.entries.toList();
    final kept = entries.length > _maxCached ? entries.sublist(entries.length - _maxCached) : entries;
    return ref
        .read(sharedPrefsProvider)
        .setString(_prefsKey, jsonEncode({for (final e in kept) e.key: e.value.toJson()}));
  }
}
