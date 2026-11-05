import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
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
          // TODO(D3): Google Sign-In + Calendar sinxron
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
            icon: const Icon(Icons.calendar_month),
            label: Text(l10n.connectCalendar),
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty) Text(l10n.plansEmpty),
          for (final p in plans) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.plan,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.event),
                ),
                title: Text(p.title),
                subtitle: Text('${context.formatDate(p.start)} – ${context.formatDate(p.end)}\n${p.locationText}'),
                isThreeLine: true,
                trailing: Builder(builder: (context) {
                  final n = insights.where((i) => i.planId == p.id).length;
                  return n == 0
                      ? const SizedBox.shrink()
                      : Badge(label: Text('$n'), child: const Icon(Icons.auto_awesome));
                }),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
