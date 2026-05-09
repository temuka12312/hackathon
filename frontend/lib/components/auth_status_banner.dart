import 'package:flutter/material.dart';

class AuthStatusBanner extends StatelessWidget {
  const AuthStatusBanner({
    super.key,
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isSuccess
        ? const Color(0xFFD7F5EA)
        : theme.colorScheme.errorContainer;
    final foreground = isSuccess
        ? const Color(0xFF0F5132)
        : theme.colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
