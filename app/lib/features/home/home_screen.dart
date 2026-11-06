import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/calendar_controller.dart';
import '../../data/providers.dart';
import '../../data/session.dart';
import '../../models/models.dart';
import '../event/event_detail_sheet.dart';
import '../weather/weather_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final session = ref.watch(sessionProvider);
    final cal = ref.watch(calendarProvider);
    final plans = ref.watch(plansProvider);
    final insights = ref.watch(insightsProvider).where((i) => i.feedback != InsightFeedback.hidden).toList();
    final now = ref.watch(nowProvider);
    final upcomingPlans = plans.where((x) => !x.end.isBefore(now)).length;
    final deadlines = insights.where((i) => i.kind == InsightKind.deadline).length;
    final name = session == null || session.isGuest ? null : session.name?.split(' ').first;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            if (cal.isConnected) await ref.read(calendarProvider.notifier).sync();
            ref.invalidate(forecastProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: Space.xxxl),
            children: [
              // ── Sarlavha ──
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(DateFormat.MMMMEEEEd(context.lang).format(now), style: t.labelMedium),
                      const SizedBox(height: 2),
                      Text(name == null ? l10n.homeHello : l10n.homeHelloName(name), style: t.headlineSmall),
                    ]),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.tabProfile,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.go('/profile'),
                      child: AppAvatar(photoUrl: session?.photoUrl, name: name, size: 40),
                    ),
                  ),
                ]),
              ),

              // ── Qisqa statistika ──
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
                child: Card(
                  child: IntrinsicHeight(
                    child: Row(children: [
                      _Stat(value: upcomingPlans, label: l10n.statPlans, onTap: () => context.go('/plans')),
                      VerticalDivider(color: p.border, width: 1, indent: Space.md, endIndent: Space.md),
                      _Stat(value: insights.length, label: l10n.statSignals),
                      VerticalDivider(color: p.border, width: 1, indent: Space.md, endIndent: Space.md),
                      _Stat(value: deadlines, label: l10n.statDeadlines, highlight: deadlines > 0),
                    ]),
                  ),
                ),
              ),

              SectionHeader(l10n.homeGreeting),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
                child: Text(l10n.homeSubtitle, style: t.bodySmall),
              ),

              // ── Kartalar ──
              if (cal.isBusy)
                const Shimmer(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Column(children: [
                      SkeletonCard(lines: 3, leading: false),
                      SizedBox(height: Space.md),
                      SkeletonCard(lines: 2, leading: false),
                    ]),
                  ),
                )
              else if (insights.isEmpty)
                EmptyState(
                  icon: Icons.radar,
                  title: l10n.homeEmptyTitle,
                  body: l10n.homeEmptyBody,
                  actions: [
                    FilledButton(onPressed: () => context.go('/plans'), child: Text(l10n.connectCalendar)),
                    OutlinedButton(onPressed: () => context.push('/interests'), child: Text(l10n.interestsEdit)),
                  ],
                )
              else
                for (var i = 0; i < insights.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
                    child: FadeSlideIn(
                      index: i,
                      child: InsightCard(key: ValueKey(insights[i].id), insight: insights[i]),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap, this.highlight = false});
  final int value;
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.lg),
          child: Column(children: [
            Text('$value', style: context.textStyles.headlineSmall!.copyWith(color: highlight ? p.accent : p.text)),
            const SizedBox(height: 2),
            Text(label, style: context.textStyles.labelMedium),
          ]),
        ),
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
    final p = context.palette;
    final t = context.textStyles;
    final feedback = ref.read(insightFeedbackProvider.notifier);
    final plan =
        insight.planId == null ? null : ref.watch(plansProvider).where((x) => x.id == insight.planId).firstOrNull;
    final event = insight.eventIds.isEmpty ? null : ref.watch(eventByIdProvider(insight.eventIds.first));

    final (kindLabel, kindIcon, tone) = switch (insight.kind) {
      InsightKind.planAlert => (l10n.kindPlanAlert, Icons.notifications_active_outlined, Tone.info),
      InsightKind.deadline => (l10n.kindDeadline, Icons.schedule_outlined, Tone.accent),
      InsightKind.opportunity => (l10n.kindOpportunity, Icons.auto_awesome_outlined, Tone.primary),
      InsightKind.route => (l10n.kindRoute, Icons.alt_route_rounded, Tone.primary),
    };

    void send(InsightFeedback f) {
      feedback.set(insight.id, f);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.feedbackThanks), duration: const Duration(seconds: 2)));
    }

    void openMap() {
      ref.read(mapFocusProvider.notifier).focus(event!.id);
      context.go('/map');
    }

    return Card(
      child: InkWell(
        onTap: event == null ? null : () => showEventDetail(context, event, onShowOnMap: openMap),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.xs, Space.xs),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Pill(kindLabel, icon: kindIcon, tone: tone),
              const SizedBox(width: Space.sm),
              Text(l10n.confidence((insight.confidence * 100).round()), style: t.labelSmall),
              const Spacer(),
              PopupMenuButton<InsightFeedback>(
                tooltip: l10n.hide,
                icon: Icon(Icons.more_horiz_rounded, color: p.textMuted),
                onSelected: send,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: InsightFeedback.hidden,
                    child: Row(children: [
                      const Icon(Icons.visibility_off_outlined, size: 20),
                      const SizedBox(width: Space.md),
                      Text(l10n.hide),
                    ]),
                  ),
                ],
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(right: Space.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr(insight.title), style: t.titleMedium),
                const SizedBox(height: Space.xs),
                Text(context.tr(insight.body), style: t.bodyMedium),
                if (plan?.location != null) ...[
                  const SizedBox(height: Space.sm),
                  WeatherChip(location: plan!.location!, date: plan.start),
                ],
                if (insight.signals.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                    for (final s in insight.signals) Pill(context.tr(s.summary), icon: signalIcon(s.type)),
                  ]),
                ],
                const SizedBox(height: Space.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.sm),
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border(left: BorderSide(color: p.primary, width: 3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.whyItMatters, style: t.labelMedium!.copyWith(color: p.primary)),
                    const SizedBox(height: 2),
                    Text(context.tr(insight.why), style: t.bodySmall!.copyWith(color: p.text)),
                  ]),
                ),
              ]),
            ),
            Row(children: [
              Expanded(
                child: Text(
                  '${l10n.sources} · ${insight.sources.map((s) => s.title).join(', ')}',
                  style: t.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: l10n.helpful,
                isSelected: insight.feedback == InsightFeedback.like,
                selectedIcon: Icon(Icons.thumb_up_rounded, color: p.primary, size: 20),
                icon: const Icon(Icons.thumb_up_outlined, size: 20),
                onPressed: () => send(InsightFeedback.like),
              ),
              IconButton(
                tooltip: l10n.notForMe,
                isSelected: insight.feedback == InsightFeedback.dislike,
                selectedIcon: Icon(Icons.thumb_down_rounded, color: p.textMuted, size: 20),
                icon: const Icon(Icons.thumb_down_outlined, size: 20),
                onPressed: () => send(InsightFeedback.dislike),
              ),
              if (event != null && !event.placeless)
                IconButton(tooltip: l10n.showOnMap, icon: const Icon(Icons.map_outlined, size: 20), onPressed: openMap),
            ]),
          ]),
        ),
      ),
    );
  }
}
