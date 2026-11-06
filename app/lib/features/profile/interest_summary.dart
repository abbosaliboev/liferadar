import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';

/// Tanlangan qiziqishlar: avval faqat bir nechtasi, qolgani "+N" bosilganda ochiladi.
/// Ko'p qiziqish tanlanganda ekranni egallab, chalg'itmasligi uchun.
class InterestSummary extends ConsumerStatefulWidget {
  const InterestSummary({super.key, this.collapsedCount = 4});

  final int collapsedCount;

  @override
  ConsumerState<InterestSummary> createState() => _InterestSummaryState();
}

class _InterestSummaryState extends ConsumerState<InterestSummary> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final selected = ref.watch(interestsProvider);
    final options = interestOptions.where((o) => selected.contains(o.tag)).toList();
    if (options.isEmpty) return Text(l10n.onboardingPickOne, style: context.textStyles.bodySmall);

    final hidden = options.length - widget.collapsedCount;
    final visible = _expanded || hidden <= 0 ? options : options.take(widget.collapsedCount);

    Widget toggle(String label) => Semantics(
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.xl),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm + 2, vertical: 5),
                decoration: BoxDecoration(
                  color: p.surfaceAlt,
                  borderRadius: BorderRadius.circular(Radii.xl),
                ),
                child: Text(label, style: context.textStyles.labelMedium!.copyWith(color: p.textMuted)),
              ),
            ),
          ),
        );

    return SmoothSize(
      alignment: Alignment.topLeft,
      child: Wrap(spacing: 6, runSpacing: 6, children: [
        for (final o in visible) InterestChip(label: context.tr(o.label), icon: o.icon, hue: o.hue, dense: true),
        if (hidden > 0) toggle(_expanded ? l10n.showLess : '+$hidden'),
      ]),
    );
  }
}
