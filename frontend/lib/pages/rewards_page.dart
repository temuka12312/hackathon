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
    _Badge(Icons.local_fire_department_rounded, 'Идэвхтэй', AppColors.danger, true),
    _Badge(Icons.verified_user_rounded, 'Итгэмжит', AppColors.primary, true),
    _Badge(Icons.star_rounded, 'Шилдэг', AppColors.gold, true),
    _Badge(Icons.workspace_premium_rounded, 'Мэргэжлийн', AppColors.routeBlue, false),
    _Badge(Icons.military_tech_rounded, 'Ахмад', AppColors.warning, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Profile row
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Б. Отгонбаяр',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          '🏅 Санкийн тайлбар мэдээлэгч',
                          style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Points card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A6B), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Нийт оноо',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.monetization_on_rounded,
                            color: AppColors.gold, size: 32),
                        SizedBox(width: 10),
                        Text(
                          '1,250',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress to next level
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Дараагийн түвшин',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text('1,250 / 2,000',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1250 / 2000,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.2),
                        color: AppColors.gold,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Badges
              const Text(
                'Шагналууд',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _badges.map(_buildBadge).toList(),
              ),
              const SizedBox(height: 24),

              // Activity feed
              const Text(
                'Сүүлийн үйлдлүүд',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ..._activities.map(_buildActivity),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(_Badge b) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: b.unlocked
                ? b.color.withValues(alpha: 0.15)
                : AppColors.bg3,
            shape: BoxShape.circle,
            border: Border.all(
              color: b.unlocked
                  ? b.color.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Icon(
            b.icon,
            color: b.unlocked ? b.color : AppColors.muted,
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          b.label,
          style: TextStyle(
              color: b.unlocked ? Colors.white : AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActivity(_Activity a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_rounded,
                color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.type,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(a.location,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(a.points,
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(a.time,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Activity {
  final String type;
  final String location;
  final String points;
  final String time;
  const _Activity(this.type, this.location, this.points, this.time);
}

class _Badge {
  final IconData icon;
  final String label;
  final Color color;
  final bool unlocked;
  const _Badge(this.icon, this.label, this.color, this.unlocked);
}
