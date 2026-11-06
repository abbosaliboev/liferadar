import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/calendar_controller.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../shell/app_shell.dart';
import '../weather/weather_chip.dart';
import 'plan_editor_sheet.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cal = ref.watch(calendarProvider);
    final now = ref.watch(nowProvider);
    final today = DateTime(now.year, now.month, now.day);
    final plans = ref.watch(plansProvider).where((p) => !p.end.isBefore(today)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final insights = ref.watch(insightsProvider);

    // Kun bo'yicha guruhlash
    final groups = <DateTime, List<Plan>>{};
    for (final p in plans) {
      final d = p.start.isBefore(today) ? today : DateTime(p.start.year, p.start.month, p.start.day);
      groups.putIfAbsent(d, () => []).add(p);
    }

    String dayLabel(DateTime d) {
      final diff = d.difference(today).inDays;
      if (diff == 0) return l10n.today;
      if (diff == 1) return l10n.tomorrow;
      return DateFormat.MMMMEEEEd(context.lang).format(d);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPlans),
        actions: [
          if (cal.isConnected)
            IconButton(
              tooltip: l10n.calendarSync,
              onPressed: cal.isBusy ? null : () => ref.read(calendarProvider.notifier).sync(),
              icon: const Icon(Icons.sync_rounded),
            ),
          const SizedBox(width: Space.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPlanEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.planNew),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (cal.isConnected) await ref.read(calendarProvider.notifier).sync();
        },
        child: ListView(
          // FAB oxirgi kartani yopmasin.
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Space.gutter),
              child: _CalendarCard(),
            ),
            if (cal.isBusy)
              const Shimmer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, 0),
                  child: Column(
                    children: [
                      SkeletonCard(),
                      SizedBox(height: Space.md),
                      SkeletonCard(),
                      SizedBox(height: Space.md),
                      SkeletonCard(lines: 1),
                    ],
                  ),
                ),
              )
            else if (plans.isEmpty)
              EmptyState(
                icon: Icons.event_available_outlined,
                title: l10n.upcoming,
                body: l10n.plansEmptyAdd,
                actions: [
                  FilledButton.icon(
                    onPressed: () => showPlanEditor(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.planNew),
                  ),
                ],
              )
            else
              for (final entry in groups.entries) ...[
                SectionHeader(dayLabel(entry.key)),
                for (var i = 0; i < entry.value.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
                    child: FadeSlideIn(
                      index: i,
                      child: _PlanCard(
                        plan: entry.value[i],
                        signals: insights.where((x) => x.planId == entry.value[i].id).length,
                      ),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final cal = ref.watch(calendarProvider);
    final c = ref.read(calendarProvider.notifier);
    final count = ref.watch(plansProvider).where((x) => x.source == 'gcal').length;

    final error = cal.status != CalendarStatus.error
        ? null
        : switch (cal.error) {
            'not-configured' => l10n.calendarNotConfigured,
            'expired' => l10n.calendarExpired,
            _ => l10n.calendarError(cal.error ?? ''),
          };

    if (cal.isConnected) {
      return Card(
        child: ListTile(
          leading: const IconTile(Icons.calendar_month_outlined, size: 36),
          title: Text(l10n.sourceCalendar),
          subtitle: Text(cal.isBusy ? l10n.calendarSyncing : l10n.calendarConnectedCount(count)),
          trailing: Pill(l10n.connected, tone: Tone.primary, dense: true),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconTile(Icons.calendar_month_outlined),
                const SizedBox(width: Space.md),
                Expanded(child: Text(l10n.connectCalendar, style: t.titleSmall)),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(l10n.calendarPrivacy, style: t.bodySmall),
            if (error != null) ...[
              const SizedBox(height: Space.sm),
              Text(error, style: t.bodySmall!.copyWith(color: p.danger)),
            ],
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: cal.isBusy ? null : c.connect,
              icon: cal.isBusy
                  ? AppSpinner(color: p.textMuted)
                  : const Icon(Icons.link_rounded),
              label: Text(cal.isBusy ? l10n.calendarConnecting : l10n.connect),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.signals});
  final Plan plan;
  final int signals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final allDay = plan.isAllDay;
    final multiDay = plan.end.difference(plan.start).inDays >= 1;
    final time = allDay ? '—' : DateFormat.Hm(context.lang).format(plan.start);

    return Card(
      child: InkWell(
        onTap: () => showPlanEditor(context, plan: plan),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(time, style: t.titleSmall),
                    if (multiDay) ...[
                      const SizedBox(height: 2),
                      Text('~${DateFormat.Md(context.lang).format(plan.end)}', style: t.labelSmall),
                    ],
                  ],
                ),
              ),
              Container(
                width: 3,
                height: 44,
                decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(plan.title, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (plan.source == 'sample') const SampleBadge(),
                        if (plan.source == 'gcal')
                          Tooltip(
                            message: l10n.sourceCalendar,
                            child: Icon(Icons.calendar_month_outlined, size: 16, color: p.textMuted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    MetaRow(
                      plan.location == null ? Icons.location_off_outlined : Icons.place_outlined,
                      plan.locationText.isEmpty ? l10n.noLocation : plan.locationText,
                    ),
                    if (plan.location != null) ...[
                      const SizedBox(height: 6),
                      WeatherChip(location: plan.location!, date: plan.start),
                    ],
                    if (signals > 0) ...[
                      const SizedBox(height: Space.sm),
                      Pill('${l10n.statSignals} $signals', icon: Icons.radar, tone: Tone.primary, dense: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
