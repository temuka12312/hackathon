import 'package:flutter/material.dart';

import '../api/backend_service.dart';
import '../components/auth_shell.dart';
import '../components/auth_status_banner.dart';
import '../components/auth_text_field.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
      _isSuccess = false;
    });

    try {
      final result = await BackendService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isSuccess = true;
        _message = result.name.isEmpty
            ? result.message
            : '${result.message} ${result.name}';
      });
    } catch (error) {
      setState(() {
        _message = error.toString().replaceFirst('Exception: ', '');
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

    return AuthShell(
      switchLabel: 'Шинэ хэрэглэгч үү?',
      switchActionLabel: 'Create account',
      onSwitchTap: () =>
          Navigator.pushReplacementNamed(context, RegisterPage.routeName),
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign in', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Continue to book rides, manage trips, and stay synced across devices.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF5B665F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 6 characters',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Нууц үг 6-аас дээш тэмдэгттэй байна';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                if (_message != null) ...[
                  AuthStatusBanner(message: _message!, isSuccess: _isSuccess),
                  const SizedBox(height: 18),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF123C37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _login,
                    child: Text(
                      _isSubmitting ? 'Signing in...' : 'Sign in',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
