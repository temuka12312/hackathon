import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../pages/home_page.dart';
import '../pages/accessibility_map_page.dart';
import '../pages/rewards_page.dart';
import '../pages/profile_page.dart';
import '../pages/obstacle_report_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    HomePage(),
    AccessibilityMapPage(),
    RewardsPage(),
    ProfilePage(),
  ];

  static const _navItems = [
    _NavItem(Icons.home_rounded, 'Нүүр'),
    _NavItem(Icons.map_rounded, 'Зам'),
    _NavItem(Icons.emoji_events_rounded, 'Оноо'),
    _NavItem(Icons.person_rounded, 'Профайл'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showObstacleReportSheet(context),
        backgroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.bg1,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left two tabs
              _buildNavItem(0),
              _buildNavItem(1),
              // Center gap for FAB
              const SizedBox(width: 64),
              // Right two tabs
              _buildNavItem(2),
              _buildNavItem(3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: active ? Colors.white : AppColors.muted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.muted,
                fontSize: 10,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
