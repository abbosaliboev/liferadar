import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import 'route_controller.dart';

/// Map'ning Route rejimidagi pastki panel: qayerdan / qayerga / sana → natijalar.
class RoutePanel extends ConsumerStatefulWidget {
  const RoutePanel({super.key, required this.onOpportunityTap});

  final void Function(RouteOpportunity) onOpportunityTap;

  @override
  ConsumerState<RoutePanel> createState() => _RoutePanelState();
}

class _RoutePanelState extends ConsumerState<RoutePanel> {
  /// Natija chiqqanda xaritani ko'rish uchun panelni yig'ish mumkin.
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(routeProvider);
    final c = ref.read(routeProvider.notifier);
    final text = Theme.of(context).textTheme;
    final summary = s.route == null || s.status == RouteStatus.error ? null : _summary(context, s.route!);

    if (_collapsed && summary != null) {
      return Card(
        elevation: 3,
        color: Theme.of(context).colorScheme.surface,
        child: ListTile(
          leading: const Icon(Icons.alt_route, color: AppColors.route),
          title: Text(summary, style: text.titleSmall),
          subtitle: Text(l10n.routeAlongTheWay(s.opportunities.length)),
          trailing: const Icon(Icons.expand_less),
          onTap: () => setState(() => _collapsed = false),
        ),
      );
    }

    return Card(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.48),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          children: [
            SegmentedButton<TravelMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: TravelMode.transit, icon: const Icon(Icons.train), label: Text(l10n.travelTransit)),
                ButtonSegment(value: TravelMode.car, icon: const Icon(Icons.directions_car), label: Text(l10n.travelCar)),
              ],
              selected: {s.mode},
              onSelectionChanged: (v) => c.setMode(v.first),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Column(children: [
                  _PlaceField(
                    icon: Icons.trip_origin,
                    label: l10n.routeFrom,
                    place: s.origin,
                    onPicked: c.setOrigin,
                  ),
                  const SizedBox(height: 6),
                  _PlaceField(
                    icon: Icons.place,
                    label: l10n.routeTo,
                    place: s.destination,
                    onPicked: c.setDestination,
                  ),
                ]),
              ),
              IconButton(onPressed: c.swap, icon: const Icon(Icons.swap_vert)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text(context.formatDate(s.date)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: s.date,
                    firstDate: DateTime(2026, 1, 1),
                    lastDate: DateTime(2027, 12, 31),
                  );
                  if (picked != null) c.setDate(picked);
                },
              ),
              TextButton(onPressed: c.useDemo, child: Text(l10n.routeDemo)),
            ]),
            const SizedBox(height: 4),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.route),
              onPressed: s.canSearch ? c.search : null,
              icon: s.status == RouteStatus.loading
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.alt_route),
              label: Text(l10n.routeFind),
            ),
            if (s.status == RouteStatus.error) ...[
              const SizedBox(height: 8),
              Text(l10n.routeError(s.error ?? ''), style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (s.route != null && s.status != RouteStatus.error) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text(summary!, style: text.titleSmall)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.expand_more),
                  onPressed: () => setState(() => _collapsed = true),
                ),
              ]),
              const Divider(),
              Text(l10n.routeAlongTheWay(s.opportunities.length), style: text.labelLarge),
              if (s.opportunities.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.routeNoOpportunities)),
              for (final o in s.opportunities) _OpportunityTile(o, onTap: () => widget.onOpportunityTap(o)),
            ],
          ],
        ),
      ),
    );
  }
}

String _summary(BuildContext context, TravelRoute r) {
  final l10n = context.l10n;
  final km = (r.distanceMeters / 1000).toStringAsFixed(1);
  final dur = _duration(context, r.durationSeconds);
  return r.mode == TravelMode.transit
      ? l10n.routeSummaryTransit(km, dur, r.transitLines.isEmpty ? l10n.travelTransit : r.transitLines.join(' → '))
      : l10n.routeSummary(km, dur);
}

String _duration(BuildContext context, int seconds) {
  final m = (seconds / 60).round();
  return context.l10n.hoursMinutes(m ~/ 60, m % 60);
}

class _OpportunityTile extends StatelessWidget {
  const _OpportunityTile(this.o, {required this.onTap});
  final RouteOpportunity o;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detour = o.detourKm == null
        ? null
        : l10n.routeDetour(o.detourKm!.toStringAsFixed(1), o.detourMinutes!);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.route,
        foregroundColor: Colors.white,
        child: Icon(categoryIcon(o.event.category), size: 18),
      ),
      title: Text(context.tr(o.event.title), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        '${context.formatDateTime(o.event.start)} · ${o.event.city}',
        detour ?? l10n.routeFromRoute(o.distanceFromRouteKm.toStringAsFixed(1)),
      ].join('\n')),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _PlaceField extends ConsumerWidget {
  const _PlaceField({required this.icon, required this.label, required this.place, required this.onPicked});

  final IconData icon;
  final String label;
  final Place? place;
  final void Function(Place) onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showModalBottomSheet<Place>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => const PlaceSearchSheet(),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(place?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Kakao Local qidiruvi (debounce bilan).
class PlaceSearchSheet extends ConsumerStatefulWidget {
  const PlaceSearchSheet({super.key});

  @override
  ConsumerState<PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends ConsumerState<PlaceSearchSheet> {
  Timer? _debounce;
  List<Place> _results = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _query = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(kakaoApiProvider).searchPlaces(q);
      if (!mounted || q != _query) return;
      setState(() => _results = r);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              onChanged: _onChanged,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: l10n.routeSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
          if (!_loading && _error == null && _query.isNotEmpty && _results.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(l10n.routeNoResults)),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final p = _results[i];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(p.name),
                  subtitle: Text(p.address),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
