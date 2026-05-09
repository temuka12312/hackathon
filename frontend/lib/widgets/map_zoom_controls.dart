import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mapInk.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.mapInk.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(icon: Icons.add_rounded, onTap: onZoomIn),
          Container(
            width: 36,
            height: 1,
            color: AppColors.mapSand.withValues(alpha: 0.18),
          ),
          _ZoomButton(icon: Icons.remove_rounded, onTap: onZoomOut),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.mapGlow, size: 22),
        ),
      ),
    );
  }
}
