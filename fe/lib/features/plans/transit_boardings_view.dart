import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/transit_journey.dart';

/// Shared by new search results and previously saved routes.
class TransitBoardingsView extends StatelessWidget {
  const TransitBoardingsView({super.key, required this.boardings});
  final List<TransitBoarding> boardings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.textStyles;
    final p = context.palette;
    String time(DateTime? value) => value == null
        ? ''
        : DateFormat.Md(context.lang).add_Hm().format(value.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in boardings)
          Padding(
            padding: const EdgeInsets.only(top: Space.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (b.mode) {
                    'bus' => Icons.directions_bus_rounded,
                    'subway' => Icons.subway_rounded,
                    'rail' => Icons.train_rounded,
                    _ => Icons.directions_transit_rounded,
                  },
                  size: 20,
                  color: p.primary,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.line.isEmpty ? l10n.transitLineUnavailable : b.line,
                        style: t.labelLarge,
                      ),
                      if (b.lineName != null && b.lineName != b.line)
                        Text(b.lineName!, style: t.bodySmall),
                      if (b.headsign != null)
                        Text(
                          l10n.transitTowards(b.headsign!),
                          style: t.bodySmall,
                        ),
                      const SizedBox(height: Space.xs),
                      Text(
                        '${b.departureStop ?? l10n.transitStopUnavailable} → ${b.arrivalStop ?? l10n.transitStopUnavailable}',
                        style: t.bodyMedium,
                      ),
                      if (b.departureTime != null || b.arrivalTime != null)
                        Text(
                          '${l10n.planRouteDeparture} ${time(b.departureTime)} · ${l10n.planRouteArrival} ${time(b.arrivalTime)}',
                          style: t.bodySmall,
                        ),
                      if (b.stopCount != null)
                        Text(
                          l10n.transitStops(b.stopCount!),
                          style: t.bodySmall,
                        ),
                      if (b.agency != null) Text(b.agency!, style: t.bodySmall),
                      if (b.serviceActive == false)
                        Text(
                          l10n.transitServiceInactive,
                          style: t.bodySmall!.copyWith(color: p.danger),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
