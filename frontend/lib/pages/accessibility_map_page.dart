import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../widgets/map_zoom_controls.dart';

class AccessibilityMapPage extends StatefulWidget {
  const AccessibilityMapPage({super.key});

  @override
  State<AccessibilityMapPage> createState() => _AccessibilityMapPageState();
}

class _AccessibilityMapPageState extends State<AccessibilityMapPage> {
  static const double _minZoom = 5;
  static const double _maxZoom = 18;
  static const _center = LatLng(47.9184, 106.9177);

  final MapController _mapController = MapController();

  bool _showRamps = true;
  bool _showElevators = true;
  bool _showClosed = true;

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

  void _adjustZoom(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ubcab.app',
              ),
              CircleLayer(
                circles: [
                  if (_showRamps) ..._circles(_ramps, AppColors.success, 36),
                  if (_showElevators)
                    ..._circles(_elevators, AppColors.routeBlue, 30),
                  if (_showClosed)
                    ..._circles(_closedRoads, AppColors.danger, 34),
                ],
              ),
            ],
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.52),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _FrostCard(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.accessible_forward_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accessibility map',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Рамп, лифт, хаалттай хэсгүүдийг хянах',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 250,
            child: MapZoomControls(
              onZoomIn: () => _adjustZoom(1),
              onZoomOut: () => _adjustZoom(-1),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.26,
            minChildSize: 0.2,
            maxChildSize: 0.46,
            snap: true,
            snapSizes: const [0.26, 0.46],
            builder: (context, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.stroke,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Accessibility layers',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'City movement-д саад болж болох цэгүүдийг хурдан шүүж харуулна.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    _legendRow(
                      AppColors.success,
                      Icons.accessible_rounded,
                      'Рамп',
                      _showRamps,
                      (value) => setState(() => _showRamps = value),
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      AppColors.routeBlue,
                      Icons.elevator_rounded,
                      'Лифт',
                      _showElevators,
                      (value) => setState(() => _showElevators = value),
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      AppColors.danger,
                      Icons.block_rounded,
                      'Хаалттай зам',
                      _showClosed,
                      (value) => setState(() => _showClosed = value),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<CircleMarker> _circles(List<LatLng> points, Color color, double radius) {
    return points
        .map(
          (point) => CircleMarker(
            point: point,
            radius: radius,
            color: color.withValues(alpha: 0.18),
            borderColor: color,
            borderStrokeWidth: 2,
          ),
        )
        .toList();
  }

  Widget _legendRow(
    Color color,
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _FrostCard extends StatelessWidget {
  const _FrostCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          child: child,
        ),
      ),
    );
  }
}
