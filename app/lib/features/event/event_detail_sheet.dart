import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/calendar_controller.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../shell/app_shell.dart';
import '../weather/weather_chip.dart';

Future<void> showEventDetail(
  BuildContext context,
  RadarEvent event, {
  VoidCallback? onShowOnMap,
  RouteOpportunity? opportunity,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => EventDetailSheet(event: event, onShowOnMap: onShowOnMap, opportunity: opportunity),
  );
}

class EventDetailSheet extends ConsumerStatefulWidget {
  const EventDetailSheet({super.key, required this.event, this.onShowOnMap, this.opportunity});

  final RadarEvent event;
  final VoidCallback? onShowOnMap;

  /// Route rejimidan ochilganda: yo'ldan uzoqlik va qo'shimcha yo'l.
  final RouteOpportunity? opportunity;

  @override
  ConsumerState<EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends ConsumerState<EventDetailSheet> {
  bool _adding = false;

  RadarEvent get event => widget.event;

  /// Google Calendar'ga qo'shish. Ulanmagan bo'lsa Google ruxsat oynasi ochiladi.
  Future<void> _addToCalendar() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final title = context.tr(event.title);
    setState(() => _adding = true);
    try {
      final link = await ref.read(calendarProvider.notifier).addEvent(event, title: title);
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.addedToCalendar),
        action: link == null
            ? null
            : SnackBarAction(
                label: l10n.openSource,
                onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
              ),
      ));
    } catch (e) {
      final msg = e.toString().contains('not-configured') ? l10n.calendarNotConfigured : l10n.calendarError('$e');
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final t = context.textStyles;
    final interests = ref.watch(interestsProvider);
    final matched = event.tags.where(interests.contains).toList();
    final o = widget.opportunity;

    final addButton = FilledButton.icon(
      onPressed: _adding ? null : _addToCalendar,
      icon: _adding
          ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p.textMuted))
          : const Icon(Icons.event_available_outlined),
      label: Text(_adding ? l10n.addingToCalendar : l10n.addToCalendar),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(children: [
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
            children: [
              Row(children: [
                IconTile(categoryIcon(event.category), size: 44),
                const SizedBox(width: Space.md),
                Pill(context.categoryLabel(event.category)),
                const Spacer(),
                if (event.isSample) const SampleBadge(),
              ]),
              const SizedBox(height: Space.md),
              Text(context.tr(event.title), style: t.headlineSmall),
              const SizedBox(height: Space.lg),

              // ── Asosiy ma'lumotlar ──
              Container(
                padding: const EdgeInsets.all(Space.lg),
                decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(Radii.lg)),
                child: Column(children: [
                  _Info(Icons.schedule_outlined,
                      '${context.formatDateTime(event.start)} – ${context.formatDateTime(event.end)}'),
                  _Info(Icons.place_outlined, '${event.venue} · ${event.city}'),
                  if (event.deadline != null)
                    _Info(Icons.hourglass_bottom_rounded, '${l10n.kindDeadline} · ${context.formatDate(event.deadline!)}',
                        color: p.accent),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    child: Row(children: [
                      const SizedBox(width: 26),
                      Expanded(child: WeatherChip(location: event.location, date: event.start)),
                    ]),
                  ),
                  if (o != null)
                    _Info(
                      Icons.alt_route_rounded,
                      '${l10n.onYourWay} · ${o.detourKm != null ? l10n.routeDetour(o.detourKm!.toStringAsFixed(1), o.detourMinutes!) : l10n.routeFromRoute(o.distanceFromRouteKm.toStringAsFixed(1))}',
                      color: p.primary,
                    ),
                ]),
              ),
              const SizedBox(height: Space.lg),
              Text(context.tr(event.description), style: t.bodyLarge),

              if (matched.isNotEmpty) ...[
                const SizedBox(height: Space.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.whyForYou, style: t.labelMedium!.copyWith(color: p.primary)),
                    const SizedBox(height: Space.xs),
                    Text(l10n.matchesInterests(matched.map((x) => '#$x').join(' ')), style: t.bodyMedium),
                  ]),
                ),
              ],
            ],
          ),
        ),

        // ── Harakatlar (doim ko'rinadi) ──
        DecoratedBox(
          decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.border))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
              child: Row(children: [
                if (widget.onShowOnMap != null) ...[
                  SizedBox(
                    width: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onShowOnMap!();
                      },
                      child: Tooltip(message: l10n.showOnMap, child: const Icon(Icons.map_outlined)),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                ],
                if (event.registerUrl != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => launchUrl(Uri.parse(event.registerUrl!), mode: LaunchMode.externalApplication),
                      child: Text(l10n.register),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(flex: 2, child: addButton),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExcludeSemantics(child: Icon(icon, size: 18, color: color ?? p.textMuted)),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(
            text,
            style: context.textStyles.bodyMedium!.copyWith(
              color: color ?? p.text,
              fontWeight: color != null ? FontWeight.w600 : null,
            ),
          ),
        ),
      ]),
    );
  }
}
