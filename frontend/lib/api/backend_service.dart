import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/login_response.dart';
import '../models/auth_response.dart';
import 'api_client.dart';

class BackendService {
  const BackendService._();

  static String get baseUrl => ApiClient.baseUrl;

  static Future<AuthResponse> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
    } catch (_) {
      throw Exception(
        'Backend-тай холбогдож чадсангүй. Сервер ажиллаж байгаа эсэх, порт нь $_portLabel мөн эсэхийг шалгана уу.',
      );
    }

    Map<String, dynamic> json = const {};

    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        json = const {};
      }
    }

    if (response.statusCode != 201) {
      throw Exception(
        json['message'] as String? ??
            'Бүртгэл амжилтгүй. (${response.statusCode})',
      );
    }

    return AuthResponse.fromJson(json);
  }

  static Future<LoginResponse> loginUser({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (_) {
      throw Exception(
        'Backend-тай холбогдож чадсангүй. Сервер ажиллаж байгаа эсэх, порт нь $_portLabel мөн эсэхийг шалгана уу.',
      );
    }

    Map<String, dynamic> json = const {};

    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        json = const {};
      }
    }

    if (response.statusCode != 200) {
      throw Exception(
        json['message'] as String? ??
            'Нэвтрэх амжилтгүй. (${response.statusCode})',
      );
    }

    return LoginResponse.fromJson(json);
  }

  static Future<void> saveRoute({
    required List<LatLng> points,
    List<double>? elevations,
    required String mode,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final polyline = List.generate(points.length, (i) {
      final pt = <String, dynamic>{
        'lat': points[i].latitude,
        'lng': points[i].longitude,
      };
      if (elevations != null && i < elevations.length) {
        pt['ele'] = elevations[i];
      }
      return pt;
    });
    final uri = Uri.parse('$baseUrl/api/routes');
    await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transportMode': mode,
        'polyline': polyline,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      }),
    );
  }

  static Future<List<Map<String, dynamic>>> getRoutes() async {
    final uri = Uri.parse('$baseUrl/api/routes');
    final response = await http.get(uri);
    if (response.statusCode != 200) return [];
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static String get _portLabel => Uri.parse(baseUrl).port.toString();
}
