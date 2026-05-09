import 'package:flutter/material.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F1EA), Color(0xFFE1ECE8)],
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
                      const SizedBox(height: 16),
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
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 32,
            offset: Offset(0, 14),
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
        Text(switchLabel, style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: onSwitchTap,
          child: Text(
            switchActionLabel,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
