import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User Registration Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late Future<BackendResponse> _backendResponse;
  bool _isSubmitting = false;
  String? _registerMessage;
  bool _registerSucceeded = false;

  @override
  void initState() {
    super.initState();
    _backendResponse = BackendService.fetchHealth();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final nextResponse = BackendService.fetchHealth();
    setState(() {
      _backendResponse = nextResponse;
    });
    await nextResponse;
  }

  Future<void> _register() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _registerMessage = null;
      _registerSucceeded = false;
    });

    try {
      final result = await BackendService.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _registerSucceeded = true;
        _registerMessage = result.message;
      });

      _passwordController.clear();
    } catch (error) {
      setState(() {
        _registerMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Хэрэглэгч бүртгэл')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FutureBuilder<BackendResponse>(
                  future: _backendResponse,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return _StatusCard(
                        title: 'Backend холболт амжилтгүй',
                        subtitle: snapshot.error.toString(),
                        color: theme.colorScheme.errorContainer,
                        buttonLabel: 'Дахин оролдох',
                        onPressed: _refresh,
                      );
                    }

                    final response = snapshot.data!;
                    return _StatusCard(
                      title: response.message,
                      subtitle:
                          'Status: ${response.status}\nURL: ${BackendService.baseUrl}',
                      color: theme.colorScheme.primaryContainer,
                      buttonLabel: 'Шинэчлэх',
                      onPressed: _refresh,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Шинэ хэрэглэгч бүртгэх',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Нэр',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Нэрээ оруулна уу';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Имэйл',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Имэйлээ оруулна уу';
                              }
                              if (!text.contains('@')) {
                                return 'Зөв имэйл оруулна уу';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Нууц үг',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Нууц үг 6-аас дээш тэмдэгттэй байна';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _register,
                            child: Text(
                              _isSubmitting ? 'Бүртгэж байна...' : 'Бүртгэх',
                            ),
                          ),
                          if (_registerMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _registerMessage!,
                              style: TextStyle(
                                color: _registerSucceeded
                                    ? Colors.green.shade700
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Color color;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(subtitle),
            const SizedBox(height: 20),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class BackendService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

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
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw Exception(json['message'] as String? ?? 'Бүртгэл амжилтгүй.');
    }

    return RegisterResponse.fromJson(json);
  }
}

class BackendResponse {
  const BackendResponse({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  factory BackendResponse.fromJson(Map<String, dynamic> json) {
    return BackendResponse(
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? 'No message',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  final String status;
  final String message;
  final String timestamp;
}

class RegisterResponse {
  const RegisterResponse({
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String? ?? 'Хэрэглэгч бүртгэгдлээ.',
    );
  }

  final String message;
}
