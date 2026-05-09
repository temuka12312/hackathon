import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationError =
            'Location permission бүрмөсөн хаалттай байна. Settings-ээс зөвшөөрнө үү.';
      });
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

      _focusRoute();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        locationError = 'Таны байршлыг авч чадсангүй.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeOptions = _buildRouteOptions();
    final activeRoute =
        routeOptions[selectedRoute] ?? routeOptions[_defaultRoute]!;

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
                polylines: routeOptions.entries.map((entry) {
                  final isSelected = entry.key == selectedRoute;
                  final route = entry.value;

                  return Polyline(
                    points: route.points,
                    strokeWidth: isSelected ? 7 : 4,
                    color: isSelected
                        ? route.color
                        : route.color.withValues(alpha: 0.32),
                  );
                }).toList(),
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
                    point: activeRoute.points.last,
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
                          activeRoute.description,
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
        points: _routePoints(const [
          [0.0000, 0.0000],
          [0.0030, 0.0080],
          [0.0070, 0.0180],
          [0.0110, 0.0290],
        ]),
      ),
      'Shared Ride': _RouteOption(
        color: Colors.blue,
        description: 'Замдаа rider авах боломжтой нийлмэл цэгүүдтэй маршрут.',
        points: _routePoints(const [
          [0.0000, 0.0000],
          [0.0045, 0.0050],
          [0.0060, 0.0150],
          [0.0095, 0.0240],
          [0.0130, 0.0320],
        ]),
      ),
      'Safe Route': _RouteOption(
        color: Colors.green,
        description: 'Илүү гэрэлтүүлэгтэй, гол замууд дагасан аюулгүй чиглэл.',
        points: _routePoints(const [
          [0.0000, 0.0000],
          [0.0020, 0.0100],
          [0.0050, 0.0200],
          [0.0080, 0.0260],
          [0.0120, 0.0360],
        ]),
      ),
      'SOS': _RouteOption(
        color: Colors.red,
        description: 'Хамгийн ойр emergency цэг рүү хурдан хүрэх маршрут.',
        points: _routePoints(const [
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

      final centerPoint = route.points[route.points.length ~/ 2];
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
          setState(() {
            selectedRoute = label;
          });
          _focusRoute();

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
    required this.points,
  });

  final Color color;
  final String description;
  final List<LatLng> points;
}
