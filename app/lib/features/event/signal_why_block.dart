import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';

/// Signal turi → (nom, ikonka, ohang). Karta va tafsilotlar bir xil ko'rinsin.
(String, IconData, Tone) insightKindMeta(BuildContext context, InsightKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    InsightKind.planAlert => (l10n.kindPlanAlert, Icons.notifications_active_outlined, Tone.info),
    InsightKind.deadline => (l10n.kindDeadline, Icons.schedule_outlined, Tone.accent),
    InsightKind.opportunity => (l10n.kindOpportunity, Icons.auto_awesome_outlined, Tone.primary),
    InsightKind.route => (l10n.kindRoute, Icons.alt_route_rounded, Tone.primary),
  };
}

/// "Bu signal nega chiqdi": kartadan olib tashlangan batafsil ma'lumot (tafsilotlar oynasida).
class SignalWhyBlock extends StatelessWidget {
  const SignalWhyBlock({super.key, required this.insight, this.showTitle = false});

  final Insight insight;

  /// Eventsiz signal oynasida sarlavha ham shu blokda.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final (label, icon, tone) = insightKindMeta(context, insight.kind);
    final links = insight.sources.where((s) => s.url != null).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border(left: BorderSide(color: p.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(label, icon: icon, tone: tone),
              const SizedBox(width: Space.sm),
              Text(l10n.confidence((insight.confidence * 100).round()), style: t.labelSmall),
            ],
          ),
          const SizedBox(height: Space.md),
          if (showTitle) ...[Text(context.tr(insight.title), style: t.titleMedium), const SizedBox(height: Space.xs)],
          Text(context.tr(insight.body), style: t.bodyMedium!.copyWith(color: p.text)),
          const SizedBox(height: Space.md),
          Text(l10n.signalWhy, style: t.labelMedium!.copyWith(color: p.primary)),
          const SizedBox(height: 2),
          Text(context.tr(insight.why), style: t.bodySmall!.copyWith(color: p.text)),
          if (insight.signals.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [for (final s in insight.signals) Pill(context.tr(s.summary), icon: signalIcon(s.type))],
            ),
          ],
          const SizedBox(height: Space.md),
          Text('${l10n.sources} · ${insight.sources.map((s) => s.title).join(', ')}', style: t.labelSmall),
          for (final s in links)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                onPressed: () => launchUrl(Uri.parse(s.url!), mode: LaunchMode.externalApplication),
                child: Text(l10n.openSource),
              ),
            ),
        ],
      ),
    );
  }
}
