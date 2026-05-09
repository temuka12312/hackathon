import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  static const _activities = [
    _Activity('Мөс / цас', 'Сүхбаатар дүүрэг', '+50', '10:24'),
    _Activity('Замын засвар', 'Хан-Уул дүүрэг', '+50', '09:15'),
    _Activity('Замын осол', 'Баянзүрх дүүрэг', '+50', '08:52'),
    _Activity('Үерт зам', 'Чингэлтэй дүүрэг', '+50', '07:30'),
  ];

  static const _badges = [
    _Badge(Icons.local_fire_department_rounded, 'Идэвхтэй', AppColors.danger),
    _Badge(Icons.verified_user_rounded, 'Итгэмжит', AppColors.primary),
    _Badge(Icons.star_rounded, 'Шилдэг', AppColors.gold),
    _Badge(Icons.workspace_premium_rounded, 'Pro', AppColors.routeBlue),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rewards',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your reporting streak, trust, and contribution history in one premium view.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 26,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Нийт оноо',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1,250',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: 0.62,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Next tier',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '1,250 / 2,000',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _badges.map(_buildBadge).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recent activity',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ..._activities.map(_buildActivity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(_Badge badge) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: badge.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(badge.icon, color: badge.color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          badge.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActivity(_Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.route_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.location,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.points,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activity.time,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Activity {
  const _Activity(this.title, this.location, this.points, this.time);

  final String title;
  final String location;
  final String points;
  final String time;
}

class _Badge {
  const _Badge(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}
