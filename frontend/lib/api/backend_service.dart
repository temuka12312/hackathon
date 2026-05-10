import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/auth_response.dart';
import '../models/login_response.dart';
import '../models/report_item.dart';
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

  static Future<List<ReportItem>> fetchReports() async {
    final uri = Uri.parse('$baseUrl/api/reports');
    http.Response response;

    try {
      response = await http.get(uri);
    } catch (_) {
      throw Exception(
        'Backend-тай холбогдож чадсангүй. Сервер ажиллаж байгаа эсэх, порт нь $_portLabel мөн эсэхийг шалгана уу.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Түгжрэлийн дата ачаалж чадсангүй. (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as List<dynamic>? ?? const [];
    return json
        .whereType<Map<String, dynamic>>()
        .map(ReportItem.fromJson)
        .toList();
  }

  static Future<void> saveRoute({
    required List<LatLng> points,
    List<double>? elevations,
    required String mode,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final uri = Uri.parse('$baseUrl/api/routes');
    final polyline = List.generate(points.length, (index) {
      final point = <String, dynamic>{
        'lat': points[index].latitude,
        'lng': points[index].longitude,
      };
      if (elevations != null && index < elevations.length) {
        final ele = elevations[index];
        if (ele.isFinite) {
          point['ele'] = ele;
        }
      }
      return point;
    });

    final body = jsonEncode({
      'transportMode': mode,
      'polyline': polyline,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    });

    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (_) {
      throw Exception('Маршрут хадгалах үед backend-тай холбогдож чадсангүй.');
    }

    if (response.statusCode != 201) {
      throw Exception('Маршрут хадгалж чадсангүй. (${response.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getRoutes() async {
    final uri = Uri.parse('$baseUrl/api/routes');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return [];
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static String get _portLabel => Uri.parse(baseUrl).port.toString();
}