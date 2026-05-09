import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../api/backend_service.dart';
import '../api/routing_service.dart';
import '../theme/app_colors.dart';
import 'route_options_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// No SingleTickerProviderStateMixin — animation lives in _LocationDot
class _HomePageState extends State<HomePage> {
  static const _defaultLocation = LatLng(47.9184, 106.9177);
  final MapController _mapController = MapController();
  LatLng _location = _defaultLocation;
  int _selectedMode = 0;

  // Concurrency guard — prevents overlapping _setDestination calls
  bool _isBusy = false;

  // Feature 1 — destination + OSRM preview route
  LatLng? _destination;
  List<LatLng> _navRoutePoints = [];
  bool _isNavLoading = false;

  // Feature 2 — GPS recording
  bool _isRecording = false;
  List<LatLng> _recordedPoints = [];
  StreamSubscription<Position>? _gpsSub;
  DateTime? _recordStart;

  // Feature 3 — community routes (precomputed, not rebuilt every frame)
  List<Polyline> _communityPolylines = [];

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
    (label: 'Хүртээмж', icon: Icons.accessible_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadSavedRoutes();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
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
      setState(() => _location = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_location, 15);
    } catch (_) {}
  }

  Future<void> _loadSavedRoutes() async {
    try {
      final raw = await BackendService.getRoutes();
      if (!mounted) return;
      // Precompute Polyline objects here — not in build()
      final polylines = <Polyline>[];
      for (final r in raw) {
        final mode = r['transportMode'] as String;
        final pts = (r['polyline'] as List).map<LatLng>((p) =>
          LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())
        ).toList();
        if (pts.length >= 2) {
          polylines.add(Polyline(
            points: pts,
            strokeWidth: 3,
            color: _communityColor(mode).withValues(alpha: 0.25),
          ));
        }
      }
      setState(() => _communityPolylines = polylines);
    } catch (_) {}
  }

  Future<void> _setDestination(LatLng dest) async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      await _stopRecording();
      setState(() {
        _destination = dest;
        _navRoutePoints = [];
        _isNavLoading = true;
      });
      try {
        final points = await RoutingService.fetchRoutes(
          start: _location,
          end: dest,
          profile: _osrmProfile(),
        );
        if (!mounted) return;
        setState(() {
          _navRoutePoints = points.cast<LatLng>();
          _isNavLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isNavLoading = false);
      }
      // Recording starts only when user explicitly taps "Аялал эхлүүлэх"
    } finally {
      _isBusy = false;
    }
  }

  String _osrmProfile() =>
      (_selectedMode == 1 || _selectedMode == 3) ? 'foot' : 'driving';

  String _modeString() =>
      const ['car', 'walk', 'heavy', 'wheelchair'][_selectedMode];

  Color _modeColor() => switch (_selectedMode) {
        1 => AppColors.success,
        2 => AppColors.warning,
        3 => const Color(0xFF9C27B0),
        _ => AppColors.routeBlue,
      };

  static Color _communityColor(String mode) => switch (mode) {
        'walk' => AppColors.success,
        'heavy' => AppColors.warning,
        'wheelchair' => const Color(0xFF9C27B0),
        _ => AppColors.routeBlue,
      };

  void _startRecording() {
    _recordStart = DateTime.now();
    _recordedPoints = [_location];
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final pt = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _location = pt;
        _recordedPoints.add(pt);
      });
      if (_destination != null && _isRecording) {
        final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude,
          _destination!.latitude, _destination!.longitude,
        );
        if (dist <= 30) _stopRecording();
      }
    });
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording && _gpsSub == null) return;
    final sub = _gpsSub;
    final wasRecording = _isRecording;
    final points = List<LatLng>.from(_recordedPoints);
    final start = _recordStart;
    _gpsSub = null;
    _isRecording = false;
    await sub?.cancel();

    if (wasRecording && points.length >= 2 && start != null) {
      try {
        await BackendService.saveRoute(
          points: points,
          mode: _modeString(),
          startTime: start,
          endTime: DateTime.now(),
        );
        await _loadSavedRoutes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Маршрут хадгалагдлаа'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _recordedPoints = []);
  }

  Future<void> _clearDestination() async {
    await _stopRecording();
    if (mounted) {
      setState(() {
        _destination = null;
        _navRoutePoints = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _location,
              initialZoom: 14,
              onTap: (_, latLng) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _setDestination(latLng);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.frontend',
              ),
              // Community routes — precomputed, zero allocation in build()
              if (_communityPolylines.isNotEmpty)
                PolylineLayer(polylines: _communityPolylines),
              // OSRM preview route
              if (_navRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _navRoutePoints,
                      strokeWidth: 5,
                      color: AppColors.routeBlue,
                    ),
                  ],
                ),
              // Actual GPS track while recording
              if (_isRecording && _recordedPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recordedPoints,
                      strokeWidth: 4,
                      color: _modeColor().withValues(alpha: 0.6),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _location,
                    width: 36,
                    height: 36,
                    child: const _LocationDot(),
                  ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 40,
                      height: 48,
                      child: const Icon(Icons.location_pin,
                          color: AppColors.danger, size: 48),
                    ),
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

          // Top gradient overlay
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 8),
                  _buildSearchBar(context),
                ],
              ),
            ),
          ),

          // Recording status chip — only shown while recording
          if (_isRecording)
            Positioned(
              top: 140,
              right: 20,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(),
                      SizedBox(width: 6),
                      Text(
                        'Бичлэглэж байна',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(context),
          ),
        ],
      ),
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bg2.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GreenDot(),
                SizedBox(width: 5),
                Text('28 жолооч',
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
    if (_destination != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const Icon(Icons.location_pin,
                  color: AppColors.danger, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_destination!.latitude.toStringAsFixed(4)}, '
                  '${_destination!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _clearDestination,
                child: const Icon(Icons.close_rounded,
                    color: AppColors.muted, size: 20),
              ),
            ],
          ),
        ),
      );
    }
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
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      padding: EdgeInsets.only(
                          right: i < _modes.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMode = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                active ? AppColors.primary : AppColors.bg3,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(m.icon, color: Colors.white, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                m.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
              if (_destination != null && _isRecording)
                FilledButton(
                  onPressed: _stopRecording,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop_circle_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Аяллыг дуусгах',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else if (_destination != null)
                FilledButton(
                  onPressed: _isNavLoading ? null : _startRecording,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isNavLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Аялал эхлүүлэх',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                )
              else
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

// ── Isolated animation widgets — own their AnimationControllers ───────────────

class _LocationDot extends StatefulWidget {
  const _LocationDot();

  @override
  State<_LocationDot> createState() => _LocationDotState();
}

class _LocationDotState extends State<_LocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _anim = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (_, child) => Transform.scale(
            scale: _anim.value,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary
                    .withValues(alpha: (1 - _ctrl.value) * 0.35),
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
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Obstacle marker widgets ───────────────────────────────────────────────────

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
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 6),
            ],
          ),
          child: Text(
            obstacle.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 5),
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
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
