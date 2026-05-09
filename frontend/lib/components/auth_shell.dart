import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.form,
    required this.switchLabel,
    required this.switchActionLabel,
    required this.onSwitchTap,
  });

  final Widget form;
  final String switchLabel;
  final String switchActionLabel;
  final VoidCallback onSwitchTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bg1, Color(0xFF16171B), Color(0xFF0D0E11)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(child: _FormPanel(child: form)),
                      const SizedBox(height: 20),
                      _SwitchRow(
                        switchLabel: switchLabel,
                        switchActionLabel: switchActionLabel,
                        onSwitchTap: onSwitchTap,
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
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 42,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchLabel,
    required this.switchActionLabel,
    required this.onSwitchTap,
  });

  final String switchLabel;
  final String switchActionLabel;
  final VoidCallback onSwitchTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          switchLabel,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        TextButton(
          onPressed: onSwitchTap,
          child: Text(
            switchActionLabel,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
