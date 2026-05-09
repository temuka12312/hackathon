import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/routing_service.dart';
import '../theme/app_colors.dart';
import '../widgets/map_zoom_controls.dart';
import 'active_trip_page.dart';

class RouteOptionsPage extends StatefulWidget {
  const RouteOptionsPage({super.key, this.origin, this.destination});

  final LatLng? origin;
  final LatLng? destination;

  @override
  State<RouteOptionsPage> createState() => _RouteOptionsPageState();
}

class _RouteOptionsPageState extends State<RouteOptionsPage> {
  static const _fallbackOrigin = LatLng(47.9184, 106.9177);
  static const _fallbackDest = LatLng(47.9300, 106.9350);
  static const double _minZoom = 5;
  static const double _maxZoom = 18;

  final MapController _mapController = MapController();

  LatLng get _origin => widget.origin ?? _fallbackOrigin;
  LatLng get _dest => widget.destination ?? _fallbackDest;

  List<LatLng> _routePoints = [];
  int _selectedVehicle = 0;

  static const _vehicles = [
    _Vehicle('Хотын машин', '4 мин', '₮6,550', Icons.directions_car_rounded),
    _Vehicle('UBCab', '6 мин', '₮5,200', Icons.local_taxi_rounded),
    _Vehicle('Хүнд тээвэр', '8 мин', '₮11,200', Icons.local_shipping_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  void _adjustZoom(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, nextZoom);
  }

  Future<void> _fetchRoute() async {
    try {
      final routes = await RoutingService.fetchRoutes(
        start: _origin,
        end: _dest,
        profile: 'driving',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _routePoints = routes.isNotEmpty
            ? routes.first.points
            : [_origin, _dest];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routePoints = [_origin, _dest];
      });
    }
  }

  LatLng get _mapCenter => LatLng(
    (_origin.latitude + _dest.latitude) / 2,
    (_origin.longitude + _dest.longitude) / 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _mapCenter, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ubcab.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
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
                  Marker(
                    point: _dest,
                    width: 40,
                    height: 48,
                    child: const Icon(
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
                            const Text(
                              'Таны байршил',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_origin.latitude.toStringAsFixed(4)}, ${_origin.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Divider(color: AppColors.bg3, height: 16),
                            Text(
                              '${_dest.latitude.toStringAsFixed(4)}, ${_dest.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
          ),
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _vehicles.length,
                  itemBuilder: (_, index) => _vehicleCard(index),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ActiveTripPage(),
                    ),
                  ),
                  child: const Text('Захиалах'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleCard(int index) {
    final vehicle = _vehicles[index];
    final active = _selectedVehicle == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = index),
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
                Icon(vehicle.icon, color: Colors.white, size: 20),
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
                    vehicle.eta,
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
              vehicle.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              vehicle.price,
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
  const _Vehicle(this.name, this.eta, this.price, this.icon);

  final String name;
  final String eta;
  final String price;
  final IconData icon;
}
