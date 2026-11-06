import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/app_shell.dart';
import '../weather/weather_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final insights =
        ref.watch(insightsProvider).where((i) => i.feedback != InsightFeedback.hidden).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle), actions: const [EditInterestsButton(), LanguageButton()]),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: insights.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            final text = Theme.of(context).textTheme;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.homeGreeting, style: text.headlineMedium),
              Text(l10n.homeSubtitle, style: text.bodyMedium),
            ]);
          }
          return InsightCard(insight: insights[i - 1]);
        },
      ),
    );
  }
}

class InsightCard extends ConsumerWidget {
  const InsightCard({super.key, required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(insightsProvider.notifier);
    final plan = insight.planId == null
        ? null
        : ref.watch(plansProvider).where((p) => p.id == insight.planId).firstOrNull;

    void feedback(InsightFeedback f) {
      controller.setFeedback(insight.id, f);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.feedbackThanks)));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_kindIcon(insight.kind), color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(context.tr(insight.title), style: text.titleMedium)),
            PopupMenuButton<InsightFeedback>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: feedback,
              itemBuilder: (_) => const [
                PopupMenuItem(value: InsightFeedback.hidden, child: Icon(Icons.visibility_off_outlined)),
              ],
            ),
          ]),
          const SizedBox(height: 6),
          Text(context.tr(insight.body), style: text.bodyLarge),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in insight.signals)
              Chip(avatar: Icon(signalIcon(s.type), size: 16), label: Text(context.tr(s.summary))),
          ]),
          // Reja joyi va sanasi bo'yicha jonli ob-havo (Google Weather).
          if (plan?.location != null) ...[
            const SizedBox(height: 8),
            WeatherChip(location: plan!.location!, date: plan.start),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.whyItMatters, style: text.labelLarge),
              const SizedBox(height: 4),
              Text(context.tr(insight.why)),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.verified_outlined, size: 16, color: scheme.outline),
            const SizedBox(width: 4),
            Text(l10n.confidence((insight.confidence * 100).round()), style: text.bodySmall),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${l10n.sources}: ${insight.sources.map((s) => s.title).join(', ')}',
                style: text.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const Divider(height: 20),
          Row(children: [
            IconButton(
              isSelected: insight.feedback == InsightFeedback.like,
              selectedIcon: const Icon(Icons.thumb_up),
              icon: const Icon(Icons.thumb_up_outlined),
              onPressed: () => feedback(InsightFeedback.like),
            ),
            IconButton(
              isSelected: insight.feedback == InsightFeedback.dislike,
              selectedIcon: const Icon(Icons.thumb_down),
              icon: const Icon(Icons.thumb_down_outlined),
              onPressed: () => feedback(InsightFeedback.dislike),
            ),
            const Spacer(),
            if (insight.eventIds.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  ref.read(mapFocusProvider.notifier).focus(insight.eventIds.first);
                  context.go('/map');
                },
                icon: const Icon(Icons.map_outlined),
                label: Text(l10n.showOnMap),
              ),
          ]),
        ]),
      ),
    );
  }

  IconData _kindIcon(InsightKind k) => switch (k) {
        InsightKind.planAlert => Icons.notifications_active_outlined,
        InsightKind.opportunity => Icons.auto_awesome,
        InsightKind.route => Icons.alt_route,
        InsightKind.deadline => Icons.timer_outlined,
      };
}
