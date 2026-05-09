import 'dart:convert';
import 'dart:math' as math;

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
    if (profile == 'driving-shortest') {
      return _fetchNeighborhoodShortcutRoutes(start: start, end: end);
    }

    if (_orsApiKey.isNotEmpty) {
      return _fetchOrsRoutes(start: start, end: end, profile: profile);
    }

    return _fetchOsrmRoutes(start: start, end: end, profile: profile);
  }

  static Future<List<RoutePath>> _fetchNeighborhoodShortcutRoutes({
    required LatLng start,
    required LatLng end,
  }) async {
    final baseRoutes = _orsApiKey.isNotEmpty
        ? await _fetchOrsRoutes(
            start: start,
            end: end,
            profile: 'driving-shortest',
          )
        : await _fetchOsrmRoutes(
            start: start,
            end: end,
            profile: 'driving-shortest',
          );

    final candidates = <RoutePath>[...baseRoutes];
    final viaPoints = _buildNeighborhoodViaPoints(start, end);

    for (final via in viaPoints) {
      try {
        final firstLeg = _orsApiKey.isNotEmpty
            ? await _fetchOrsRoutes(
                start: start,
                end: via,
                profile: 'driving-shortest',
              )
            : await _fetchOsrmRoutes(
                start: start,
                end: via,
                profile: 'driving-shortest',
              );
        final secondLeg = _orsApiKey.isNotEmpty
            ? await _fetchOrsRoutes(
                start: via,
                end: end,
                profile: 'driving-shortest',
              )
            : await _fetchOsrmRoutes(
                start: via,
                end: end,
                profile: 'driving-shortest',
              );

        if (firstLeg.isEmpty || secondLeg.isEmpty) {
          continue;
        }

        candidates.add(_mergeRoutePaths(firstLeg.first, secondLeg.first));
      } catch (_) {
        continue;
      }
    }

    if (_orsApiKey.isNotEmpty) {
      candidates.sort(
        (a, b) => _neighborhoodScore(b).compareTo(_neighborhoodScore(a)),
      );
    } else {
      candidates.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    }
    return candidates;
  }

  static Future<List<RoutePath>> _fetchOsrmRoutes({
    required LatLng start,
    required LatLng end,
    required String profile,
  }) async {
    final osrmProfile = switch (profile) {
      'driving-car' => 'driving',
      'driving-shortest' => 'driving',
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

    final parsedRoutes = routes.map(_parseOsrmRoute).toList();
    _sortRoutesForProfile(parsedRoutes, profile);

    return parsedRoutes;
  }

  static Future<List<RoutePath>> _fetchOrsRoutes({
    required LatLng start,
    required LatLng end,
    required String profile,
  }) async {
    final orsProfile = switch (profile) {
      'driving-shortest' => 'driving-car',
      _ => profile,
    };
    final uri = Uri.parse('$_orsBaseUrl/$orsProfile/geojson');
    final options = _orsOptionsFor(profile);
    final body = <String, dynamic>{
      'coordinates': [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ],
      'preference': _orsPreferenceFor(profile),
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

    final parsedRoutes = features.map(_parseOrsFeature).toList();
    _sortRoutesForProfile(parsedRoutes, profile);

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
    final extras = properties['extras'] as Map<String, dynamic>? ?? const {};

    final points = coordinatesJson.map(_parseCoordinate).toList();

    return RoutePath(
      points: points,
      distanceMeters: (summary['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (summary['duration'] as num?)?.toDouble() ?? 0,
      neighborhoodShare: _orsWayTypeShare(extras, 3),
      arterialShare: _orsWayTypeShare(extras, 1) + _orsWayTypeShare(extras, 2),
    );
  }

  static LatLng _parseCoordinate(dynamic point) {
    final values = point as List<dynamic>;
    return LatLng((values[1] as num).toDouble(), (values[0] as num).toDouble());
  }

  static List<LatLng> _buildNeighborhoodViaPoints(LatLng start, LatLng end) {
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final deltaLat = end.latitude - start.latitude;
    final deltaLng = end.longitude - start.longitude;
    final length = _safeHypot(deltaLat, deltaLng);

    if (length == 0) {
      return const [];
    }

    final perpendicularLat = -deltaLng / length;
    final perpendicularLng = deltaLat / length;
    final offset = (length * 0.22).clamp(0.0012, 0.0042);

    return [
      LatLng(
        midLat + perpendicularLat * offset,
        midLng + perpendicularLng * offset,
      ),
      LatLng(
        midLat - perpendicularLat * offset,
        midLng - perpendicularLng * offset,
      ),
      LatLng(
        midLat + perpendicularLat * (offset * 0.55),
        midLng + perpendicularLng * (offset * 0.55),
      ),
      LatLng(
        midLat - perpendicularLat * (offset * 0.55),
        midLng - perpendicularLng * (offset * 0.55),
      ),
      LatLng(
        start.latitude + (deltaLat * 0.30) + perpendicularLat * offset,
        start.longitude + (deltaLng * 0.30) + perpendicularLng * offset,
      ),
      LatLng(
        start.latitude + (deltaLat * 0.30) - perpendicularLat * offset,
        start.longitude + (deltaLng * 0.30) - perpendicularLng * offset,
      ),
      LatLng(
        start.latitude + (deltaLat * 0.68) + perpendicularLat * offset,
        start.longitude + (deltaLng * 0.68) + perpendicularLng * offset,
      ),
      LatLng(
        start.latitude + (deltaLat * 0.68) - perpendicularLat * offset,
        start.longitude + (deltaLng * 0.68) - perpendicularLng * offset,
      ),
    ];
  }

  static RoutePath _mergeRoutePaths(RoutePath first, RoutePath second) {
    final mergedPoints = [...first.points, ...second.points.skip(1)];

    return RoutePath(
      points: mergedPoints,
      distanceMeters: first.distanceMeters + second.distanceMeters,
      durationSeconds: first.durationSeconds + second.durationSeconds,
      neighborhoodShare:
          ((first.neighborhoodShare * first.distanceMeters) +
              (second.neighborhoodShare * second.distanceMeters)) /
          (first.distanceMeters + second.distanceMeters),
      arterialShare:
          ((first.arterialShare * first.distanceMeters) +
              (second.arterialShare * second.distanceMeters)) /
          (first.distanceMeters + second.distanceMeters),
    );
  }

  static double _safeHypot(double a, double b) {
    return math.sqrt((a * a) + (b * b));
  }

  static double _orsWayTypeShare(Map<String, dynamic> extras, int targetValue) {
    final waytype = extras['waytype'] as Map<String, dynamic>? ?? const {};
    final summary = waytype['summary'] as List<dynamic>? ?? const [];
    double matchedDistance = 0;
    double totalDistance = 0;

    for (final entry in summary) {
      final json = entry as Map<String, dynamic>? ?? const {};
      final value = (json['value'] as num?)?.toInt();
      final distance = (json['distance'] as num?)?.toDouble() ?? 0;
      totalDistance += distance;
      if (value == targetValue) {
        matchedDistance += distance;
      }
    }

    if (totalDistance == 0) {
      return 0;
    }

    return matchedDistance / totalDistance;
  }

  static double _neighborhoodScore(RoutePath route) {
    final neighborhoodBias = route.neighborhoodShare * 1000;
    final arterialPenalty = route.arterialShare * 600;
    final distancePenalty = route.distanceMeters * 0.08;
    final durationPenalty = route.durationSeconds * 0.015;
    return neighborhoodBias -
        arterialPenalty -
        distancePenalty -
        durationPenalty;
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
      case 'driving-shortest':
        return {
          'avoid_features': ['highways', 'tollways', 'ferries'],
        };
      default:
        return null;
    }
  }

  static String _orsPreferenceFor(String profile) {
    switch (profile) {
      case 'driving-shortest':
        return 'shortest';
      default:
        return 'recommended';
    }
  }

  static void _sortRoutesForProfile(List<RoutePath> routes, String profile) {
    switch (profile) {
      case 'driving-shortest':
        routes.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        return;
      case 'driving-car':
      case 'foot-walking':
      case 'wheelchair':
      default:
        routes.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
        return;
    }
  }
}

class RoutePath {
  const RoutePath({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.neighborhoodShare = 0,
    this.arterialShare = 0,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final double neighborhoodShare;
  final double arterialShare;
}
