import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as km;

import '../../core/env.dart';
import '../../core/kakao_sdk_check.dart';
import '../../core/l10n_ext.dart';
import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../services/route_matcher.dart';
import '../event/event_detail_sheet.dart';
import '../route/route_controller.dart';
import '../route/route_panel.dart';
import '../shell/app_shell.dart';
import 'marker_icons.dart';

enum MapMode { explore, myMap, route }

enum MapLayer { plans, recommended, route }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _seoul = km.LatLng(37.5665, 126.9780);

  km.KakaoMapController? _map;
  String? _mapError;
  MapMode _mode = MapMode.explore;
  final Set<MapLayer> _layers = {MapLayer.plans, MapLayer.recommended};

  /// Har bir layer'dagi chizilgan Poi'lar (yashirish/ko'rsatish uchun).
  final Map<MapLayer, List<km.Poi>> _pois = {for (final l in MapLayer.values) l: []};

  /// Chizilgan yo'nalish chizig'i (Route layer).
  km.Route? _routeLine;

  /// Route opportunity Poi'si → opportunity (bosilganda detour ko'rsatish uchun).
  final Map<String, RouteOpportunity> _routeOppByEventId = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Home/Discover'dan "xaritada ko'rsatish" kelganda.
    ref.listen<String?>(mapFocusProvider, (_, id) {
      if (id != null) _focusEvent(id);
    });

    // Yangi yo'nalish yoki detour natijalari kelganda qayta chizamiz.
    // Kalendar sinxronidan keyin rejalar o'zgaradi.
    ref.listen<List<Plan>>(plansProvider, (_, next) {
      _drawing = _drawing.then((_) => _drawPlans(next)).catchError((_) {});
    });

    ref.listen<RouteState>(routeProvider, (prev, next) {
      if (prev?.route != next.route || prev?.opportunities != next.opportunities) {
        _drawRoute(next, fit: prev?.route != next.route);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMap), actions: const [LanguageButton()]),
      body: Stack(children: [
        Positioned.fill(child: _buildMap(context)),
        Positioned(
          left: 12,
          right: 12,
          top: 8,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SegmentedButton<MapMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                visualDensity: VisualDensity.compact,
              ),
              segments: [
                ButtonSegment(value: MapMode.explore, icon: const Icon(Icons.travel_explore), label: Text(l10n.modeExplore)),
                ButtonSegment(value: MapMode.myMap, icon: const Icon(Icons.person_pin_circle_outlined), label: Text(l10n.modeMyMap)),
                ButtonSegment(value: MapMode.route, icon: const Icon(Icons.alt_route), label: Text(l10n.modeRoute)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => _setMode(s.first),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              _layerChip(MapLayer.plans, l10n.layerPlans, AppColors.plan),
              _layerChip(MapLayer.recommended, l10n.layerRecommended, AppColors.recommended),
              _layerChip(MapLayer.route, l10n.layerRoute, AppColors.route),
            ]),
          ]),
        ),
        if (_mode == MapMode.route)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: RoutePanel(onOpportunityTap: _openOpportunity),
          ),
      ]),
    );
  }

  Widget _buildMap(BuildContext context) {
    final l10n = context.l10n;
    if (!Env.hasKakaoMapKey) return _MapMessage(l10n.mapKeyMissing);
    if (!isKakaoSdkLoaded()) return _MapMessage(l10n.mapSdkNotLoaded(Uri.base.origin));
    if (_mapError != null) return _MapMessage(l10n.mapError(_mapError!));
    return km.KakaoMap(
      option: const km.KakaoMapOption(position: _seoul, zoomLevel: 7),
      onMapReady: _onMapReady,
      onMapError: (e) => setState(() => _mapError = e.toString()),
    );
  }

  Widget _layerChip(MapLayer layer, String label, Color color) => FilterChip(
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
        label: Text(label),
        selected: _layers.contains(layer),
        backgroundColor: Theme.of(context).colorScheme.surface,
        onSelected: (on) => _setLayer(layer, on),
      );

  // ---------- Map logikasi ----------

  Future<void> _onMapReady(km.KakaoMapController controller) async {
    _map = controller;
    await _drawOverlays();
    await _fitAll();
    final pending = ref.read(mapFocusProvider);
    if (pending != null) await _focusEvent(pending);
  }

  Future<void> _drawOverlays() async {
    final map = _map;
    if (map == null) return;
    final events = ref.read(eventsProvider);

    await _drawPlans(ref.read(plansProvider));

    for (final e in events) {
      final icon = await MarkerIcons.pin(AppColors.recommended, categoryIcon(e.category));
      final poi = await map.labelLayer.addPoi(
        _ll(e.location),
        id: e.id,
        style: km.PoiStyle(icon: icon),
        visible: _layers.contains(MapLayer.recommended),
        onClick: () => _openEvent(e),
      );
      _pois[MapLayer.recommended]!.add(poi);
    }
  }

  /// "My Plans" markerlari — Google Calendar sinxronidan keyin qayta chiziladi.
  Future<void> _drawPlans(List<Plan> plans) async {
    final map = _map;
    if (map == null) return;
    for (final poi in _pois[MapLayer.plans]!) {
      await poi.remove();
    }
    _pois[MapLayer.plans]!.clear();
    final planIcon = await MarkerIcons.pin(AppColors.plan, Icons.event);
    for (final p in plans) {
      if (p.location == null) continue;
      _pois[MapLayer.plans]!.add(await map.labelLayer.addPoi(
        _ll(p.location!),
        style: km.PoiStyle(
          icon: planIcon,
          textStyle: const [km.PoiTextStyle(size: 12, color: Colors.black87, stroke: 2, strokeColor: Colors.white)],
        ),
        text: p.title,
        visible: _layers.contains(MapLayer.plans),
      ));
    }
  }

  Future<void> _setLayer(MapLayer layer, bool on) async {
    setState(() => on ? _layers.add(layer) : _layers.remove(layer));
    for (final poi in _pois[layer]!) {
      on ? await poi.show() : await poi.hide();
    }
    if (layer == MapLayer.route && _routeLine != null) {
      on ? await _routeLine!.show() : await _routeLine!.hide();
    }
  }

  // ---------- Route ----------

  /// Chizishlar ketma-ket bajarilsin (route + detour natijalari tez-tez keladi).
  Future<void> _drawing = Future.value();

  void _drawRoute(RouteState s, {required bool fit}) {
    _drawing = _drawing.then((_) => _doDrawRoute(s, fit: fit)).catchError((_) {});
  }

  Future<void> _doDrawRoute(RouteState s, {required bool fit}) async {
    final map = _map;
    if (map == null) return;

    // Eskisini tozalash
    if (_routeLine != null) {
      await map.routeLayer.removeRoute(_routeLine!);
      _routeLine = null;
    }
    for (final poi in _pois[MapLayer.route]!) {
      await poi.remove();
    }
    _pois[MapLayer.route]!.clear();
    _routeOppByEventId.clear();

    final route = s.route;
    if (route == null || route.points.length < 2) return;
    final visible = _layers.contains(MapLayer.route);

    // Yo'l chizig'i (siyraklashtirilgan — web'da tez chiziladi)
    final pts = RouteMatcher.sample(route.points, 0.3).map(_ll).toList();
    _routeLine = await map.routeLayer.addRoute(
      pts,
      km.RouteStyle(AppColors.route, 8, strokeColor: Colors.white, strokeWidth: 2),
    );
    if (!visible) await _routeLine!.hide();

    // Boshlanish / tugash
    final endIcon = await MarkerIcons.pin(AppColors.route, Icons.flag);
    final startIcon = await MarkerIcons.pin(AppColors.route, Icons.trip_origin);
    for (final (p, icon) in [(s.origin, startIcon), (s.destination, endIcon)]) {
      if (p == null) continue;
      _pois[MapLayer.route]!.add(await map.labelLayer.addPoi(
        _ll(p.location),
        style: km.PoiStyle(
          icon: icon,
          textStyle: const [km.PoiTextStyle(size: 13, color: Colors.black87, stroke: 2, strokeColor: Colors.white)],
        ),
        text: p.name,
        visible: visible,
      ));
    }

    // Yo'l bo'yidagi imkoniyatlar
    for (final o in s.opportunities) {
      final icon = await MarkerIcons.pin(AppColors.route, categoryIcon(o.event.category), selected: true);
      _routeOppByEventId[o.event.id] = o;
      _pois[MapLayer.route]!.add(await map.labelLayer.addPoi(
        _ll(o.event.location),
        id: 'route-${o.event.id}',
        style: km.PoiStyle(icon: icon),
        visible: visible,
        onClick: () => _openOpportunity(_routeOppByEventId[o.event.id] ?? o),
      ));
    }

    if (fit) {
      final step = (pts.length / 40).ceil().clamp(1, pts.length);
      await _fit([for (var i = 0; i < pts.length; i += step) pts[i], pts.last]);
    }
  }

  void _openOpportunity(RouteOpportunity o) {
    if (!mounted) return;
    _map?.moveCamera(
      km.CameraUpdate.newCenterPosition(_ll(o.event.location), zoomLevel: 12),
      animation: const km.CameraAnimation(600),
    );
    showEventDetail(context, o.event, opportunity: o);
  }

  Future<void> _setMode(MapMode mode) async {
    setState(() => _mode = mode);
    switch (mode) {
      case MapMode.explore:
        await _setLayer(MapLayer.route, false);
        await _setLayer(MapLayer.plans, true);
        await _setLayer(MapLayer.recommended, true);
        await _fitAll();
      case MapMode.myMap:
        await _setLayer(MapLayer.route, false);
        await _setLayer(MapLayer.plans, true);
        await _setLayer(MapLayer.recommended, false);
        final pts = ref.read(plansProvider).where((p) => p.location != null).map((p) => _ll(p.location!)).toList();
        await _fit(pts);
      case MapMode.route:
        // Chalkashmasligi uchun faqat yo'l va uning atrofidagi eventlar.
        await _setLayer(MapLayer.plans, false);
        await _setLayer(MapLayer.recommended, false);
        await _setLayer(MapLayer.route, true);
    }
  }

  Future<void> _fitAll() async {
    final pts = [
      ...ref.read(plansProvider).where((p) => p.location != null).map((p) => _ll(p.location!)),
      ...ref.read(eventsProvider).map((e) => _ll(e.location)),
    ];
    await _fit(pts);
  }

  Future<void> _fit(List<km.LatLng> pts) async {
    if (_map == null || pts.isEmpty) return;
    await _map!.moveCamera(
      pts.length == 1
          ? km.CameraUpdate.newCenterPosition(pts.first, zoomLevel: 14)
          : km.CameraUpdate.fitMapPoints(pts, padding: 120),
      animation: const km.CameraAnimation(600),
    );
  }

  Future<void> _focusEvent(String id) async {
    final event = ref.read(eventByIdProvider(id));
    if (event == null || _map == null) return;
    ref.read(mapFocusProvider.notifier).focus(null);
    if (!_layers.contains(MapLayer.recommended)) await _setLayer(MapLayer.recommended, true);
    await _map!.moveCamera(
      km.CameraUpdate.newCenterPosition(_ll(event.location), zoomLevel: 14),
      animation: const km.CameraAnimation(800),
    );
    if (mounted) _openEvent(event);
  }

  void _openEvent(RadarEvent e) {
    if (!mounted) return;
    showEventDetail(context, e);
  }

  km.LatLng _ll(GeoPoint p) => km.LatLng(p.lat, p.lng);
}

class _MapMessage extends StatelessWidget {
  const _MapMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.map_outlined, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}
