import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Frontend + Backend Demo',
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
  late Future<BackendResponse> _backendResponse;

  @override
  void initState() {
    super.initState();
    _backendResponse = BackendService.fetchHealth();
  }

  Future<void> _refresh() async {
    final nextResponse = BackendService.fetchHealth();
    setState(() {
      _backendResponse = nextResponse;
    });
    await nextResponse;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Express Backend холбоос'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FutureBuilder<BackendResponse>(
              future: _backendResponse,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
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
                  subtitle: 'Status: ${response.status}\nURL: ${BackendService.baseUrl}',
                  color: theme.colorScheme.primaryContainer,
                  buttonLabel: 'Шинэчлэх',
                  onPressed: _refresh,
                );
              },
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
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(subtitle),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
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
