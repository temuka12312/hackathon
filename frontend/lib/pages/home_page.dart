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

class _HomePageState extends State<HomePage> {
  static const LatLng _defaultLocation = LatLng(47.9184, 106.9177);
  static const String _defaultRoute = 'Такси';

  final MapController _mapController = MapController();

  LatLng currentLocation = _defaultLocation;
  String? locationError;
  String selectedRoute = _defaultRoute;
  String selectedSafeMode = 'Явган';
  List<LatLng> activeRoutePoints = const [];
  bool isRouteLoading = false;
  String? routeError;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        locationError = 'Location service унтраалттай байна.';
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
        locationError = 'Location permission зөвшөөрөөгүй байна.';
      });
      await _loadSelectedRoute();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationError =
            'Location permission бүрмөсөн хаалттай байна. Settings-ээс зөвшөөрнө үү.';
      });
      await _loadSelectedRoute();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final nextLocation = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() {
        currentLocation = nextLocation;
        locationError = null;
      });

      await _loadSelectedRoute();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        locationError = 'Таны байршлыг авч чадсангүй.';
      });
      await _loadSelectedRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeOptions = _buildRouteOptions();
    final activeRoute =
        routeOptions[selectedRoute] ?? routeOptions[_defaultRoute]!;
    final routePoints = activeRoutePoints.isNotEmpty
        ? activeRoutePoints
        : activeRoute.fallbackPoints;

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ub_smartride',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 7,
                    color: activeRoute.color,
                  ),
                ],
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
                  Marker(
                    point: routePoints.last,
                    width: 68,
                    height: 68,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        color: activeRoute.color,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Хаашаа явах вэ?',
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedRoute маршрут',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isRouteLoading
                              ? 'Зам тооцоолж байна...'
                              : routeError ?? activeRoute.description,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (locationError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        locationError!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        actionButton(
                          Icons.local_taxi,
                          'Такси',
                          Colors.amber,
                          'Таны байршлаас төв замаар шууд очих хурдан чиглэл.',
                        ),
                        actionButton(
                          Icons.people,
                          'Shared Ride',
                          Colors.blue,
                          'Замдаа rider авах боломжтой нийлмэл цэгүүдтэй маршрут.',
                        ),
                        actionButton(
                          Icons.shield,
                          'Safe Route',
                          Colors.green,
                          'Илүү гэрэлтүүлэгтэй, гол замууд дагасан аюулгүй чиглэл.',
                        ),
                        actionButton(
                          Icons.sos,
                          'SOS',
                          Colors.red,
                          'Хамгийн ойр emergency цэг рүү хурдан хүрэх маршрут.',
                        ),
                      ],
                    ),
                  ),
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

  Map<String, _RouteOption> _buildRouteOptions() {
    return {
      'Такси': _RouteOption(
        color: Colors.amber,
        description: 'Таны байршлаас төв замаар шууд очих хурдан чиглэл.',
        profile: 'driving',
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
        profile: 'driving',
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
        profile: 'driving',
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
            currentLocation.latitude + offset[0],
            currentLocation.longitude + offset[1],
          ),
        )
        .toList();
  }

  List<LatLng> _safeRoutePoints() {
    switch (selectedSafeMode) {
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
    switch (selectedSafeMode) {
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
    switch (selectedSafeMode) {
      case 'Машинтай':
        return 'driving';
      case 'Хөгжлийн бэрхшээлтэй':
      case 'Явган':
      default:
        return 'foot';
    }
  }

  Future<void> _loadSelectedRoute() async {
    final routeOptions = _buildRouteOptions();
    final activeRoute =
        routeOptions[selectedRoute] ?? routeOptions[_defaultRoute]!;
    final requestKey =
        '$selectedRoute:$selectedSafeMode:${currentLocation.latitude}:${currentLocation.longitude}';

    setState(() {
      isRouteLoading = true;
      routeError = null;
      activeRoutePoints = activeRoute.fallbackPoints;
    });

    try {
      final route = await RoutingService.fetchRoute(
        start: currentLocation,
        end: activeRoute.fallbackPoints.last,
        profile: activeRoute.profile,
      );

      if (!mounted) {
        return;
      }

      final isSameRequest =
          requestKey ==
          '$selectedRoute:$selectedSafeMode:${currentLocation.latitude}:${currentLocation.longitude}';
      if (!isSameRequest) {
        return;
      }

      setState(() {
        activeRoutePoints = route;
        isRouteLoading = false;
      });

      _focusRoute();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        activeRoutePoints = activeRoute.fallbackPoints;
        isRouteLoading = false;
        routeError =
            'Жинхэнэ зам ачаалж чадсангүй. Түр fallback route үзүүлж байна.';
      });

      _focusRoute();
    }
  }

  Future<void> _showSafeRouteOptions() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final options = [
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

  void _focusRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final route = _buildRouteOptions()[selectedRoute];
      if (route == null) {
        _mapController.move(currentLocation, 15);
        return;
      }

      final points = activeRoutePoints.isNotEmpty
          ? activeRoutePoints
          : route.fallbackPoints;
      final centerPoint = points[points.length ~/ 2];
      _mapController.move(centerPoint, 14.2);
    });
  }

  Widget actionButton(
    IconData icon,
    String label,
    Color color,
    String description,
  ) {
    final isSelected = selectedRoute == label;

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
