import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'points_store.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final _store = PointsStore();

  static const _badges = [
    _Badge(Icons.local_fire_department_rounded, 'Идэвхтэй', AppColors.danger),
    _Badge(Icons.verified_user_rounded, 'Итгэмжит', AppColors.primary),
    _Badge(Icons.star_rounded, 'Шилдэг', AppColors.gold),
    _Badge(Icons.workspace_premium_rounded, 'Pro', AppColors.routeBlue),
  ];

  static const int _nextTier = 2000;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _store.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final total = _store.total;
    final activities = _store.activities;
    final progress = (total / _nextTier).clamp(0.0, 1.0);

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

              // 🏆 Оноо карт
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
                    const Text('Нийт оноо', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Text(
                      _fmt(total),
                      style: const TextStyle(
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
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Next tier', style: TextStyle(color: Colors.white70)),
                        Text(
                          '$total / $_nextTier',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Badges
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _badges.map(_buildBadge).toList(),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Recent activity',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),

              if (activities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text(
                      'Одоохондоо мэдээлэл байхгүй байна.\nМэдээлэл илгээснээр энд харагдана.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                )
              else
                ...activities.map(_buildActivity),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(_Badge b) => Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: b.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(b.icon, color: b.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            b.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );

  Widget _buildActivity(ActivityEntry a) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
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
                    a.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(a.location, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${a.points}',
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(a.time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}

class _Badge {
  const _Badge(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}