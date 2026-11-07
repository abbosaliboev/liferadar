import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart' show Tone;
import '../../data/providers.dart';
import '../../models/models.dart';

/// Rejaga ta'sir qiladigan bitta qisqa xabar (karta ostida / reja oynasida).
/// Manba — InsightEngine qoidalari (ob-havo API, festival/e'lon ma'lumotlari), AI emas.
class PlanSignal {
  const PlanSignal({required this.insight, required this.icon, required this.text, required this.tone, this.event});
  final Insight insight;
  final IconData icon;
  final String text;
  final Tone tone;
  final RadarEvent? event;
}

/// Reja uchun signallar — muhimlik tartibida (ogohlantirish → imkoniyat).
List<PlanSignal> planSignals(BuildContext context, WidgetRef ref, Plan plan) {
  final l10n = context.l10n;
  final insights = ref
      .watch(insightsProvider)
      .where((i) => i.planId == plan.id && i.feedback != InsightFeedback.hidden);
  final out = <PlanSignal>[];
  for (final i in insights) {
    final event = i.eventIds.isEmpty ? null : ref.watch(eventByIdProvider(i.eventIds.first));
    if (i.id.startsWith('rain:')) {
      out.add(PlanSignal(insight: i, icon: Icons.umbrella_outlined, text: l10n.planSignalRain, tone: Tone.info));
    } else if (i.id.startsWith('crowd:') && event != null) {
      out.add(
        PlanSignal(
          insight: i,
          event: event,
          icon: Icons.groups_2_outlined,
          text: l10n.planSignalCrowd(context.tr(event.title)),
          tone: Tone.accent,
        ),
      );
    } else if (event != null) {
      out.add(
        PlanSignal(
          insight: i,
          event: event,
          icon: Icons.auto_awesome_outlined,
          text: l10n.planSignalNearby(context.tr(event.title)),
          tone: Tone.primary,
        ),
      );
    }
  }
  int rank(PlanSignal s) => switch (s.tone) {
    Tone.info => 0,
    Tone.accent => 1,
    _ => 2,
  };
  return out..sort((a, b) => rank(a).compareTo(rank(b)));
}

/// Karta ostidagi ixcham qator: ikonka + bir qatorli matn (ohang rangida).
class PlanSignalLine extends StatelessWidget {
  const PlanSignalLine(this.signal, {super.key});
  final PlanSignal signal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = switch (signal.tone) {
      Tone.info => p.info,
      Tone.accent => p.accent,
      _ => p.primary,
    };
    return Row(
      children: [
        Icon(signal.icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            signal.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelMedium!.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
