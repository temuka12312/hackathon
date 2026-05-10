import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/backend_service.dart';
import '../components/auth_status_banner.dart';
import '../components/auth_text_field.dart';
import '../models/app_user.dart';
import '../models/login_response.dart';
import '../theme/app_colors.dart';
import '../widgets/main_scaffold.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _showLogin = true;

  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;
  bool _isRegisterSubmitting = false;
  bool _isLoginSubmitting = false;
  String? _registerMessage;
  bool _registerSucceeded = false;
  String? _loginMessage;

  @override
  void dispose() {
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    final form = _registerFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isRegisterSubmitting = true;
      _registerMessage = null;
      _registerSucceeded = false;
    });

    try {
      final response = await BackendService.registerUser(
        name: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _registerSucceeded = true;
        _registerMessage = response.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _registerSucceeded = false;
        _registerMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isRegisterSubmitting = false);
      }
    }
  }

  Future<void> _submitLogin() async {
    final form = _loginFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isLoginSubmitting = true;
      _loginMessage = null;
    });

    try {
      final LoginResponse response = await BackendService.loginUser(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      if (!mounted) {
        return;
      }

      final currentUser = AppUser(name: response.name, email: response.email);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainScaffold(currentUser: currentUser),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoginSubmitting = false;
        _loginMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07080A), Color(0xFF131519), Color(0xFF1B2220)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(theme),
                      const SizedBox(height: 24),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildToggle(),
                            const SizedBox(height: 28),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.05, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _showLogin
                                  ? _buildLoginForm(theme)
                                  : _buildRegisterForm(theme),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Move through Ulaanbaatar with a cleaner, faster booking flow.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Book rides, monitor safer routes, and keep the map experience focused on motion instead of clutter.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _toggleItem(label: 'Нэвтрэх', isLogin: true),
          const SizedBox(width: 6),
          _toggleItem(label: 'Бүртгүүлэх', isLogin: false),
        ],
      ),
    );
  }

  Widget _toggleItem({required String label, required bool isLogin}) {
    final active = _showLogin == isLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showLogin = isLogin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Тавтай морил', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Sign in to manage rides, alerts, and destination history in one place.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          AuthTextField(
            controller: _loginEmailController,
            label: 'Имэйл',
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
          TextFormField(
            controller: _loginPasswordController,
            obscureText: !_loginPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Нууц үгээ оруулна уу';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Нууц үг',
              hintText: 'Таны нууц үг',
              fillColor: AppColors.lightSurface,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => _loginPasswordVisible = !_loginPasswordVisible,
                  );
                },
                icon: Icon(
                  _loginPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_loginMessage != null) ...[
            AuthStatusBanner(message: _loginMessage!, isSuccess: false),
            const SizedBox(height: 18),
          ],
          FilledButton(
            onPressed: _isLoginSubmitting ? null : _submitLogin,
            child: Text(_isLoginSubmitting ? 'Нэвтэрч байна...' : 'Нэвтрэх'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Fast access for trips, reports, and account activity.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(ThemeData theme) {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Шинэ бүртгэл', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Create one account to book rides, report road issues, and keep your saved destinations synced.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          AuthTextField(
            controller: _registerNameController,
            label: 'Нэр',
            hint: 'Таны бүтэн нэр',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Нэрээ оруулна уу';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _registerEmailController,
            label: 'Имэйл',
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
          TextFormField(
            controller: _registerPasswordController,
            obscureText: !_registerPasswordVisible,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Нууц үг 6-аас дээш тэмдэгттэй байна';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Нууц үг',
              hintText: 'Доод тал нь 6 тэмдэгт',
              fillColor: AppColors.lightSurface,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(
                    () => _registerPasswordVisible = !_registerPasswordVisible,
                  );
                },
                icon: Icon(
                  _registerPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_registerMessage != null) ...[
            AuthStatusBanner(
              message: _registerMessage!,
              isSuccess: _registerSucceeded,
            ),
            const SizedBox(height: 18),
          ],
          FilledButton(
            onPressed: _isRegisterSubmitting ? null : _submitRegistration,
            child: Text(
              _isRegisterSubmitting ? 'Бүртгэж байна...' : 'Бүртгэл үүсгэх',
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
