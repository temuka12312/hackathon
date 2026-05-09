import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../widgets/map_zoom_controls.dart';
import 'active_trip_page.dart';

class RouteOptionsPage extends StatefulWidget {
  const RouteOptionsPage({super.key});

  @override
  State<RouteOptionsPage> createState() => _RouteOptionsPageState();
}

class _RouteOptionsPageState extends State<RouteOptionsPage> {
  static const double _minZoom = 5;
  static const double _maxZoom = 18;
  static const _origin = LatLng(47.9184, 106.9177);
  static const _destination = LatLng(47.9300, 106.9350);
  static const _route = [
    _origin,
    LatLng(47.922, 106.922),
    LatLng(47.927, 106.930),
    _destination,
  ];

  final MapController _mapController = MapController();
  int _selectedVehicle = 0;

  static const _vehicles = [
    _Vehicle('Хотын машин', '4 мин', '₮6,550', Icons.directions_car_rounded),
    _Vehicle('UBCab', '6 мин', '₮5,200', Icons.local_taxi_rounded),
    _Vehicle('Хүнд тээвэр', '8 мин', '₮11,200', Icons.local_shipping_rounded),
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
          // Map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(47.924, 106.926),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                        border: Border.all(color: Colors.white, width: 2.5),
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
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 264,
            child: MapZoomControls(
              onZoomIn: () => _adjustZoom(1),
              onZoomOut: () => _adjustZoom(-1),
            ),
          ),

          // Top card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Таны байршил',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Column(
                                children: const [
                                  SizedBox(height: 2),
                                  Divider(
                                    color: AppColors.bg3,
                                    height: 12,
                                    indent: 0,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Сүхбаатарын талбай',
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
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom sheet
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

  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
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
              SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _vehicles.length,
                  itemBuilder: (_, i) => _vehicleCard(i),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ActiveTripPage()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Захиалах',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleCard(int i) {
    final v = _vehicles[i];
    final active = _selectedVehicle == i;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 156,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.bg3,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(v.icon, color: Colors.white, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    v.eta,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              v.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              v.price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Vehicle {
  final String name;
  final String eta;
  final String price;
  final IconData icon;
  const _Vehicle(this.name, this.eta, this.price, this.icon);
}
