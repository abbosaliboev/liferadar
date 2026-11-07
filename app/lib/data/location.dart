import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/models.dart';

enum LocationStatus { idle, asking, located, denied, unavailable }

class MyLocation {
  const MyLocation({this.status = LocationStatus.idle, this.position, this.accuracyM});
  final LocationStatus status;
  final GeoPoint? position;
  final double? accuracyM;
}

/// Foydalanuvchining joylashuvi (xarita uchun). Ruxsat birinchi marta xaritada so'raladi;
/// keyin joy o'zgarsa (≥ 20 m) yangilanadi. Joylashuv hech qayerga yuborilmaydi.
final myLocationProvider = NotifierProvider<MyLocationController, MyLocation>(MyLocationController.new);

class MyLocationController extends Notifier<MyLocation> {
  StreamSubscription<Position>? _sub;

  @override
  MyLocation build() {
    ref.onDispose(() => _sub?.cancel());
    return const MyLocation();
  }

  /// Ruxsat so'rab, kuzatishni boshlaydi. Natija: joy topildimi.
  Future<bool> start() async {
    if (state.status == LocationStatus.located) return true;
    state = const MyLocation(status: LocationStatus.asking);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = const MyLocation(status: LocationStatus.unavailable);
        return false;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        state = const MyLocation(status: LocationStatus.denied);
        return false;
      }
      final first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      _set(first);
      _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20),
      ).listen(_set, onError: (_) {});
      return true;
    } catch (e) {
      debugPrint('location: $e');
      state = const MyLocation(status: LocationStatus.unavailable);
      return false;
    }
  }

  void _set(Position p) => state = MyLocation(
        status: LocationStatus.located,
        position: GeoPoint(p.latitude, p.longitude),
        accuracyM: p.accuracy,
      );
}
