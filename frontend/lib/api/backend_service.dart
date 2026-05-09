import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backend_response.dart';
import '../models/register_response.dart';
import 'api_client.dart';

class BackendService {
  const BackendService._();

  static String get baseUrl => ApiClient.baseUrl;

  static Future<BackendResponse> fetchHealth() async {
    final uri = Uri.parse('$baseUrl/api/health');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Backend returned ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return BackendResponse.fromJson(json);
  }

  static Future<RegisterResponse> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw Exception(json['message'] as String? ?? 'Бүртгэл амжилтгүй.');
    }

    return RegisterResponse.fromJson(json);
  }
}
