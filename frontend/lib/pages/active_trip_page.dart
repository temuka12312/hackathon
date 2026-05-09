import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../widgets/map_zoom_controls.dart';
import 'obstacle_report_page.dart';

class ActiveTripPage extends StatefulWidget {
  const ActiveTripPage({super.key});

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  static const double _minZoom = 5;
  static const double _maxZoom = 18;
  final MapController _mapController = MapController();

  static const _origin = LatLng(47.9184, 106.9177);
  static const _destination = LatLng(47.9300, 106.9350);
  static const _route = [
    _origin,
    LatLng(47.922, 106.922),
    LatLng(47.927, 106.930),
    _destination,
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
      body: Column(
        children: [
          // Map — top half
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(47.924, 106.926),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ubcab.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route,
                          strokeWidth: 5,
                          color: AppColors.routeBlue,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _origin,
                          width: 18,
                          height: 18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                        const Marker(
                          point: _destination,
                          width: 40,
                          height: 48,
                          child: Icon(
                            Icons.location_pin,
                            color: AppColors.danger,
                            size: 48,
                          ),
                        ),
                        const Marker(
                          point: LatLng(47.921, 106.920),
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    bottom: false,
                    child: MapZoomControls(
                      onZoomIn: () => _adjustZoom(1),
                      onZoomOut: () => _adjustZoom(-1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom panel
          Container(
            color: AppColors.bg2,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ETA chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Хүрэлт: 12:45  •  2 мин',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Driver card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg3,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Б. Отгонбаяр',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.gold,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '4.9',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                'Toyota Prius',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'УБ 1234 АА',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Safety score
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Аюулгүйн оноо',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '96%',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            value: 0.96,
                            backgroundColor: AppColors.bg3,
                            color: AppColors.success,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Addresses
                    _addressRow(
                      Icons.radio_button_checked_rounded,
                      AppColors.primary,
                      'Таны байршил',
                      '2 мин',
                    ),
                    const SizedBox(height: 8),
                    _addressRow(
                      Icons.location_pin,
                      AppColors.danger,
                      'Сүхбаатарын талбай',
                      '12:45',
                    ),
                    const SizedBox(height: 16),

                    // Report button
                    OutlinedButton.icon(
                      onPressed: () => showObstacleReportSheet(context),
                      icon: const Icon(
                        Icons.warning_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                      label: const Text(
                        'Саад мэдээлэх',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressRow(IconData icon, Color color, String label, String detail) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            detail,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
