import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../api/routing_service.dart';

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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                  Marker(
                    point: currentLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 42,
                    ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safe Route сонгох',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Хамгийн товч бөгөөд аюулгүй замыг ямар хэрэглэгчид зориулж тооцохоо сонгоно уу.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                ...options.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withValues(alpha: 0.12),
                      child: Icon(option.icon, color: Colors.green.shade700),
                    ),
                    title: Text(option.label),
                    subtitle: Text(option.subtitle),
                    trailing: selectedSafeMode == option.label
                        ? Icon(Icons.check_circle, color: Colors.green.shade700)
                        : null,
                    onTap: () => Navigator.of(context).pop(option.label),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      selectedRoute = 'Safe Route';
      selectedSafeMode = selected;
    });
    _loadSelectedRoute();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Safe Route: $selected'),
          duration: const Duration(seconds: 2),
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
      width: 128,
      margin: const EdgeInsets.only(right: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey.shade900,
          foregroundColor: isSelected ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          if (label == 'Safe Route') {
            _showSafeRouteOptions();
            return;
          }

          setState(() {
            selectedRoute = label;
          });
          _loadSelectedRoute();

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(description),
                duration: const Duration(seconds: 2),
              ),
            );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.black : color, size: 32),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center),
          ],
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
