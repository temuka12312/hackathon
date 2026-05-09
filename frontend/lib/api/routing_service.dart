import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  const RoutingService._();

  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1';
  static const String _orsBaseUrl = String.fromEnvironment(
    'ORS_BASE_URL',
    defaultValue: 'https://api.openrouteservice.org/v2/directions',
  );
  static const String _orsApiKey = String.fromEnvironment('ORS_API_KEY');

  static Future<List<RoutePath>> fetchRoutes({
    required LatLng start,
    required LatLng end,
    required String profile,
  }) async {
    if (_orsApiKey.isNotEmpty) {
      return _fetchOrsRoutes(start: start, end: end, profile: profile);
    }

    return _fetchOsrmRoutes(start: start, end: end, profile: profile);
  }

  static Future<List<RoutePath>> _fetchOsrmRoutes({
    required LatLng start,
    required LatLng end,
    required String profile,
  }) async {
    final osrmProfile = switch (profile) {
      'driving-car' => 'driving',
      'foot-walking' => 'foot',
      'wheelchair' => 'foot',
      _ => profile,
    };
    final coordinates =
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

    final uri = Uri.parse('$_osrmBaseUrl/$osrmProfile/$coordinates').replace(
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
        'alternatives': 'true',
        'steps': 'false',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Routing service returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['code'] != 'Ok') {
      throw Exception(json['code'] as String? ?? 'No route');
    }

    final routes = json['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw Exception('No route found');
    }

    final parsedRoutes = routes.map(_parseOsrmRoute).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return parsedRoutes;
  }

  static Future<List<RoutePath>> _fetchOrsRoutes({
    required LatLng start,
    required LatLng end,
    required String profile,
  }) async {
    final uri = Uri.parse('$_orsBaseUrl/$profile/geojson');
    final options = _orsOptionsFor(profile);
    final body = <String, dynamic>{
      'coordinates': [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ],
      'instructions': false,
      'elevation': false,
      'extra_info': ['waytype', 'surface', 'roadaccessrestrictions'],
      ...?options == null ? null : {'options': options},
    };

    final response = await http.post(
      uri,
      headers: {
        'Authorization': _orsApiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/geo+json, application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Routing service returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>? ?? const [];
    if (features.isEmpty) {
      throw Exception('No route found');
    }

    final parsedRoutes = features.map(_parseOrsFeature).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return parsedRoutes;
  }

  static RoutePath _parseOsrmRoute(dynamic route) {
    final routeJson = route as Map<String, dynamic>;
    final geometry = routeJson['geometry'] as Map<String, dynamic>? ?? const {};
    final coordinatesJson =
        geometry['coordinates'] as List<dynamic>? ?? const [];

    final points = coordinatesJson.map(_parseCoordinate).toList();

    return RoutePath(
      points: points,
      distanceMeters: (routeJson['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (routeJson['duration'] as num?)?.toDouble() ?? 0,
    );
  }

  static RoutePath _parseOrsFeature(dynamic feature) {
    final featureJson = feature as Map<String, dynamic>;
    final geometry =
        featureJson['geometry'] as Map<String, dynamic>? ?? const {};
    final coordinatesJson =
        geometry['coordinates'] as List<dynamic>? ?? const [];
    final properties =
        featureJson['properties'] as Map<String, dynamic>? ?? const {};
    final summary = properties['summary'] as Map<String, dynamic>? ?? const {};

    final points = coordinatesJson.map(_parseCoordinate).toList();

    return RoutePath(
      points: points,
      distanceMeters: (summary['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (summary['duration'] as num?)?.toDouble() ?? 0,
    );
  }

  static LatLng _parseCoordinate(dynamic point) {
    final values = point as List<dynamic>;
    return LatLng((values[1] as num).toDouble(), (values[0] as num).toDouble());
  }

  static Map<String, dynamic>? _orsOptionsFor(String profile) {
    switch (profile) {
      case 'wheelchair':
        return {
          'avoid_features': ['steps', 'ferries'],
          'profile_params': {
            'restrictions': {
              'surface_type': 'paved',
              'track_type': 'grade1',
              'smoothness_type': 'good',
              'maximum_sloped_kerb': 0.06,
              'maximum_incline': 6,
            },
          },
        };
      case 'foot-walking':
        return {
          'avoid_features': ['ferries'],
        };
      case 'driving-car':
        return {
          'avoid_features': ['ferries'],
        };
      default:
        return null;
    }
  }
}

class RoutePath {
  const RoutePath({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}
