import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_colors.dart';
import '../pages/home_page.dart';
import '../pages/accessibility_map_page.dart';
import '../pages/rewards_page.dart';
import '../pages/profile_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.currentUser});

  final AppUser? currentUser;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  final HomePageController _homePageController = HomePageController();
  int _currentIndex = 0;

  static const _navItems = [
    _NavItem(Icons.home_rounded, 'Нүүр'),
    _NavItem(Icons.map_rounded, 'Зам'),
    _NavItem(Icons.emoji_events_rounded, 'Оноо'),
    _NavItem(Icons.person_rounded, 'Профайл'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(controller: _homePageController),
      const AccessibilityMapPage(),
      const RewardsPage(),
      ProfilePage(currentUser: widget.currentUser),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(index: _currentIndex, children: pages),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _buildNavItem(0)),
                  Expanded(child: _buildNavItem(1)),
                  Expanded(child: _buildCenterAction()),
                  Expanded(child: _buildNavItem(2)),
                  Expanded(child: _buildNavItem(3)),
                ],
              ),
            ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: active ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAction() {
    return AnimatedBuilder(
      animation: _homePageController,
      builder: (context, _) {
        final active = _currentIndex == 0;
        final journeyStarted = _homePageController.journeyStarted;
        final busy = _homePageController.busy;

        return GestureDetector(
          onTap: busy
              ? null
              : () {
                  if (_currentIndex != 0) {
                    setState(() => _currentIndex = 0);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _homePageController.handlePrimaryAction();
                    });
                    return;
                  }
                  _homePageController.handlePrimaryAction();
                },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  journeyStarted
                      ? Icons.stop_circle_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  busy
                      ? 'Түр хүлээ'
                      : journeyStarted
                      ? 'Дуусгах'
                      : 'Эхлүүлэх',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!active)
                  const Text(
                    'Аялал',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}