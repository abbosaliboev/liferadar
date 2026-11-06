import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../data/providers.dart';
import '../../models/models.dart';

/// Berilgan joy va kun uchun ob-havo: "☀️ 15° / 7° · 구름 없음".
/// Kun 10 kunlik prognozdan tashqarida bo'lsa — "~10 kun oldin chiqadi".
/// Xato yoki kalit yo'q bo'lsa hech narsa ko'rsatmaydi (asosiy UI'ni buzmaydi).
class WeatherChip extends ConsumerWidget {
  const WeatherChip({super.key, required this.location, required this.date});

  final GeoPoint location;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall;
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final daysAhead = day.difference(DateTime(today.year, today.month, today.day)).inDays;
    if (daysAhead < 0) return const SizedBox.shrink();
    if (daysAhead > 9) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.schedule, size: 14, color: scheme.outline),
        const SizedBox(width: 4),
        Text(l10n.weatherLater, style: style?.copyWith(color: scheme.outline)),
      ]);
    }

    final forecast = ref.watch(forecastProvider(forecastKey(location, context.lang)));
    return forecast.when(
      loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
      error: (_, _) => const SizedBox.shrink(),
      data: (days) {
        final w = days.where((d) => d.date == day).firstOrNull;
        if (w == null) return const SizedBox.shrink();
        final rain = w.likelyRain;
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(weatherIcon(w.type), size: 16, color: rain ? Colors.blue : Colors.orange),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              [
                if (w.maxC != null && w.minC != null) '${w.maxC}° / ${w.minC}°',
                w.condition,
                if ((w.rainChance ?? 0) >= 30) '☔ ${w.rainChance}%',
              ].join(' · '),
              style: style?.copyWith(
                color: rain ? Colors.blue : null,
                fontWeight: rain ? FontWeight.w600 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]);
      },
    );
  }
}

IconData weatherIcon(String type) {
  if (type.contains('THUNDER')) return Icons.thunderstorm;
  if (type.contains('SNOW')) return Icons.ac_unit;
  if (type.contains('RAIN') || type.contains('SHOWER') || type.contains('DRIZZLE')) return Icons.umbrella;
  if (type.contains('FOG') || type.contains('HAZE')) return Icons.foggy;
  if (type.contains('WIND')) return Icons.air;
  if (type == 'CLEAR' || type.contains('SUNNY')) return Icons.wb_sunny;
  return Icons.cloud;
}
