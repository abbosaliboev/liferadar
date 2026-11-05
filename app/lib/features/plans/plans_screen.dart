import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/calendar_controller.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../shell/app_shell.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plans = [...ref.watch(plansProvider)]..sort((a, b) => a.start.compareTo(b.start));
    final insights = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabPlans), actions: const [LanguageButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _CalendarCard(planCount: plans.length),
          const SizedBox(height: 12),
          if (plans.isEmpty) Text(l10n.plansEmpty),
          for (final p in plans) ...[
            _PlanTile(plan: p, insightCount: insights.where((i) => i.planId == p.id).length),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard({required this.planCount});
  final int planCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cal = ref.watch(calendarProvider);
    final c = ref.read(calendarProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    String? errorText;
    if (cal.status == CalendarStatus.error) {
      errorText = switch (cal.error) {
        'not-configured' => l10n.calendarNotConfigured,
        'expired' => l10n.calendarExpired,
        _ => l10n.calendarError(cal.error ?? ''),
      };
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.calendar_month, color: cal.isConnected ? AppColors.plan : scheme.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                switch (cal.status) {
                  CalendarStatus.connecting => l10n.calendarConnecting,
                  CalendarStatus.syncing => l10n.calendarSyncing,
                  CalendarStatus.connected => l10n.calendarConnectedCount(planCount),
                  _ => l10n.sourceCalendar,
                },
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (cal.isBusy) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(errorText, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 10),
          if (!cal.isConnected)
            FilledButton.icon(
              onPressed: cal.isBusy ? null : c.connect,
              icon: const Icon(Icons.login),
              label: Text(l10n.connectCalendar),
            )
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cal.isBusy ? null : c.sync,
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.calendarSync),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: c.disconnect, child: Text(l10n.calendarDisconnect)),
            ]),
          const SizedBox(height: 6),
          Text(l10n.calendarPrivacy, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.insightCount});
  final Plan plan;
  final int insightCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = plan;
    final sameDay = p.start.year == p.end.year && p.start.month == p.end.month && p.start.day == p.end.day;
    final when = sameDay
        ? context.formatDateTime(p.start)
        : '${context.formatDate(p.start)} – ${context.formatDate(p.end)}';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.location == null ? Theme.of(context).colorScheme.outlineVariant : AppColors.plan,
          foregroundColor: Colors.white,
          child: Icon(p.location == null ? Icons.event_note : Icons.place),
        ),
        title: Row(children: [
          Expanded(child: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (p.source == 'sample') const SampleBadge(),
        ]),
        subtitle: Text('$when\n${p.locationText.isEmpty ? l10n.noLocation : p.locationText}'),
        isThreeLine: true,
        trailing: insightCount == 0 ? null : Badge(label: Text('$insightCount'), child: const Icon(Icons.auto_awesome)),
      ),
    );
  }
}
