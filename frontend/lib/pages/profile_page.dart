import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'authority_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifications = true;
  bool _accessibilityMode = false;

  static const _stats = [
    _Stat('Нийт мэдээлэл', '25'),
    _Stat('Баталгаажсан', '18'),
    _Stat('Streak өдөр', '7'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Avatar + edit
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 48),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.bg1, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Name & info
              const Text(
                'Б. Отгонбаяр',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'otgonbayar@email.com',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Бүртгүүлсэн: 2024 оны 3 сар',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _stats
                        .map(
                          (s) => Column(
                            children: [
                              Text(
                                s.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(s.label,
                                  style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Settings section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Тохиргоо',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _settingsCard([
                      _SwitchTile(
                        icon: Icons.notifications_rounded,
                        color: AppColors.primary,
                        label: 'Мэдэгдэл',
                        value: _notifications,
                        onChanged: (v) =>
                            setState(() => _notifications = v),
                      ),
                      _SwitchTile(
                        icon: Icons.accessible_rounded,
                        color: AppColors.success,
                        label: 'Хүртээмжийн горим',
                        value: _accessibilityMode,
                        onChanged: (v) =>
                            setState(() => _accessibilityMode = v),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _settingsCard([
                      _TapTile(
                        icon: Icons.language_rounded,
                        color: AppColors.routeBlue,
                        label: 'Хэл: Монгол',
                        onTap: () {},
                      ),
                      _TapTile(
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppColors.warning,
                        label: 'Эрх мэдлийн самбар',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AuthorityDashboardPage(),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Гарах',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    Divider(
                        color: AppColors.bg3, height: 1, indent: 52),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
        inactiveTrackColor: AppColors.bg3,
      ),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _TapTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.muted, size: 20),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  const _Stat(this.label, this.value);
}
