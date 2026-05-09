import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'auth_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      eyebrow: 'Live road awareness',
      title: 'Report obstacles in seconds.',
      body:
          'Share blocked roads, hazards, and congestion signals with a ride flow that stays clean and immediate.',
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
    ),
    _Slide(
      eyebrow: 'Smarter motion',
      title: 'Choose safer routes with less friction.',
      body:
          'Keep the map clear, compare route context faster, and start each trip from a more confident view.',
      icon: Icons.alt_route_rounded,
      color: AppColors.accent,
    ),
    _Slide(
      eyebrow: 'Rewards layer',
      title: 'Turn local insight into points.',
      body:
          'Contribute traffic and accessibility updates, then track streaks, trust, and rider reputation in one account.',
      icon: Icons.workspace_premium_rounded,
      color: AppColors.gold,
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060709), Color(0xFF121417), Color(0xFF090A0C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'UBCab',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _next,
                      child: Text(
                        _page == _slides.length - 1 ? 'Эхлэх' : 'Алгасах',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemCount: _slides.length,
                    itemBuilder: (_, index) {
                      final slide = _slides[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _HeroCard(slide: slide)),
                          const SizedBox(height: 28),
                          Text(
                            slide.eyebrow,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.title,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide.body,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.66),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _buildDots(),
                    const Spacer(),
                    Expanded(
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: Text(
                          _page == _slides.length - 1 ? 'Continue' : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(_slides.length, (index) {
        final active = _page == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: active ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            slide.color.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(slide.icon, color: Colors.white, size: 30),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(280, 220),
              painter: _RouteCanvasPainter(slide.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

class _RouteCanvasPainter extends CustomPainter {
  const _RouteCanvasPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final street = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.4
      ..style = ui.PaintingStyle.stroke;

    for (final y in [0.16, 0.38, 0.62, 0.84]) {
      canvas.drawLine(
        Offset(size.width * 0.06, size.height * y),
        Offset(size.width * 0.94, size.height * y),
        street,
      );
    }

    for (final x in [0.18, 0.42, 0.67, 0.86]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * 0.08),
        Offset(size.width * x, size.height * 0.92),
        street,
      );
    }

    final routeGlow = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 18
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;

    final route = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;

    final path = ui.Path()
      ..moveTo(size.width * 0.12, size.height * 0.78)
      ..lineTo(size.width * 0.28, size.height * 0.78)
      ..lineTo(size.width * 0.28, size.height * 0.45)
      ..lineTo(size.width * 0.53, size.height * 0.45)
      ..lineTo(size.width * 0.53, size.height * 0.24)
      ..lineTo(size.width * 0.82, size.height * 0.24)
      ..lineTo(size.width * 0.82, size.height * 0.68);

    canvas.drawPath(path, routeGlow);
    canvas.drawPath(path, route);
    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.78),
      7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.68),
      9,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
