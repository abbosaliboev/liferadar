import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/env.dart';
import '../models/models.dart';

/// Kakao Local (joy qidirish) va Kakao Mobility (avtomobil yo'nalishi).
/// ⚠️ Hozir client'dan chaqiriladi (CORS ochiq). Keyin Cloud Functions'ga ko'chadi.
class KakaoApi {
  KakaoApi({http.Client? client, String? restKey})
      : _client = client ?? http.Client(),
        _key = restKey ?? Env.kakaoRestApiKey;

  final http.Client _client;
  final String _key;

  Map<String, String> get _headers => {'Authorization': 'KakaoAK $_key'};

  /// Kalit so'z bo'yicha joy qidirish (masalan "부산역", "BEXCO").
  Future<List<Place>> searchPlaces(String query, {int size = 8}) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.https('dapi.kakao.com', '/v2/local/search/keyword.json', {
      'query': query.trim(),
      'size': '$size',
    });
    final json = await _get(uri);
    return [
      for (final d in json['documents'] as List)
        Place(
          name: d['place_name'] as String,
          address: ((d['road_address_name'] as String?)?.isNotEmpty ?? false)
              ? d['road_address_name'] as String
              : d['address_name'] as String,
          location: GeoPoint(double.parse(d['y'] as String), double.parse(d['x'] as String)),
        ),
    ];
  }

  /// A→B (ixtiyoriy oraliq nuqta bilan) avtomobil yo'nalishi.
  /// [withGeometry] false bo'lsa faqat masofa/vaqt (detour hisobi uchun, tezroq).
  Future<TravelRoute> directions(
    GeoPoint origin,
    GeoPoint destination, {
    GeoPoint? waypoint,
    bool withGeometry = true,
  }) async {
    String xy(GeoPoint p) => '${p.lng},${p.lat}';
    final uri = Uri.https('apis-navi.kakaomobility.com', '/v1/directions', {
      'origin': xy(origin),
      'destination': xy(destination),
      'waypoints': ?(waypoint == null ? null : xy(waypoint)),
      'summary': '${!withGeometry}',
    });
    final json = await _get(uri);
    final route = (json['routes'] as List).first as Map<String, dynamic>;
    if (route['result_code'] != 0) {
      throw KakaoApiException(route['result_msg'] as String? ?? 'route failed');
    }
    final summary = route['summary'] as Map<String, dynamic>;
    final points = <GeoPoint>[];
    if (withGeometry) {
      for (final section in route['sections'] as List) {
        for (final road in section['roads'] as List) {
          final v = (road['vertexes'] as List).cast<num>();
          for (var i = 0; i + 1 < v.length; i += 2) {
            points.add(GeoPoint(v[i + 1].toDouble(), v[i].toDouble()));
          }
        }
      }
    }
    return TravelRoute(
      distanceMeters: (summary['distance'] as num).toInt(),
      durationSeconds: (summary['duration'] as num).toInt(),
      points: points,
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    if (_key.isEmpty) throw const KakaoApiException('KAKAO_REST_API_KEY missing');
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw KakaoApiException('HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}

class KakaoApiException implements Exception {
  const KakaoApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
