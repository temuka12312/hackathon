import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../api/routing_service.dart';
import '../theme/app_colors.dart';
import 'route_options_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const LatLng _defaultLocation = LatLng(47.9184, 106.9177);
  static const String _defaultRoute = 'Такси';
  static const String _defaultSafeMode = 'Явган';

  final MapController _mapController = MapController();

  LatLng _currentLocation = _defaultLocation;
  String? _locationError;
  String _selectedRoute = _defaultRoute;
  String _selectedSafeMode = _defaultSafeMode;
  List<LatLng> _activeRoutePoints = const [];
  bool _isRouteLoading = false;
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        _locationError = 'Location service унтраалттай байна.';
      });
      await _loadSelectedRoute();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        _locationError = 'Location permission зөвшөөрөөгүй байна.';
      });
      await _loadSelectedRoute();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationError =
            'Location permission бүрмөсөн хаалттай байна. Settings-ээс зөвшөөрнө үү.';
      });
      await _loadSelectedRoute();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationError = 'Таны байршлыг авч чадсангүй.';
      });
    }

    await _loadSelectedRoute();
  }

  @override
  Widget build(BuildContext context) {
    final routeOptions = _buildRouteOptions();
    final activeRoute =
        routeOptions[_selectedRoute] ?? routeOptions[_defaultRoute]!;
    final routePoints = _activeRoutePoints.isNotEmpty
        ? _activeRoutePoints
        : activeRoute.fallbackPoints;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.frontend',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 6,
                    color: activeRoute.color,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 28,
                    height: 28,
                    child: _buildLocationDot(),
                  ),
                  Marker(
                    point: routePoints.last,
                    width: 52,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        color: activeRoute.color,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  _buildSearchBar(context),
                  const Spacer(),
                  if (_locationError != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _locationError!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  _buildRouteStatus(activeRoute),
                  const SizedBox(height: 232),
                ],
              ),
            ),
          ),
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

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RouteOptionsPage()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'Хаашаа явах вэ?',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStatus(_RouteOption activeRoute) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedRoute маршрут',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isRouteLoading
                ? 'Зам тооцоолж байна...'
                : _routeError ?? activeRoute.description,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildActionButton(
                      icon: Icons.local_taxi_rounded,
                      label: 'Такси',
                      color: Colors.amber,
                      description:
                          'Таны байршлаас төв замаар шууд очих хурдан чиглэл.',
                    ),
                    _buildActionButton(
                      icon: Icons.people_alt_rounded,
                      label: 'Shared Ride',
                      color: Colors.blue,
                      description:
                          'Замдаа rider авах боломжтой нийлмэл цэгүүдтэй маршрут.',
                    ),
                    _buildActionButton(
                      icon: Icons.shield_rounded,
                      label: 'Safe Route',
                      color: Colors.green,
                      description: _safeRouteDescription(),
                      onTap: _showSafeRouteOptions,
                    ),
                    _buildActionButton(
                      icon: Icons.sos_rounded,
                      label: 'SOS',
                      color: Colors.red,
                      description:
                          'Хамгийн ойр emergency цэг рүү хурдан хүрэх маршрут.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _locationError == null
                        ? 'Байршил тогтоогдлоо'
                        : 'Default байршил ашиглаж байна',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _selectedRoute == 'Safe Route'
                        ? _selectedSafeMode
                        : 'Маршрут бэлэн',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required String description,
    Future<void> Function()? onTap,
  }) {
    final isSelected = _selectedRoute == label;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () async {
          if (onTap != null) {
            await onTap();
            return;
          }

          await _selectRoute(label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 156,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.bg3,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : AppColors.bg3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isSelected ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDot() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Future<void> _selectRoute(String label) async {
    setState(() {
      _selectedRoute = label;
    });

    await _loadSelectedRoute();
  }

  Future<void> _showSafeRouteOptions() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        const options = [
          (
            label: 'Машинтай',
            subtitle: 'Автомашинд тохирсон өргөн, аюулгүй зам',
            icon: Icons.directions_car_filled_rounded,
          ),
          (
            label: 'Явган',
            subtitle: 'Явган хүнд илүү аюулгүй, гэрэлтүүлэгтэй зам',
            icon: Icons.directions_walk_rounded,
          ),
          (
            label: 'Хөгжлийн бэрхшээлтэй',
            subtitle: 'Саад багатай, хүртээмж харгалзсан зам',
            icon: Icons.accessible_forward_rounded,
          ),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Safe Route төрөл',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (final option in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(option.icon, color: AppColors.primary),
                    ),
                    title: Text(
                      option.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(option.subtitle),
                    trailing: _selectedSafeMode == option.label
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(option.label),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSafeMode = selected;
      _selectedRoute = 'Safe Route';
    });

    await _loadSelectedRoute();
  }

  Future<void> _loadSelectedRoute() async {
    final routeOptions = _buildRouteOptions();
    final activeRoute =
        routeOptions[_selectedRoute] ?? routeOptions[_defaultRoute]!;
    final fallbackPoints = activeRoute.fallbackPoints;

    setState(() {
      _isRouteLoading = true;
      _routeError = null;
      _activeRoutePoints = fallbackPoints;
    });

    try {
      final routes = await RoutingService.fetchRoutes(
        start: _currentLocation,
        end: fallbackPoints.last,
        profile: activeRoute.profile,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeRoutePoints = routes.first.points;
        _isRouteLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeRoutePoints = fallbackPoints;
        _isRouteLoading = false;
        _routeError =
            'Жинхэнэ зам ачаалж чадсангүй. Түр fallback route үзүүлж байна.';
      });
    }

    _focusRoute();
  }

  void _focusRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final routeOptions = _buildRouteOptions();
      final activeRoute =
          routeOptions[_selectedRoute] ?? routeOptions[_defaultRoute]!;
      final points = _activeRoutePoints.isNotEmpty
          ? _activeRoutePoints
          : activeRoute.fallbackPoints;

      _mapController.move(points[points.length ~/ 2], 14.2);
    });
  }

  Map<String, _RouteOption> _buildRouteOptions() {
    return {
      'Такси': _RouteOption(
        color: Colors.amber,
        description: 'Таны байршлаас төв замаар шууд очих хурдан чиглэл.',
        profile: 'driving-car',
        fallbackPoints: _routePoints(const [
          [0.0000, 0.0000],
          [0.0030, 0.0080],
          [0.0070, 0.0180],
          [0.0110, 0.0290],
        ]),
      ),
      'Shared Ride': _RouteOption(
        color: Colors.blue,
        description: 'Замдаа rider авах боломжтой нийлмэл цэгүүдтэй маршрут.',
        profile: 'driving-car',
        fallbackPoints: _routePoints(const [
          [0.0000, 0.0000],
          [0.0045, 0.0050],
          [0.0060, 0.0150],
          [0.0095, 0.0240],
          [0.0130, 0.0320],
        ]),
      ),
      'Safe Route': _RouteOption(
        color: Colors.green,
        description: _safeRouteDescription(),
        profile: _safeRouteProfile(),
        fallbackPoints: _safeRoutePoints(),
      ),
      'SOS': _RouteOption(
        color: Colors.red,
        description: 'Хамгийн ойр emergency цэг рүү хурдан хүрэх маршрут.',
        profile: 'driving-car',
        fallbackPoints: _routePoints(const [
          [0.0000, 0.0000],
          [-0.0020, 0.0070],
          [-0.0035, 0.0140],
          [-0.0015, 0.0210],
        ]),
      ),
    };
  }

  List<LatLng> _routePoints(List<List<double>> offsets) {
    return offsets
        .map(
          (offset) => LatLng(
            _currentLocation.latitude + offset[0],
            _currentLocation.longitude + offset[1],
          ),
        )
        .toList();
  }

  List<LatLng> _safeRoutePoints() {
    switch (_selectedSafeMode) {
      case 'Машинтай':
        return _routePoints(const [
          [0.0000, 0.0000],
          [0.0030, 0.0110],
          [0.0065, 0.0200],
          [0.0100, 0.0310],
        ]);
      case 'Хөгжлийн бэрхшээлтэй':
        return _routePoints(const [
          [0.0000, 0.0000],
          [0.0015, 0.0080],
          [0.0035, 0.0150],
          [0.0060, 0.0220],
          [0.0080, 0.0290],
        ]);
      case 'Явган':
      default:
        return _routePoints(const [
          [0.0000, 0.0000],
          [0.0020, 0.0100],
          [0.0050, 0.0200],
          [0.0080, 0.0260],
          [0.0120, 0.0360],
        ]);
    }
  }

  String _safeRouteDescription() {
    switch (_selectedSafeMode) {
      case 'Машинтай':
        return 'Машинтай зорчигчид зориулсан, камер ба гэрэлтүүлэг сайтай гол замын чиглэл.';
      case 'Хөгжлийн бэрхшээлтэй':
        return 'Налуу зам, гарц, саад багатай хэсгүүдийг илүү харгалзсан аюулгүй чиглэл.';
      case 'Явган':
      default:
        return 'Явган зорчигчид зориулсан, гэрэлтүүлэгтэй гол замууд дагасан аюулгүй чиглэл.';
    }
  }

  String _safeRouteProfile() {
    switch (_selectedSafeMode) {
      case 'Хөгжлийн бэрхшээлтэй':
        return 'wheelchair';
      case 'Машинтай':
        return 'driving-car';
      case 'Явган':
      default:
        return 'foot-walking';
    }
  }
}

class _RouteOption {
  const _RouteOption({
    required this.color,
    required this.description,
    required this.profile,
    required this.fallbackPoints,
  });

  final Color color;
  final String description;
  final String profile;
  final List<LatLng> fallbackPoints;
}
