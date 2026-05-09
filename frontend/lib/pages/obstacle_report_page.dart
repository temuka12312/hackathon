import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'camera_page.dart';

void showObstacleReportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ObstacleReportSheet(),
  );
}

class _ObstacleReportSheet extends StatefulWidget {
  const _ObstacleReportSheet();

  @override
  State<_ObstacleReportSheet> createState() => _ObstacleReportSheetState();
}

class _ObstacleReportSheetState extends State<_ObstacleReportSheet> {
  int? _selected;

  static const _categories = [
    _Category('Замын засвар', Icons.construction_rounded, AppColors.danger),
    _Category('Үерт зам', Icons.water_rounded, AppColors.routeBlue),
    _Category('Мөс / цас', Icons.ac_unit_rounded, Color(0xFF4DD0E1)),
    _Category('Эвдэрсэн зам', Icons.warning_rounded, AppColors.warning),
    _Category('Хаагдсан зам', Icons.block_rounded, AppColors.danger),
    _Category('Замын осол', Icons.car_crash_rounded, AppColors.danger),
    _Category('Нарийн зам', Icons.local_shipping_rounded, AppColors.muted),
    _Category('Хүртээмжийн саад', Icons.accessible_rounded, Color(0xFF9C27B0)),
    _Category('Түр бөглөрөл', Icons.timer_rounded, AppColors.warning),
    _Category('Зам нүх', Icons.circle_outlined, Color(0xFF795548)),
    _Category('Бусад', Icons.add_circle_outline_rounded, AppColors.muted),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Саадын төрөл сонгох',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Замд тулгарсан саадын төрлийг сонгоно уу.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: _categories.length,
                itemBuilder: (_, i) => _categoryCard(i),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          final label = _categories[_selected!].label;
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CameraPage(obstacleType: label),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.bg3,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Үргэлжлүүлэх',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(int index) {
    final cat = _categories[index];
    final isSelected = _selected == index;

    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon,
                color: isSelected ? AppColors.primary : cat.color, size: 22),
            const SizedBox(height: 6),
            Text(
              cat.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String label;
  final IconData icon;
  final Color color;
  const _Category(this.label, this.icon, this.color);
}
