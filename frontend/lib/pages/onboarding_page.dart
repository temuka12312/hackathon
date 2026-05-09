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
      title: 'Саад мэдээлэх',
      subtitle: 'Report road obstacles',
      body: 'Замын саадуудыг бусдад мэдэгдэж,\nаюулгүй замнахад тусал.',
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
    ),
    _Slide(
      title: 'Аюулгүй зам',
      subtitle: 'Safe routing',
      body: 'Саад мэдээллийг ашиглан хамгийн\nаюулгүй замыг сонго.',
      icon: Icons.route_rounded,
      color: AppColors.routeBlue,
    ),
    _Slide(
      title: 'Оноо цуглуулах',
      subtitle: 'Earn rewards',
      body: 'Мэдээлэл илгээх тутамд оноо\nцуглуулж, шагнал ав.',
      icon: Icons.emoji_events_rounded,
      color: AppColors.gold,
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AuthPage()),
      );
    }
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
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _buildSlide(_slides[i]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _page == _slides.length - 1 ? 'Эхлэх' : 'Үргэлжлүүлэх',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_Slide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Illustration area
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: slide.color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: const Size(220, 110),
                  painter: _CityMapPainter(slide.color),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: slide.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: slide.color.withValues(alpha: 0.4)),
                  ),
                  child: Icon(slide.icon, color: slide.color, size: 34),
                ),
              ],
            ),
          ),
          const Spacer(flex: 1),
          Text(
            slide.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            slide.subtitle,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.bg3,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _Slide {
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Color color;
  const _Slide({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    required this.color,
  });
}

class _CityMapPainter extends CustomPainter {
  final Color color;
  const _CityMapPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = ui.PaintingStyle.stroke;

    // Horizontal street lines
    for (final y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        grid,
      );
    }
    // Vertical street lines
    for (final x in [0.3, 0.6]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        grid,
      );
    }

    // Glowing route line
    final route = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round;

    final path = ui.Path()
      ..moveTo(size.width * 0.05, size.height * 0.75)
      ..lineTo(size.width * 0.3, size.height * 0.75)
      ..lineTo(size.width * 0.3, size.height * 0.25)
      ..lineTo(size.width * 0.6, size.height * 0.25)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width * 0.95, size.height * 0.5);

    canvas.drawPath(path, route);

    // Start dot
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.75),
      5,
      Paint()..color = color,
    );
    // End dot
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.5),
      5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_CityMapPainter old) => old.color != color;
}
