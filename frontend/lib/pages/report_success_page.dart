import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'points_store.dart';

class ReportSuccessPage extends StatefulWidget {
  final String obstacleType;
  final String location;

  const ReportSuccessPage({
    super.key,
    required this.obstacleType,
    this.location = 'Улаанбаатар хот',
  });

  @override
  State<ReportSuccessPage> createState() => _ReportSuccessPageState();
}

class _ReportSuccessPageState extends State<ReportSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  static const int _earnedPoints = 50;
  final _store = PointsStore();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _store.addPoints(
        _earnedPoints,
        title: widget.obstacleType,
        location: widget.location,
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 2.5),
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 52),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Мэдээлэл хүлээн авлаа!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.obstacleType,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                widget.location,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '+$_earnedPoints оноо авлаа',
                      style: TextStyle(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ListenableBuilder(
                listenable: _store,
                builder: (_, __) => Text(
                  'Нийт оноо: ${_store.total}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Нүүр хуудас руу',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}