import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../api/backend_service.dart';
import '../api/routing_service.dart';
import '../theme/app_colors.dart';

class AccessibilityMapPage extends StatefulWidget {
  const AccessibilityMapPage({super.key});

  @override
  State<AccessibilityMapPage> createState() => _AccessibilityMapPageState();
}

class _AccessibilityMapPageState extends State<AccessibilityMapPage> {
  bool _showRamps = true;
  bool _showElevators = true;
  bool _showClosed = true;

  static const _center = LatLng(47.9184, 106.9177);
  LatLng _location = _center;

  static const _ramps = [
    LatLng(47.9200, 106.9180),
    LatLng(47.9160, 106.9210),
    LatLng(47.9240, 106.9150),
  ];
  static const _elevators = [
    LatLng(47.9175, 106.9230),
    LatLng(47.9220, 106.9260),
  ];
  static const _closedRoads = [
    LatLng(47.9145, 106.9170),
    LatLng(47.9265, 106.9195),
  ];

  // Destination + OSRM preview route
  LatLng? _destination;
  List<LatLng> _navRoutePoints = [];
  bool _isNavLoading = false;

  // GPS recording (always wheelchair mode)
  bool _isRecording = false;
  List<LatLng> _recordedPoints = [];
  StreamSubscription<Position>? _gpsSub;
  DateTime? _recordStart;

  // Concurrency guard
  bool _isBusy = false;

  // Community routes — precomputed, not rebuilt every frame
  List<Polyline> _communityPolylines = [];

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
    } catch (_) {}
  }

  Future<void> _loadSavedRoutes() async {
    try {
      final raw = await BackendService.getRoutes();
      if (!mounted) return;
      // Wheelchair routes full opacity purple; others faint
      final polylines = <Polyline>[];
      for (final r in raw) {
        final mode = r['transportMode'] as String;
        final pts = (r['polyline'] as List).map<LatLng>((p) =>
          LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())
        ).toList();
        if (pts.length >= 2) {
          polylines.add(Polyline(
            points: pts,
            strokeWidth: mode == 'wheelchair' ? 4.0 : 2.5,
            color: _communityColor(mode).withValues(
                alpha: mode == 'wheelchair' ? 0.7 : 0.2),
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
        final points = await RoutingService.fetchRoute(
          start: _location,
          end: dest,
          profile: 'foot',
        );
        if (!mounted) return;
        setState(() {
          _navRoutePoints = points;
          _isNavLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isNavLoading = false);
      }
      _startRecording();
    } finally {
      _isBusy = false;
    }
  }

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
    // Capture and clear immediately to prevent re-entry
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
          mode: 'wheelchair',
          startTime: start,
          endTime: DateTime.now(),
        );
        await _loadSavedRoutes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Хүртээмжийн маршрут хадгалагдлаа'),
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

  static Color _communityColor(String mode) => switch (mode) {
        'wheelchair' => const Color(0xFF9C27B0),
        'walk' => AppColors.success,
        'heavy' => AppColors.warning,
        _ => AppColors.routeBlue,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14,
              onTap: (_, latLng) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _setDestination(latLng);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ubcab.app',
              ),
              // Community routes — precomputed
              if (_communityPolylines.isNotEmpty)
                PolylineLayer(polylines: _communityPolylines),
              // OSRM preview route
              if (_navRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _navRoutePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF9C27B0),
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
                      color:
                          const Color(0xFF9C27B0).withValues(alpha: 0.6),
                    ),
                  ],
                ),
              // Accessibility feature circles
              CircleLayer(
                circles: [
                  if (_showRamps)
                    ..._ramps.map(
                      (p) => CircleMarker(
                        point: p,
                        radius: 40,
                        color: AppColors.success.withValues(alpha: 0.25),
                        borderColor: AppColors.success,
                        borderStrokeWidth: 2,
                      ),
                    ),
                  if (_showElevators)
                    ..._elevators.map(
                      (p) => CircleMarker(
                        point: p,
                        radius: 30,
                        color: AppColors.routeBlue.withValues(alpha: 0.25),
                        borderColor: AppColors.routeBlue,
                        borderStrokeWidth: 2,
                      ),
                    ),
                  if (_showClosed)
                    ..._closedRoads.map(
                      (p) => CircleMarker(
                        point: p,
                        radius: 35,
                        color: AppColors.danger.withValues(alpha: 0.2),
                        borderColor: AppColors.danger,
                        borderStrokeWidth: 2,
                      ),
                    ),
                ],
              ),
              // User location + destination markers
              MarkerLayer(
                markers: [
                  Marker(
                    point: _location,
                    width: 18,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 40,
                      height: 48,
                      child: const Icon(Icons.location_pin,
                          color: Color(0xFF9C27B0), size: 48),
                    ),
                ],
              ),
            ],
          ),

          // Top banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.accessible_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Хүртээмжийн горим — газрыг дарж очих газраа тэмдэглэнэ үү',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_destination != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_pin,
                              color: Color(0xFF9C27B0), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isNavLoading
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF9C27B0),
                                    ),
                                  )
                                : Text(
                                    '${_destination!.latitude.toStringAsFixed(4)}, '
                                    '${_destination!.longitude.toStringAsFixed(4)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          GestureDetector(
                            onTap: _clearDestination,
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.muted, size: 18),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Recording status chip
          if (_isRecording)
            Positioned(
              bottom: 220,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RecordingDot(),
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

          // Bottom legend panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bg2,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Давхарга',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _legendRow(
                        AppColors.success,
                        Icons.accessible_rounded,
                        'Рамп (налуу гарц)',
                        _showRamps,
                        (v) => setState(() => _showRamps = v),
                      ),
                      const SizedBox(height: 10),
                      _legendRow(
                        AppColors.routeBlue,
                        Icons.elevator_rounded,
                        'Лифт',
                        _showElevators,
                        (v) => setState(() => _showElevators = v),
                      ),
                      const SizedBox(height: 10),
                      _legendRow(
                        AppColors.danger,
                        Icons.block_rounded,
                        'Хаалттай зам',
                        _showClosed,
                        (v) => setState(() => _showClosed = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(
    Color color,
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
          inactiveTrackColor: AppColors.bg3,
        ),
      ],
    );
  }
}

class _RecordingDot extends StatelessWidget {
  const _RecordingDot();

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
