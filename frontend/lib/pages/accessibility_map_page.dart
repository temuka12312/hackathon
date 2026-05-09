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
  bool _showRamps = true;
  bool _showElevators = true;
  bool _showClosed = true;
  final MapController _mapController = MapController();

  static const _center = LatLng(47.9184, 106.9177);

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
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          // Map with accessibility circles
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ubcab.app',
              ),
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
            ],
          ),
          Positioned(
            right: 16,
            bottom: 232,
            child: MapZoomControls(
              onZoomIn: () => _adjustZoom(1),
              onZoomOut: () => _adjustZoom(-1),
            ),
          ),

          // Top accessibility banner
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
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.accessible_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Хүртээмжийн горим идэвхтэй',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
