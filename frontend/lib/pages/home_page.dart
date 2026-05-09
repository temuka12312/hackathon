import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../api/backend_service.dart';
import '../api/routing_service.dart';
import '../models/report_item.dart';
import '../theme/app_colors.dart';
import '../widgets/map_zoom_controls.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const LatLng _defaultLocation = LatLng(47.9184, 106.9177);
  static const List<double> _defaultDestinationOffset = [0.012, 0.02];
  static const double _minZoom = 5;
  static const double _maxZoom = 18;
  static const double _defaultZoom = 14.5;

  final MapController _mapController = MapController();

  late LatLng _currentLocation = _defaultLocation;
  late LatLng _destinationLocation = _offsetDestination(_defaultLocation);
  late LatLng _mapCenter = _destinationLocation;
  String? _locationError;
  List<LatLng> _activeRoutePoints = const [];
  bool _isUsingLiveLocation = false;
  bool _isInitializingLocation = true;
  bool _hasCustomDestination = false;
  bool _journeyStarted = false;
  bool _showTrafficOverlay = true;
  bool _isTrafficLoading = false;
  List<_TrafficHotspot> _trafficHotspots = const [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadTrafficApproximation();
  }

  Future<void> _initializeLocation() async {
    await _syncCurrentLocation(allowPermissionPrompt: true, recenterMap: true);
    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializingLocation = false;
    });
  }

  Future<void> _syncCurrentLocation({
    required bool allowPermissionPrompt,
    required bool recenterMap,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUsingLiveLocation = false;
        _locationError = 'Location service унтраалттай байна.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && allowPermissionPrompt) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUsingLiveLocation = false;
        _locationError = 'Location permission зөвшөөрөөгүй байна.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUsingLiveLocation = false;
        _locationError =
            'Location permission бүрмөсөн хаалттай байна. Settings-ээс зөвшөөрнө үү.';
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }

      final nextCurrent = LatLng(position.latitude, position.longitude);
      final nextDestination = _hasCustomDestination
          ? _destinationLocation
          : _offsetDestination(nextCurrent);
      final nextCenter = recenterMap
          ? nextCurrent
          : (_hasCustomDestination ? _mapCenter : nextDestination);

      setState(() {
        _currentLocation = nextCurrent;
        _destinationLocation = nextDestination;
        _mapCenter = nextCenter;
        _isUsingLiveLocation = true;
        _locationError = null;
      });

      if (recenterMap) {
        _mapController.move(nextCurrent, _defaultZoom);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUsingLiveLocation = false;
        _locationError = 'Таны байршлыг авч чадсангүй.';
      });
    }
  }

  Future<void> _loadTrafficApproximation() async {
    setState(() {
      _isTrafficLoading = true;
    });

    try {
      final reports = await BackendService.fetchReports();
      if (!mounted) {
        return;
      }

      final hotspots = _buildTrafficHotspots(reports);
      setState(() {
        _trafficHotspots = hotspots.isNotEmpty ? hotspots : _fallbackHotspots();
        _isTrafficLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _trafficHotspots = _fallbackHotspots();
        _isTrafficLoading = false;
      });
    }
  }

  void _adjustZoom(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, nextZoom);
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    _mapCenter = camera.center;
    if (!hasGesture || _isInitializingLocation || _journeyStarted) {
      return;
    }

    if (const Distance().distance(_destinationLocation, camera.center) < 5) {
      return;
    }

    setState(() {
      _hasCustomDestination = true;
      _destinationLocation = camera.center;
      _activeRoutePoints = const [];
    });
  }

  Future<void> _recenterToCurrentLocation() async {
    await _syncCurrentLocation(allowPermissionPrompt: true, recenterMap: false);
    if (!mounted) {
      return;
    }

    _mapCenter = _currentLocation;
    _mapController.move(_currentLocation, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final activeRoute = _buildRouteOption();

    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _defaultZoom,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.frontend',
              ),
              if (_showTrafficOverlay)
                CircleLayer(circles: _buildTrafficCircles()),
              if (_journeyStarted && _activeRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _activeRoutePoints,
                      strokeWidth: 7,
                      borderStrokeWidth: 2,
                      color: AppColors.mapRoute,
                      borderColor: Colors.white.withValues(alpha: 0.92),
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
                ],
              ),
            ],
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                    AppColors.mapSand.withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          if (!_journeyStarted)
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 52),
                  child: _buildDestinationPin(activeRoute.color),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  _buildTrafficBanner(),
                  const Spacer(),
                  const SizedBox(height: 260),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 276,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _recenterToCurrentLocation,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.mapGlow.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: _isUsingLiveLocation
                          ? AppColors.mapInk
                          : AppColors.mapInk.withValues(alpha: 0.45),
                      size: 20,
                    ),
                  ),
                ),
                MapZoomControls(
                  onZoomIn: () => _adjustZoom(1),
                  onZoomOut: () => _adjustZoom(-1),
                ),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildTrafficBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.mapMint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.traffic_rounded, color: AppColors.mapInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Түгжрэлийн ойролцоо зураглал',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _isTrafficLoading
                      ? 'Замын ачааллын мэдээлэл уншиж байна...'
                      : 'Traffic, accident, blocked-road report дээр тулгуурласан үнэгүй approximation.',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _showTrafficOverlay,
            onChanged: (value) {
              setState(() {
                _showTrafficOverlay = value;
              });
            },
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
              if (_journeyStarted) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelJourney,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mapInk,
                      side: BorderSide(
                        color: AppColors.mapInk.withValues(alpha: 0.18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.72),
                    ),
                    child: const Text(
                      'Цуцлаад шинэ чиглэл оруулах',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mapRoute.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.mapRoute.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.alt_route_rounded, color: AppColors.mapRoute),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Үргэлж дөт замаар тооцоолж байна',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _startJourney,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Аяллаа эхлүүлэх',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Очих газраа pin-ээр тааруулаад дараа нь аяллаа эхлүүлнэ.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.stacked_line_chart_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _locationError == null
                          ? (_showTrafficOverlay
                                ? 'Approx traffic overlay идэвхтэй'
                                : 'Traffic overlay унтраалттай')
                          : _locationError!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _journeyStarted ? 'Дөт зам идэвхтэй' : 'Очих цэг сонгосон',
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

  Widget _buildLocationDot() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mapInk,
        border: Border.all(color: AppColors.mapGlow, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.mapMint.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationPin(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.mapGlow,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.place_rounded, color: color, size: 32),
        ),
        Container(width: 4, height: 20, color: color.withValues(alpha: 0.45)),
      ],
    );
  }

  Future<void> _startJourney() async {
    setState(() {
      _journeyStarted = true;
    });

    await _loadSelectedRoute();
  }

  void _cancelJourney() {
    setState(() {
      _journeyStarted = false;
      _activeRoutePoints = const [];
    });
  }

  Future<void> _loadSelectedRoute() async {
    final distance = const Distance().distance(
      _currentLocation,
      _destinationLocation,
    );
    if (distance < 25) {
      setState(() {
        _journeyStarted = false;
        _activeRoutePoints = const [];
      });
      return;
    }

    final activeRoute = _buildRouteOption();
    final fallbackPoints = activeRoute.fallbackPoints;

    setState(() {
      _activeRoutePoints = fallbackPoints;
    });

    try {
      final routes = await RoutingService.fetchRoutes(
        start: _currentLocation,
        end: _destinationLocation,
        profile: activeRoute.profile,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeRoutePoints = routes.first.points;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeRoutePoints = fallbackPoints;
      });
    }
  }

  _RouteOption _buildRouteOption() {
    return _RouteOption(
      color: AppColors.mapRoute,
      description: 'Төв замын ачааллыг тойрч, жижиг гудамжтай богино чиглэл.',
      profile: 'driving-shortest',
      fallbackPoints: _buildFallbackRoute(const [
        [0.00, 0.00],
        [0.14, 0.20],
        [0.33, 0.44],
        [0.58, 0.76],
        [1.00, 1.00],
      ]),
    );
  }

  List<LatLng> _buildFallbackRoute(List<List<double>> fractions) {
    return fractions
        .map(
          (fraction) => LatLng(
            _currentLocation.latitude +
                ((_destinationLocation.latitude - _currentLocation.latitude) *
                    fraction[0]),
            _currentLocation.longitude +
                ((_destinationLocation.longitude - _currentLocation.longitude) *
                    fraction[1]),
          ),
        )
        .toList();
  }

  List<CircleMarker> _buildTrafficCircles() {
    return _trafficHotspots
        .map(
          (spot) => CircleMarker(
            point: spot.point,
            radius: spot.radius,
            color: spot.color.withValues(alpha: 0.20),
            borderColor: spot.color,
            borderStrokeWidth: 2,
          ),
        )
        .toList();
  }

  List<_TrafficHotspot> _buildTrafficHotspots(List<ReportItem> reports) {
    final hotspots = reports
        .where((report) => report.latitude != 0 && report.longitude != 0)
        .map(
          (report) => _TrafficHotspot(
            point: LatLng(report.latitude, report.longitude),
            color: _trafficColor(report.type),
            radius: _trafficRadius(report.type),
          ),
        )
        .toList();

    return hotspots.take(12).toList();
  }

  List<_TrafficHotspot> _fallbackHotspots() {
    return const [
      _TrafficHotspot(
        point: LatLng(47.9199, 106.9175),
        color: Colors.green,
        radius: 28,
      ),
      _TrafficHotspot(
        point: LatLng(47.9238, 106.9227),
        color: Color(0xFFF39C12),
        radius: 34,
      ),
      _TrafficHotspot(
        point: LatLng(47.9165, 106.9318),
        color: Colors.red,
        radius: 38,
      ),
      _TrafficHotspot(
        point: LatLng(47.9267, 106.9354),
        color: Color(0xFF7A0019),
        radius: 44,
      ),
    ];
  }

  Color _trafficColor(String type) {
    switch (type) {
      case 'blocked-road':
        return const Color(0xFF7A0019);
      case 'accident':
        return Colors.red;
      case 'traffic':
        return const Color(0xFFF39C12);
      case 'pothole':
      default:
        return Colors.green;
    }
  }

  double _trafficRadius(String type) {
    switch (type) {
      case 'blocked-road':
        return 44;
      case 'accident':
        return 38;
      case 'traffic':
        return 34;
      case 'pothole':
      default:
        return 28;
    }
  }

  LatLng _offsetDestination(LatLng location) {
    return LatLng(
      location.latitude + _defaultDestinationOffset[0],
      location.longitude + _defaultDestinationOffset[1],
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

class _TrafficHotspot {
  const _TrafficHotspot({
    required this.point,
    required this.color,
    required this.radius,
  });

  final LatLng point;
  final Color color;
  final double radius;
}
