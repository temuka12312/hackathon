import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
    required this.message,
    required this.succeeded,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? message;
  final bool succeeded;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: widget.nameController,
            decoration: const InputDecoration(
              labelText: 'Нэр',
              hintText: 'Таны бүтэн нэр',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Нэрээ оруулна уу';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Имэйл',
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Имэйлээ оруулна уу';
              if (!text.contains('@')) return 'Зөв имэйл оруулна уу';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: widget.passwordController,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'Нууц үг',
              hintText: 'Доод тал нь 6 тэмдэгт',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
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
            onPressed: widget.isSubmitting ? null : widget.onSubmit,
            child: Text(widget.isSubmitting ? 'Бүртгэж байна...' : 'Бүртгэх'),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 12),
            _buildMessageBanner(widget.message!, widget.succeeded),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBanner(String message, bool isSuccess) {
    final color = isSuccess ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
