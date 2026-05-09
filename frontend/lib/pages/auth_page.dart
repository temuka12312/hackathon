import 'package:flutter/material.dart';

import '../api/backend_service.dart';
import '../components/registration_form.dart';
import '../models/login_response.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  bool _isRegisterSubmitting = false;
  bool _isLoginSubmitting = false;
  String? _registerMessage;
  bool _registerSucceeded = false;
  String? _loginMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        setState(() {
          _isRegisterSubmitting = false;
        });
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

      setState(() {
        _isLoginSubmitting = false;
        _loginMessage = response.message;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F8FC), Color(0xFFE2ECFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'UB SmartRide',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Апп нээгдэхэд шууд нэвтрэх эсвэл бүртгүүлэх дэлгэц харагдана.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(text: 'Login'),
                                Tab(text: 'Register'),
                              ],
                            ),
                            SizedBox(
                              height: 430,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildLoginForm(theme),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: RegistrationForm(
                                      formKey: _registerFormKey,
                                      nameController: _registerNameController,
                                      emailController: _registerEmailController,
                                      passwordController:
                                          _registerPasswordController,
                                      isSubmitting: _isRegisterSubmitting,
                                      onSubmit: _submitRegistration,
                                      message: _registerMessage,
                                      succeeded: _registerSucceeded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HomePage(),
                          ),
                        );
                      },
                      child: const Text('Газрын зураг руу түр орох'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Бүртгэлтэй хэрэглэгч нэвтрэх',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _loginEmailController,
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
                  controller: _loginPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Нууц үг',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Нууц үгээ оруулна уу';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoginSubmitting ? null : _submitLogin,
                  child: Text(
                    _isLoginSubmitting ? 'Нэвтэрч байна...' : 'Нэвтрэх',
                  ),
                ),
                if (_loginMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _loginMessage!,
                    style: TextStyle(
                      color: _loginMessage == 'Амжилттай нэвтэрлээ.'
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
    );
  }
}
