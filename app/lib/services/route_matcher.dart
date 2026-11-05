import 'dart:math' as math;

import '../models/models.dart';

/// Yo'l koridori bo'yidagi eventlarni topish (deterministik — AI emas).
/// docs/PLAN §3 "Route algoritmi" 1–3 qadamlar.
class RouteMatcher {
  const RouteMatcher({this.corridorKm = 15, this.sampleKm = 1.0});

  /// Yo'ldan maksimal uzoqlik.
  final double corridorKm;

  /// Polyline'ni shu oraliqda siyraklashtiramiz (2500 nuqta → ~400).
  final double sampleKm;

  /// [tripStart]..[tripEnd] oralig'ida bo'lgan va yo'ldan [corridorKm] ichidagi eventlar.
  /// Ball = qiziqish mosligi (60%) + yaqinlik (40%). Kamayish tartibida.
  List<RouteOpportunity> match({
    required List<GeoPoint> route,
    required List<RadarEvent> events,
    required Set<String> interests,
    required DateTime tripStart,
    required DateTime tripEnd,
    double Function(RadarEvent, Set<String>)? interestScore,
  }) {
    if (route.length < 2) return [];
    final samples = sample(route, sampleKm);
    final result = <RouteOpportunity>[];
    for (final e in events) {
      final overlaps = !e.end.isBefore(tripStart) && !e.start.isAfter(tripEnd);
      if (!overlaps) continue;
      final d = distanceToPolylineKm(e.location, samples);
      if (d > corridorKm) continue;
      final interest = (interestScore ?? _defaultInterest)(e, interests);
      final proximity = 1 - d / corridorKm;
      result.add(RouteOpportunity(
        event: e,
        distanceFromRouteKm: d,
        score: 0.6 * interest + 0.4 * proximity,
      ));
    }
    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }

  static double _defaultInterest(RadarEvent e, Set<String> interests) {
    if (e.tags.isEmpty) return 0;
    return e.tags.where(interests.contains).length / e.tags.length;
  }

  /// Har [stepKm] da bitta nuqta qoldiramiz (birinchi va oxirgi doim qoladi).
  static List<GeoPoint> sample(List<GeoPoint> pts, double stepKm) {
    if (pts.length <= 2) return pts;
    final out = <GeoPoint>[pts.first];
    var acc = 0.0;
    for (var i = 1; i < pts.length - 1; i++) {
      acc += haversineKm(pts[i - 1], pts[i]);
      if (acc >= stepKm) {
        out.add(pts[i]);
        acc = 0;
      }
    }
    out.add(pts.last);
    return out;
  }

  /// Polyline'dagi [p] ga eng yaqin nuqta (transit detour'i uchun: "shu bekatda tushing").
  /// Segment ichidagi proyeksiyani qaytaradi, shuning uchun siyrak KTX chizig'ida ham aniq.
  static GeoPoint nearestPointOnPolyline(GeoPoint p, List<GeoPoint> line) {
    if (line.length == 1) return line.first;
    var best = line.first;
    var bestD = double.infinity;
    for (var i = 0; i + 1 < line.length; i++) {
      final a = line[i], b = line[i + 1];
      final dx = b.lng - a.lng, dy = b.lat - a.lat;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : (((p.lng - a.lng) * dx + (p.lat - a.lat) * dy) / len2).clamp(0.0, 1.0);
      final c = GeoPoint(a.lat + t * dy, a.lng + t * dx);
      final d = haversineKm(p, c);
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    return best;
  }

  /// Nuqtadan polyline'gacha eng qisqa masofa (har bir segmentga proyeksiya).
  static double distanceToPolylineKm(GeoPoint p, List<GeoPoint> line) {
    var best = double.infinity;
    for (var i = 0; i + 1 < line.length; i++) {
      best = math.min(best, _distanceToSegmentKm(p, line[i], line[i + 1]));
    }
    return line.length == 1 ? haversineKm(p, line.first) : best;
  }

  /// Kichik masofalar uchun tekis (equirectangular) proyeksiya — Koreya uchun yetarli aniq.
  static double _distanceToSegmentKm(GeoPoint p, GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    final lat0 = _rad((a.lat + b.lat) / 2);
    double x(GeoPoint q) => _rad(q.lng) * math.cos(lat0) * r;
    double y(GeoPoint q) => _rad(q.lat) * r;
    final ax = x(a), ay = y(a), bx = x(b), by = y(b), px = x(p), py = y(p);
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    var t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    final cx = ax + t * dx, cy = ay + t * dy;
    return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
  }

  static double haversineKm(GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    final dLat = _rad(b.lat - a.lat), dLng = _rad(b.lng - a.lng);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
