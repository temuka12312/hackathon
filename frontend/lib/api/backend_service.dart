import 'dart:convert';

import 'package:http/http.dart' as http;

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
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw Exception(json['message'] as String? ?? 'Бүртгэл амжилтгүй.');
    }

    return AuthResponse.fromJson(json);
  }

  static Future<AuthResponse> loginUser({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        json['message'] as String? ?? 'Нэвтрэх үед алдаа гарлаа.',
      );
    }

    return AuthResponse.fromJson(json);
  }
}
