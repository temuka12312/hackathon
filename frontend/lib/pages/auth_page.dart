import 'package:flutter/material.dart';

import '../api/backend_service.dart';
import '../components/registration_form.dart';
import '../models/login_response.dart';
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

  bool _isRegisterSubmitting = false;
  bool _isLoginSubmitting = false;
  String? _registerMessage;
  bool _registerSucceeded = false;
  String? _loginMessage;

  static const _primaryBlue = Color(0xFF1A56DB);
  static const _darkNavy = Color(0xFF0D1B4B);

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
    if (form == null || !form.validate()) return;

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
      if (!mounted) return;
      setState(() {
        _registerSucceeded = true;
        _registerMessage = response.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _registerSucceeded = false;
        _registerMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isRegisterSubmitting = false);
    }
  }

  Future<void> _submitLogin() async {
    final form = _loginFormKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoginSubmitting = true;
      _loginMessage = null;
    });

    try {
      final LoginResponse _ = await BackendService.loginUser(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainScaffold()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoginSubmitting = false;
        _loginMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _darkNavy,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.34,
            child: _buildBrandSection(),
          ),
          Expanded(child: _buildFormSection()),
        ],
      ),
    );
  }

  Widget _buildBrandSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_darkNavy, _primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'UBCab',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Ухаалаг замнал • Аюулгүй хот',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabToggle(),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _showLogin
                  ? _buildLoginForm()
                  : RegistrationForm(
                      key: const ValueKey('register'),
                      formKey: _registerFormKey,
                      nameController: _registerNameController,
                      emailController: _registerEmailController,
                      passwordController: _registerPasswordController,
                      isSubmitting: _isRegisterSubmitting,
                      onSubmit: _submitRegistration,
                      message: _registerMessage,
                      succeeded: _registerSucceeded,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabItem('Нэвтрэх', true),
          const SizedBox(width: 4),
          _tabItem('Бүртгүүлэх', false),
        ],
      ),
    );
  }

  Widget _tabItem(String label, bool isLogin) {
    final isActive = _showLogin == isLogin;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showLogin = isLogin),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? _primaryBlue : Colors.black54,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Имэйл',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Имэйлээ оруулна уу';
              if (!t.contains('@')) return 'Зөв имэйл оруулна уу';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: !_loginPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Нууц үг',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _loginPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(
                  () => _loginPasswordVisible = !_loginPasswordVisible,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Нууц үгээ оруулна уу';
              return null;
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoginSubmitting ? null : _submitLogin,
            child: Text(_isLoginSubmitting ? 'Нэвтэрч байна...' : 'Нэвтрэх'),
          ),
          if (_loginMessage != null) ...[
            const SizedBox(height: 12),
            _buildMessageBanner(_loginMessage!, false),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBanner(String message, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isSuccess ? Colors.green : Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              (isSuccess ? Colors.green : Colors.red).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
