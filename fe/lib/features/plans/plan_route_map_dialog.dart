import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as km;
import 'package:liferadar_core/liferadar_core.dart';

import '../../core/env.dart';
import '../../core/kakao_sdk_check.dart';
import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../data/transit_journey.dart';
import '../map/marker_icons.dart';

const _segmentColors = [
  Color(0xFF6851A5),
  Color(0xFF1976D2),
  Color(0xFFE07816),
  Color(0xFF008577),
];

Future<List<TransitBoarding>?> showPlanRouteMap(
  BuildContext context, {
  required TravelRoute route,
  required String originName,
  required String destinationName,
  required GeoPoint origin,
  required GeoPoint destination,
  required DateTime departure,
  required List<TransitBoarding> boardings,
}) => showDialog<List<TransitBoarding>>(
  context: context,
  useRootNavigator: true,
  builder: (_) => PlanRouteMapDialog(
    route: route,
    originName: originName,
    destinationName: destinationName,
    origin: origin,
    destination: destination,
    departure: departure,
    boardings: boardings,
  ),
);

class PlanRouteMapDialog extends ConsumerStatefulWidget {
  const PlanRouteMapDialog({
    super.key,
    required this.route,
    required this.originName,
    required this.destinationName,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.boardings,
  });
  final TravelRoute route;
  final String originName, destinationName;
  final GeoPoint origin, destination;
  final DateTime departure;
  final List<TransitBoarding> boardings;
  @override
  ConsumerState<PlanRouteMapDialog> createState() => _PlanRouteMapDialogState();
}

class _PlanRouteMapDialogState extends ConsumerState<PlanRouteMapDialog> {
  Timer? _timeout;
  bool _ready = false, _failed = false, _loadingGeometry = false;
  int _generation = 0;
  int? _selected;
  km.KakaoMapController? _map;
  late List<TransitBoarding> _boardings = widget.boardings;
  final _lines = <km.Route>[];
  final _markers = <km.Poi>[];
  Future<void> _drawing = Future.value();
  km.LatLng _ll(GeoPoint p) => km.LatLng(p.lat, p.lng);
  Color _color(int index) => _segmentColors[index % _segmentColors.length];

  @override
  void initState() {
    super.initState();
    _startTimeout();
    if (_boardings.any((b) => !b.mapGeometryLoaded)) {
      unawaited(_refreshLegacyGeometry());
    }
  }

  Future<void> _refreshLegacyGeometry() async {
    _loadingGeometry = true;
    try {
      final api = ref.read(googleApiProvider);
      final choices =
          await (widget.boardings.firstOrNull?.provider == 'kakao'
                  ? ref
                        .read(kakaoTransitApiProvider)
                        .transitJourneys(widget.origin, widget.destination)
                  : widget.boardings.firstOrNull?.provider == 'tmap'
                  ? api.transitJourneys(
                      widget.origin,
                      widget.destination,
                      departure: widget.departure,
                    )
                  : api.googleTransitJourneys(
                      widget.origin,
                      widget.destination,
                      departure: widget.departure,
                    ))
              .timeout(const Duration(seconds: 40));
      if (!mounted) return;
      final exact = choices
          .where((j) => sameTransitBoardings(widget.boardings, j.boardings))
          .firstOrNull;
      if (exact != null) _boardings = exact.boardings;
    } catch (_) {
      // Keep the saved service and its stops. Never swap in a different trip.
    } finally {
      if (mounted) {
        setState(() => _loadingGeometry = false);
        _redraw();
      }
    }
  }

