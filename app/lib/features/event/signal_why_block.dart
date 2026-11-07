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

/// "Bu signal nega chiqdi" — signal turiga mos yumshoq rangli ixcham blok (chiziqsiz, hoshiyasiz):
/// tur + ishonch, bitta asosiy jumla, ostida sababi (sokin).
/// [standalone] — eventsiz signal oynasi: sarlavha, belgilar va manba havolalari ham shu yerda.
class SignalWhyBlock extends StatelessWidget {
  const SignalWhyBlock({super.key, required this.insight, this.standalone = false});

  final Insight insight;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final (label, icon, tone) = insightKindMeta(context, insight.kind);
    final (fg, bg) = switch (tone) {
      Tone.info => (p.info, p.infoSoft),
      Tone.accent => (p.accent, p.accentSoft),
      Tone.danger => (p.danger, p.dangerSoft),
      _ => (p.primary, p.primarySoft),
    };
    final links = insight.sources.where((s) => s.url != null).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, Space.lg),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: Space.sm),
              Text(label, style: t.labelLarge!.copyWith(color: fg)),
              const Spacer(),
              Text(l10n.confidence((insight.confidence * 100).round()), style: t.labelSmall),
            ],
          ),
          const SizedBox(height: Space.sm),
          if (standalone) ...[Text(context.tr(insight.title), style: t.titleMedium), const SizedBox(height: Space.xs)],
          Text(context.tr(insight.body), style: t.bodyMedium!.copyWith(color: p.text, height: 1.5)),
          const SizedBox(height: Space.sm),
          Text(context.tr(insight.why), style: t.bodySmall),
          if (standalone) ...[
            if (insight.signals.isNotEmpty) ...[
              const SizedBox(height: Space.md),
              QuietTags([for (final s in insight.signals) QuietTag(context.tr(s.summary), icon: signalIcon(s.type))]),
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
        ],
      ),
    );
  }
}
