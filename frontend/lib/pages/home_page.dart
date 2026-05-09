import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import 'route_options_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const _defaultLocation = LatLng(47.9184, 106.9177);
  final MapController _mapController = MapController();
  LatLng _location = _defaultLocation;
  int _selectedMode = 0;

  // Pulsing animation for location dot
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  static const _obstacles = [
    _Obstacle(47.9220, 106.9190, _ObstacleType.ice, 'Мөс'),
    _Obstacle(47.9150, 106.9250, _ObstacleType.construction, 'Засвар'),
    _Obstacle(47.9195, 106.9130, _ObstacleType.congestion, 'Бөглөрөл'),
    _Obstacle(47.9270, 106.9220, _ObstacleType.accident, 'Осол'),
  ];

  static const _modes = [
    (label: 'Машин', icon: Icons.directions_car_rounded),
    (label: 'Явган', icon: Icons.directions_walk_rounded),
    (label: 'Хүнд тээвэр', icon: Icons.local_shipping_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) { return; }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) { return; }
      setState(
          () => _location = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_location, 15);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _location,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ubcab.app',
              ),
              MarkerLayer(
                markers: [
                  // User location
                  Marker(
                    point: _location,
                    width: 36,
                    height: 36,
                    child: _buildLocationDot(),
                  ),
                  // Obstacle pins
                  ..._obstacles.map(
                    (o) => Marker(
                      point: LatLng(o.lat, o.lng),
                      width: 72,
                      height: 34,
                      child: _ObstaclePinWidget(obstacle: o),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xDE1C2130), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Top UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 12),
                  _buildSearchBar(context),
                ],
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: (1 - _pulseController.value) * 0.35),
              ),
            ),
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          const Text(
            'UBCab',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Drivers nearby chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bg2.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text('28 жолооч',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bg2.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RouteOptionsPage()),
        ),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                'Хаашаа явах вэ?',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 18),
              Row(
                children: List.generate(_modes.length, (i) {
                  final m = _modes[i];
                  final active = _selectedMode == i;
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: i < _modes.length - 1 ? 10 : 0),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedMode = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.bg3,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(m.icon,
                                  color: Colors.white, size: 22),
                              const SizedBox(height: 6),
                              Text(
                                m.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 5),
                  const Text('Байршил тогтоогдлоо',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${_obstacles.length} саад ойролцоо',
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Obstacle marker widgets ──────────────────────────────────────────────────

enum _ObstacleType { ice, construction, congestion, accident }

class _Obstacle {
  final double lat;
  final double lng;
  final _ObstacleType type;
  final String label;
  const _Obstacle(this.lat, this.lng, this.type, this.label);
}

class _ObstaclePinWidget extends StatelessWidget {
  final _Obstacle obstacle;
  const _ObstaclePinWidget({required this.obstacle});

  @override
  Widget build(BuildContext context) {
    final color = switch (obstacle.type) {
      _ObstacleType.ice => const Color(0xFF4DD0E1),
      _ObstacleType.construction => AppColors.warning,
      _ObstacleType.congestion => AppColors.gold,
      _ObstacleType.accident => AppColors.danger,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 6),
            ],
          ),
          child: Text(
            obstacle.label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700),
          ),
        ),
        CustomPaint(
          size: const Size(8, 5),
          painter: _TrianglePainter(color),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
