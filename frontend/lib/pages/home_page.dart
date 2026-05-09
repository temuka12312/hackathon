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

  final MapController _mapController = MapController();
  LatLng currentLocation = _defaultLocation;
  String? locationError;

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(nextLocation, 15);
        }
      });
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

              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
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
                        actionButton(Icons.local_taxi, 'Такси', Colors.amber),
                        actionButton(Icons.people, 'Shared Ride', Colors.blue),
                        actionButton(Icons.shield, 'Safe Route', Colors.green),
                        actionButton(Icons.sos, 'SOS', Colors.red),
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

  Widget actionButton(IconData icon, String label, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}
