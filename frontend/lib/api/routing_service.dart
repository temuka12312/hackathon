import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  const RoutingService._();

  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';

  static Future<List<LatLng>> fetchRoute({
    required LatLng start,
    required LatLng end,
    required String profile,
  }) async {
    final coordinates =
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';

    final uri = Uri.parse('$_baseUrl/$profile/$coordinates').replace(
      queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
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

    final geometry =
        routes.first['geometry'] as Map<String, dynamic>? ?? const {};
    final coordinatesJson =
        geometry['coordinates'] as List<dynamic>? ?? const [];

    return coordinatesJson.map((point) {
      final values = point as List<dynamic>;
      return LatLng(
        (values[1] as num).toDouble(),
        (values[0] as num).toDouble(),
      );
    }).toList();
  }
}
