import 'package:flutter/material.dart';

import '../api/backend_service.dart';
import '../components/registration_form.dart';
import '../components/status_card.dart';
import '../models/backend_response.dart';

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
                      return StatusCard(
                        title: 'Backend холболт амжилтгүй',
                        subtitle: snapshot.error.toString(),
                        color: theme.colorScheme.errorContainer,
                        buttonLabel: 'Дахин оролдох',
                        onPressed: _refresh,
                      );
                    }

                    final response = snapshot.data!;
                    return StatusCard(
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
                RegistrationForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isSubmitting: _isSubmitting,
                  onSubmit: _register,
                  message: _registerMessage,
                  succeeded: _registerSucceeded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
