import 'dart:math' as math;

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
  static const LatLng _defaultDestination = LatLng(47.9304, 106.9537);
  static const String _defaultRoute = 'Такси';

  final MapController _mapController = MapController();

  LatLng currentLocation = _defaultLocation;
  LatLng destination = _defaultDestination;
  String? locationError;
  String selectedRoute = _defaultRoute;
  String selectedSafeMode = 'Явган';
  _MapEditTarget selectedEditTarget = _MapEditTarget.destination;
  List<RoutePath> activeRoutes = const [];
  bool isRouteLoading = false;
  String? routeError;
  bool hasManualDestination = false;

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
        if (!hasManualDestination) {
          destination = _defaultDestinationFor(nextLocation);
        }
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
    final routingPolicy = _routingPolicyFor(activeRoute);
    final displayedRoutes = activeRoutes.isNotEmpty
        ? activeRoutes
        : _fallbackRoutesFor(activeRoute, routingPolicy);
    final hasDisplayedRoutes = displayedRoutes.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 15,
              onTap: (_, point) => _updateEditablePoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ub_smartride',
              ),
              PolylineLayer(
                polylines: [
                  for (final entry in displayedRoutes.asMap().entries)
                    Polyline(
                      points: entry.value.points,
                      strokeWidth: entry.key == 0 ? 8 : 5,
                      color: entry.key == 0
                          ? activeRoute.color
                          : activeRoute.color.withValues(alpha: 0.28),
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
                    point: destination,
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
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Газрын зураг дээр товшоод цэгээ зөөнө',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Эхлээд аль цэгийг зөөхөө сонгоод map дээр tap хийнэ үү.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ChoiceChip(
                              label: const Text('Байгаа газар'),
                              selected:
                                  selectedEditTarget == _MapEditTarget.current,
                              onSelected: (_) {
                                setState(() {
                                  selectedEditTarget = _MapEditTarget.current;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Очих газар'),
                              selected:
                                  selectedEditTarget ==
                                  _MapEditTarget.destination,
                              onSelected: (_) {
                                setState(() {
                                  selectedEditTarget =
                                      _MapEditTarget.destination;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _locationSummaryRow(
                          icon: Icons.my_location_rounded,
                          color: Colors.red,
                          label: 'Байгаа газар',
                          point: currentLocation,
                        ),
                        const SizedBox(height: 8),
                        _locationSummaryRow(
                          icon: Icons.flag_rounded,
                          color: activeRoute.color,
                          label: 'Очих газар',
                          point: destination,
                        ),
                      ],
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
                              : routeError ??
                                    _routeSummary(activeRoute, displayedRoutes),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (hasDisplayedRoutes) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: displayedRoutes.asMap().entries.map((
                              entry,
                            ) {
                              final isBest = entry.key == 0;
                              return _routeStatChip(
                                label: isBest
                                    ? _bestRouteLabel(routingPolicy)
                                    : 'Хувилбар ${entry.key + 1}',
                                route: entry.value,
                                color: activeRoute.color,
                                emphasized: isBest,
                              );
                            }).toList(),
                          ),
                        ],
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
        primaryFallbackWaypoints: const [
          _RouteWaypointSpec(0.00, 0.00),
          _RouteWaypointSpec(0.26, 0.10),
          _RouteWaypointSpec(0.54, -0.04),
          _RouteWaypointSpec(0.82, 0.06),
          _RouteWaypointSpec(1.00, 0.00),
        ],
        alternativeFallbackWaypoints: const [
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.18, -0.12),
            _RouteWaypointSpec(0.44, -0.06),
            _RouteWaypointSpec(0.72, 0.02),
            _RouteWaypointSpec(1.00, 0.00),
          ],
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.24, 0.18),
            _RouteWaypointSpec(0.58, 0.12),
            _RouteWaypointSpec(0.86, 0.04),
            _RouteWaypointSpec(1.00, 0.00),
          ],
        ],
      ),
      'Shared Ride': _RouteOption(
        color: Colors.blue,
        description: 'Замдаа rider авах боломжтой нийлмэл цэгүүдтэй маршрут.',
        profile: 'driving',
        primaryFallbackWaypoints: const [
          _RouteWaypointSpec(0.00, 0.00),
          _RouteWaypointSpec(0.20, 0.24),
          _RouteWaypointSpec(0.40, -0.08),
          _RouteWaypointSpec(0.66, 0.18),
          _RouteWaypointSpec(0.84, 0.04),
          _RouteWaypointSpec(1.00, 0.00),
        ],
        alternativeFallbackWaypoints: const [
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.22, 0.08),
            _RouteWaypointSpec(0.38, 0.28),
            _RouteWaypointSpec(0.64, 0.10),
            _RouteWaypointSpec(1.00, 0.00),
          ],
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.18, -0.10),
            _RouteWaypointSpec(0.46, 0.04),
            _RouteWaypointSpec(0.74, -0.02),
            _RouteWaypointSpec(1.00, 0.00),
          ],
        ],
      ),
      'Safe Route': _RouteOption(
        color: Colors.green,
        description: _safeRouteDescription(),
        profile: _safeRouteProfile(),
        primaryFallbackWaypoints: _safeRouteWaypoints(),
        alternativeFallbackWaypoints: _safeRouteAlternativeWaypoints(),
      ),
      'SOS': _RouteOption(
        color: Colors.red,
        description: 'Хамгийн ойр emergency цэг рүү хурдан хүрэх маршрут.',
        profile: 'driving',
        primaryFallbackWaypoints: const [
          _RouteWaypointSpec(0.00, 0.00),
          _RouteWaypointSpec(0.38, -0.10),
          _RouteWaypointSpec(0.74, 0.02),
          _RouteWaypointSpec(1.00, 0.00),
        ],
        alternativeFallbackWaypoints: const [
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.24, -0.18),
            _RouteWaypointSpec(0.52, -0.08),
            _RouteWaypointSpec(0.80, 0.01),
            _RouteWaypointSpec(1.00, 0.00),
          ],
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.30, 0.12),
            _RouteWaypointSpec(0.58, 0.08),
            _RouteWaypointSpec(0.88, 0.02),
            _RouteWaypointSpec(1.00, 0.00),
          ],
        ],
      ),
    };
  }

  List<LatLng> _routePoints(List<_RouteWaypointSpec> waypoints) {
    final latitudeDelta = destination.latitude - currentLocation.latitude;
    final longitudeDelta = destination.longitude - currentLocation.longitude;
    final length = math.sqrt(
      (latitudeDelta * latitudeDelta) + (longitudeDelta * longitudeDelta),
    );

    if (length < 0.00001) {
      return [currentLocation, destination];
    }

    final perpendicularLatitude = -longitudeDelta / length;
    final perpendicularLongitude = latitudeDelta / length;
    final lateralScale = math.max(length * 0.18, 0.0014);

    return waypoints.map((waypoint) {
      final baseLatitude =
          currentLocation.latitude + (latitudeDelta * waypoint.progress);
      final baseLongitude =
          currentLocation.longitude + (longitudeDelta * waypoint.progress);

      return LatLng(
        baseLatitude +
            (perpendicularLatitude * lateralScale * waypoint.lateral),
        baseLongitude +
            (perpendicularLongitude * lateralScale * waypoint.lateral),
      );
    }).toList();
  }

  List<_RouteWaypointSpec> _safeRouteWaypoints() {
    switch (selectedSafeMode) {
      case 'Машинтай':
        return const [
          _RouteWaypointSpec(0.00, 0.00),
          _RouteWaypointSpec(0.24, 0.12),
          _RouteWaypointSpec(0.52, 0.06),
          _RouteWaypointSpec(0.80, 0.10),
          _RouteWaypointSpec(1.00, 0.00),
        ];
      case 'Хөгжлийн бэрхшээлтэй':
        return const [
          _RouteWaypointSpec(0.00, 0.00),
          _RouteWaypointSpec(0.18, 0.05),
          _RouteWaypointSpec(0.42, 0.02),
          _RouteWaypointSpec(0.68, 0.08),
          _RouteWaypointSpec(0.88, 0.03),
          _RouteWaypointSpec(1.00, 0.00),
        ];
      case 'Явган':
      default:
        return const [
          _RouteWaypointSpec(0.00, 0.00),
          _RouteWaypointSpec(0.22, 0.16),
          _RouteWaypointSpec(0.46, 0.04),
          _RouteWaypointSpec(0.72, 0.10),
          _RouteWaypointSpec(1.00, 0.00),
        ];
    }
  }

  List<List<_RouteWaypointSpec>> _safeRouteAlternativeWaypoints() {
    switch (selectedSafeMode) {
      case 'Машинтай':
        return const [
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.20, 0.05),
            _RouteWaypointSpec(0.48, 0.14),
            _RouteWaypointSpec(0.76, 0.06),
            _RouteWaypointSpec(1.00, 0.00),
          ],
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.24, -0.04),
            _RouteWaypointSpec(0.56, 0.02),
            _RouteWaypointSpec(0.82, 0.03),
            _RouteWaypointSpec(1.00, 0.00),
          ],
        ];
      case 'Хөгжлийн бэрхшээлтэй':
        return const [
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.16, 0.02),
            _RouteWaypointSpec(0.40, 0.07),
            _RouteWaypointSpec(0.72, 0.04),
            _RouteWaypointSpec(1.00, 0.00),
          ],
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.20, -0.02),
            _RouteWaypointSpec(0.44, 0.01),
            _RouteWaypointSpec(0.76, 0.06),
            _RouteWaypointSpec(1.00, 0.00),
          ],
        ];
      case 'Явган':
      default:
        return const [
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.20, 0.08),
            _RouteWaypointSpec(0.46, 0.18),
            _RouteWaypointSpec(0.78, 0.07),
            _RouteWaypointSpec(1.00, 0.00),
          ],
          [
            _RouteWaypointSpec(0.00, 0.00),
            _RouteWaypointSpec(0.18, -0.03),
            _RouteWaypointSpec(0.50, 0.03),
            _RouteWaypointSpec(0.74, 0.09),
            _RouteWaypointSpec(1.00, 0.00),
          ],
        ];
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
    final routingPolicy = _routingPolicyFor(activeRoute);
    final fallbackRoutes = _fallbackRoutesFor(activeRoute, routingPolicy);
    final requestKey =
        '$selectedRoute:$selectedSafeMode:${currentLocation.latitude}:${currentLocation.longitude}:${destination.latitude}:${destination.longitude}';

    setState(() {
      isRouteLoading = true;
      routeError = null;
      activeRoutes = fallbackRoutes;
    });

    try {
      final routes = await RoutingService.fetchRoutes(
        start: currentLocation,
        end: destination,
        profile: routingPolicy.profile,
      );

      if (!mounted) {
        return;
      }

      final isSameRequest =
          requestKey ==
          '$selectedRoute:$selectedSafeMode:${currentLocation.latitude}:${currentLocation.longitude}:${destination.latitude}:${destination.longitude}';
      if (!isSameRequest) {
        return;
      }

      setState(() {
        final normalizedRoutes = _normalizeRoutesForPolicy(
          routes,
          routingPolicy,
        );
        activeRoutes = _sortRoutesForPolicy(normalizedRoutes, routingPolicy);
        isRouteLoading = false;
      });

      _focusRoute();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        activeRoutes = fallbackRoutes;
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

      final routingPolicy = _routingPolicyFor(route);
      final displayedRoutes = activeRoutes.isNotEmpty
          ? activeRoutes
          : _fallbackRoutesFor(route, routingPolicy);
      if (displayedRoutes.isEmpty) {
        _mapController.move(currentLocation, 15);
        return;
      }
      final points = displayedRoutes.first.points;
      final centerPoint = points[points.length ~/ 2];
      _mapController.move(centerPoint, 14.2);
    });
  }

  void _updateEditablePoint(LatLng point) {
    setState(() {
      if (selectedEditTarget == _MapEditTarget.current) {
        currentLocation = point;
        locationError = null;
      } else {
        destination = point;
        hasManualDestination = true;
      }
    });

    _loadSelectedRoute();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            selectedEditTarget == _MapEditTarget.current
                ? 'Байгаа газар шинэчлэгдлээ'
                : 'Очих газар шинэчлэгдлээ',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  LatLng _defaultDestinationFor(LatLng start) {
    return LatLng(start.latitude + 0.012, start.longitude + 0.03);
  }

  _RoutingPolicy _routingPolicyFor(_RouteOption route) {
    if (selectedRoute != 'Safe Route') {
      return _RoutingPolicy(
        profile: route.profile,
        priority: _RoutePriority.shortest,
      );
    }

    switch (selectedSafeMode) {
      case 'Машинтай':
        return const _RoutingPolicy(
          profile: 'driving',
          priority: _RoutePriority.roadLegal,
        );
      case 'Явган':
        return const _RoutingPolicy(
          profile: 'foot',
          priority: _RoutePriority.fastestWalk,
        );
      case 'Хөгжлийн бэрхшээлтэй':
        return const _RoutingPolicy(
          profile: 'foot',
          priority: _RoutePriority.accessibleSafe,
        );
      default:
        return _RoutingPolicy(
          profile: route.profile,
          priority: _RoutePriority.shortest,
        );
    }
  }

  List<RoutePath> _fallbackRoutesFor(
    _RouteOption route,
    _RoutingPolicy routingPolicy,
  ) {
    final variants = <List<_RouteWaypointSpec>>[
      route.primaryFallbackWaypoints,
      ...route.alternativeFallbackWaypoints,
    ];

    final fallbackRoutes = variants.map((waypoints) {
      final points = _routePoints(waypoints);
      final distanceMeters = _estimateDistanceMeters(points);

      return RoutePath(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: _estimateDurationSeconds(
          distanceMeters,
          routingPolicy.profile,
        ),
      );
    }).toList();
    final normalizedFallbackRoutes = _normalizeRoutesForPolicy(
      fallbackRoutes,
      routingPolicy,
    );
    if (routingPolicy.priority == _RoutePriority.fastestWalk ||
        routingPolicy.priority == _RoutePriority.accessibleSafe) {
      return const [];
    }

    return _sortRoutesForPolicy(normalizedFallbackRoutes, routingPolicy);
  }

  String _routeSummary(_RouteOption option, List<RoutePath> routes) {
    if (routes.isEmpty) {
      return 'Энэ горимд бодит замын маршрут олдсонгүй.';
    }

    final routingPolicy = _routingPolicyFor(option);
    final bestRoute = routes.first;
    final alternativeCount = routes.length - 1;
    final alternativesText = alternativeCount > 0
        ? '$alternativeCount өөр боломжит замтай.'
        : 'Нэмэлт боломжит зам олдсонгүй.';

    return '${_policyDescription(option, routingPolicy)} ${_bestRouteLabel(routingPolicy)} нь ${_formatDistance(bestRoute.distanceMeters)}, ойролцоогоор ${_formatDuration(bestRoute.durationSeconds)}. $alternativesText';
  }

  Widget _routeStatChip({
    required String label,
    required RoutePath route,
    required Color color,
    required bool emphasized,
  }) {
    final background = emphasized
        ? color.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasized ? color.withValues(alpha: 0.6) : Colors.black12,
        ),
      ),
      child: Text(
        '$label · ${_formatDistance(route.distanceMeters)} · ${_formatDuration(route.durationSeconds)}',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    }

    return '${meters.round()} м';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes мин';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours ц $remainingMinutes мин';
  }

  double _estimateDistanceMeters(List<LatLng> points) {
    const distance = Distance();
    var total = 0.0;

    for (var index = 1; index < points.length; index++) {
      total += distance.as(LengthUnit.Meter, points[index - 1], points[index]);
    }

    return total;
  }

  double _estimateDurationSeconds(double distanceMeters, String profile) {
    final metersPerSecond = switch (profile) {
      'driving' => 11.1,
      'foot' => 1.4,
      'bike' => 4.1,
      _ => 8.3,
    };

    return distanceMeters / metersPerSecond;
  }

  List<RoutePath> _normalizeRoutesForPolicy(
    List<RoutePath> routes,
    _RoutingPolicy routingPolicy,
  ) {
    return routes
        .map((route) => _normalizeRouteForPolicy(route, routingPolicy))
        .toList();
  }

  RoutePath _normalizeRouteForPolicy(
    RoutePath route,
    _RoutingPolicy routingPolicy,
  ) {
    if (routingPolicy.priority != _RoutePriority.fastestWalk &&
        routingPolicy.priority != _RoutePriority.accessibleSafe) {
      return route;
    }

    final minimumDuration =
        route.distanceMeters /
        (routingPolicy.priority == _RoutePriority.accessibleSafe ? 1.15 : 1.4);
    final normalizedDuration = math.max(route.durationSeconds, minimumDuration);

    return RoutePath(
      points: route.points,
      distanceMeters: route.distanceMeters,
      durationSeconds: normalizedDuration,
    );
  }

  List<RoutePath> _sortRoutesForPolicy(
    List<RoutePath> routes,
    _RoutingPolicy routingPolicy,
  ) {
    final sortedRoutes = List<RoutePath>.from(routes);
    sortedRoutes.sort(
      (a, b) => _routeScore(
        a,
        routingPolicy,
      ).compareTo(_routeScore(b, routingPolicy)),
    );
    return sortedRoutes;
  }

  double _routeScore(RoutePath route, _RoutingPolicy routingPolicy) {
    final turnPenalty = _turnPenalty(route.points);

    return switch (routingPolicy.priority) {
      _RoutePriority.shortest => route.distanceMeters,
      _RoutePriority.roadLegal =>
        (route.durationSeconds * 0.65) + (route.distanceMeters * 0.35),
      _RoutePriority.fastestWalk => route.durationSeconds,
      _RoutePriority.accessibleSafe =>
        (route.distanceMeters * 0.5) +
            (route.durationSeconds * 0.25) +
            (turnPenalty * 220),
    };
  }

  double _turnPenalty(List<LatLng> points) {
    if (points.length < 3) {
      return 0;
    }

    var totalPenalty = 0.0;

    for (var index = 1; index < points.length - 1; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final next = points[index + 1];

      final angleA = math.atan2(
        current.latitude - previous.latitude,
        current.longitude - previous.longitude,
      );
      final angleB = math.atan2(
        next.latitude - current.latitude,
        next.longitude - current.longitude,
      );

      var delta = (angleB - angleA).abs();
      if (delta > math.pi) {
        delta = (2 * math.pi) - delta;
      }

      totalPenalty += delta;
    }

    return totalPenalty;
  }

  String _bestRouteLabel(_RoutingPolicy routingPolicy) {
    return switch (routingPolicy.priority) {
      _RoutePriority.shortest => 'Хамгийн товч',
      _RoutePriority.roadLegal => 'Дүрмийн дагуух авто зам',
      _RoutePriority.fastestWalk => 'Хамгийн хурдан явган зам',
      _RoutePriority.accessibleSafe => 'Хамгийн safe, товч зам',
    };
  }

  String _policyDescription(_RouteOption option, _RoutingPolicy routingPolicy) {
    return switch (routingPolicy.priority) {
      _RoutePriority.shortest => option.description,
      _RoutePriority.roadLegal =>
        'Машинтай хэрэглэгчид зориулж авто зам, уулзварын дүрэм дагасан чиглэл сонголоо.',
      _RoutePriority.fastestWalk =>
        'Явган хэрэглэгчид зориулж дундын явган хэсэг, гэр хорооллын shortcut боломжийг ашигласан хамгийн хурдан чиглэлийг сонголоо.',
      _RoutePriority.accessibleSafe =>
        'Хөгжлийн бэрхшээлтэй хэрэглэгчид зориулж илүү аюулгүй, бага эргэлттэй, товч чиглэлийг түрүүлж эрэмбэллээ.',
    };
  }

  Widget _locationSummaryRow({
    required IconData icon,
    required Color color,
    required String label,
    required LatLng point,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
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
    required this.primaryFallbackWaypoints,
    this.alternativeFallbackWaypoints = const [],
  });

  final Color color;
  final String description;
  final String profile;
  final List<_RouteWaypointSpec> primaryFallbackWaypoints;
  final List<List<_RouteWaypointSpec>> alternativeFallbackWaypoints;
}

class _RoutingPolicy {
  const _RoutingPolicy({required this.profile, required this.priority});

  final String profile;
  final _RoutePriority priority;
}

enum _RoutePriority { shortest, roadLegal, fastestWalk, accessibleSafe }

enum _MapEditTarget { current, destination }

class _RouteWaypointSpec {
  const _RouteWaypointSpec(this.progress, this.lateral);

  final double progress;
  final double lateral;
}