  void _startTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 25), () {
      if (mounted && !_ready) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  List<GeoPoint> get _visiblePoints {
    final index = _selected;
    if (index != null) {
      final b = _boardings[index];
      return [
        if (b.departureLocation != null) b.departureLocation!,
        if (b.hasDetailedMapGeometry) ...b.mapPoints,
        if (b.arrivalLocation != null) b.arrivalLocation!,
      ];
    }
    return [
      widget.origin,
      widget.destination,
      for (final b in _boardings) ...[
        if (b.departureLocation != null) b.departureLocation!,
        if (b.hasDetailedMapGeometry) ...b.mapPoints,
        if (b.arrivalLocation != null) b.arrivalLocation!,
      ],
    ];
  }

  Future<void> _fit() async {
    final points = _visiblePoints;
    if (_map == null || points.isEmpty) return;
    final step = (points.length / 60).ceil().clamp(1, points.length);
    await _map!.moveCamera(
      km.CameraUpdate.fitMapPoints([
        for (var i = 0; i < points.length; i += step) _ll(points[i]),
        _ll(points.last),
      ], padding: 50),
    );
  }

  void _redraw() {
    // Update native overlays after Flutter has committed the selected row.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _drawing = _drawing.then((_) => _draw()).catchError((Object _) {
        if (mounted) setState(() => _failed = true);
      });
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _draw() async {
    final map = _map;
    if (!mounted || map == null) return;
    for (final line in _lines) {
      await map.routeLayer.removeRoute(line);
    }
    for (final marker in _markers) {
      await marker.remove();
    }
    _lines.clear();
    _markers.clear();
    final selected = _selected;
    for (var i = 0; i < _boardings.length; i++) {
      final b = _boardings[i];
      if (!b.hasDetailedMapGeometry || (selected != null && selected != i)) {
        continue;
      }
      if (!mounted) return;
      // Use each boarding's actual shape independently. Do not connect gaps,
      // infer a bus route from a car route, or draw endpoint-only polylines.
      _lines.add(
        await map.routeLayer.addRoute(
          b.mapPoints.map(_ll).toList(),
          km.RouteStyle(
            _color(i),
            5,
            strokeColor: Colors.white,
            strokeWidth: 1.5,
          ),
        ),
      );
    }
    Future<void> marker(GeoPoint? p, String label, Color color) async {
      if (!mounted || p == null) return;
      final icon = await MarkerIcons.badge(color, label);
      if (!mounted) return;
      _markers.add(
        await map.labelLayer.addPoi(
          _ll(p),
          style: km.PoiStyle(icon: icon, anchor: const km.KPoint(0.5, 0.5)),
        ),
      );
    }

    if (selected == null) {
      await marker(widget.origin, 'A', Colors.green.shade700);
      await marker(widget.destination, 'B', Colors.red.shade700);
    } else {
      final b = _boardings[selected];
      await marker(b.departureLocation, 'A', _color(selected));
      await marker(b.arrivalLocation, 'B', _color(selected));
    }
    if (!mounted) return;
    await _fit();
    if (!mounted) return;
    _timeout?.cancel();
    setState(() => _ready = true);
  }

  void _select(int? index) {
    setState(() => _selected = index);
    _redraw();
  }

  Widget _mapView() {
    final l10n = context.l10n;
    final message = !Env.hasKakaoMapKey
        ? l10n.mapKeyMissing
        : !isKakaoSdkLoaded()
        ? l10n.mapSdkNotLoaded(Uri.base.origin)
        : _failed
        ? l10n.transitMapError
        : null;
    if (message != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 32),
              Text(message, textAlign: TextAlign.center),
              if (_failed)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _failed = false;
                      _ready = false;
                      _map = null;
                      _lines.clear();
                      _markers.clear();
                      _generation++;
                    });
                    _startTimeout();
                  },
                  child: Text(l10n.retry),
                ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        km.KakaoMap(
          key: ValueKey(_generation),
          forceHybridComposition: true,
          option: km.KakaoMapOption(
            position: _ll(widget.origin),
            zoomLevel: 10,
          ),
          onMapReady: (map) {
            if (mounted) {
              _map = map;
              _redraw();
            }
          },
          onMapError: (_) {
            if (mounted) setState(() => _failed = true);
          },
        ),
        if (!_ready) const Center(child: CircularProgressIndicator()),
        if (_loadingGeometry)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
        if (_ready)
          Positioned(
            top: Space.sm,
            right: Space.sm,
            child: IconButton.filledTonal(
              onPressed: () => _select(null),
              tooltip: l10n.transitMapFit,
              icon: const Icon(Icons.fit_screen_rounded),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n, t = context.textStyles, p = context.palette;
    final minutes = (widget.route.durationSeconds / 60).ceil();
    final selected = _selected == null ? null : _boardings[_selected!];
    final missing = _boardings.any((b) => !b.hasDetailedMapGeometry);
    return Dialog(
      insetPadding: const EdgeInsets.all(Space.md),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 600,
        height: MediaQuery.sizeOf(context).height * 0.83,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.xs,
                Space.sm,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.transitMapTitle, style: t.titleMedium),
                  ),
                  Text(
                    l10n.hoursMinutes(minutes ~/ 60, minutes % 60),
                    style: t.bodySmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, _boardings),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                0,
                Space.md,
                Space.sm,
              ),
              child: Text(
                selected == null
                    ? 'A ${widget.originName} → B ${widget.destinationName}'
                    : 'A ${selected.departureStop ?? l10n.transitStopUnavailable} → B ${selected.arrivalStop ?? l10n.transitStopUnavailable}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall,
              ),
            ),
            Expanded(
              child: SizedBox.expand(
                key: const ValueKey('transit-map-viewport'),
                child: _mapView(),
              ),
            ),
            // Resizing a live Android GL SurfaceView during a section switch
            // can leave the map and Flutter composition showing a stale frame.
            // Keep this slot allocated during selection and geometry refresh.
            SizedBox(
              height:
                  MediaQuery.textScalerOf(
                        context,
                      ).scale(t.bodySmall?.fontSize ?? 12) *
                      3 +
                  Space.sm,
              child: missing && !_loadingGeometry
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Space.md,
                        Space.sm,
                        Space.md,
                        0,
                      ),
                      child: Text(
                        l10n.transitMapGeometryNotice,
                        style: t.bodySmall!.copyWith(color: p.primary),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.sm,
                Space.md,
                Space.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.transitMapTapSegment, style: t.labelSmall),
                  ),
                  TextButton(
                    onPressed: () => _select(null),
                    child: Text(l10n.transitMapOverview),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                itemCount: _boardings.length,
                itemBuilder: (context, i) {
                  final b = _boardings[i];
                  return ListTile(
                    key: ValueKey('transit-map-segment-$i'),
                    dense: true,
                    selected: _selected == i,
                    selectedTileColor: _color(i).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: CircleAvatar(
                      radius: 13,
                      backgroundColor: _color(i),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      b.line.isEmpty ? l10n.transitLineUnavailable : b.line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelLarge,
                    ),
                    subtitle: Text(
                      '${b.departureStop ?? l10n.transitStopUnavailable} → ${b.arrivalStop ?? l10n.transitStopUnavailable}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall,
                    ),
                    trailing: Icon(
                      b.hasDetailedMapGeometry
                          ? Icons.zoom_in_rounded
                          : Icons.location_on_outlined,
                      color: _color(i),
                      size: 20,
                    ),
                    onTap: () => _select(i),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                Space.xs,
                Space.md,
                Space.sm,
              ),
              child: Text(
                context.transitSourceFor(
                  _boardings.firstOrNull?.provider ?? 'google',
                ),
                style: t.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
