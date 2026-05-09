import 'dart:async';
import 'dart:ui';

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
  List<LatLng> _recordedPoints = const [];
  List<double> _recordedElevations = const [];
  bool _isUsingLiveLocation = false;
  bool _isInitializingLocation = true;
  bool _hasCustomDestination = false;
  bool _journeyStarted = false;
  bool _isTracking = false;
  bool _isSavingTrack = false;
  bool _showTrafficOverlay = true;
  bool _isTrafficLoading = false;
  bool _isRouteLoading = false;
  DateTime? _trackStartedAt;
  StreamSubscription<Position>? _locationSubscription;
  List<_TrafficHotspot> _trafficHotspots = const [];
  List<Polyline> _savedTrackPolylines = const [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadTrafficApproximation();
    _loadSavedTracks();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
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

  Future<void> _loadSavedTracks() async {
    try {
      final routes = await BackendService.getRoutes();
      if (!mounted) {
        return;
      }

      final polylines = routes
          .map((route) {
            final rawPoints = route['polyline'];
            if (rawPoints is! List) {
              return null;
            }

            final points = rawPoints
                .whereType<Map<String, dynamic>>()
                .map(
                  (point) => LatLng(
                    (point['lat'] as num).toDouble(),
                    (point['lng'] as num).toDouble(),
                  ),
                )
                .toList();

            if (points.length < 2) {
              return null;
            }

            final mode = route['transportMode'] as String? ?? '';
            return Polyline(
              points: points,
              strokeWidth: mode == 'wheelchair' ? 4 : 3,
              color: _savedTrackColor(mode),
            );
          })
          .whereType<Polyline>()
          .toList();

      setState(() {
        _savedTrackPolylines = polylines;
      });
    } catch (_) {}
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

  Future<void> _startJourney() async {
    setState(() {
      _journeyStarted = true;
      _isRouteLoading = true;
      _recordedPoints = [_currentLocation];
      _recordedElevations = const [0];
      _trackStartedAt = DateTime.now();
    });

    await _loadSelectedRoute();
    await _startLiveTracking();
  }

  void _cancelJourney() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    setState(() {
      _journeyStarted = false;
      _isTracking = false;
      _isSavingTrack = false;
      _isRouteLoading = false;
      _activeRoutePoints = const [];
      _recordedPoints = const [];
      _recordedElevations = const [];
      _trackStartedAt = null;
    });
  }

  Future<void> _startLiveTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 8,
          ),
        ).listen((position) {
          if (!mounted || !_journeyStarted) {
            return;
          }

          final nextPoint = LatLng(position.latitude, position.longitude);
          final shouldAppend =
              _recordedPoints.isEmpty ||
              const Distance().distance(_recordedPoints.last, nextPoint) >= 5;

          setState(() {
            _currentLocation = nextPoint;
            _isUsingLiveLocation = true;
            _isTracking = true;
            _locationError = null;
            if (shouldAppend) {
              _recordedPoints = [..._recordedPoints, nextPoint];
              _recordedElevations = [..._recordedElevations, position.altitude];
            }
          });
        });
  }

  Future<void> _finishJourney() async {
    final points = List<LatLng>.from(_recordedPoints);
    final elevations = List<double>.from(_recordedElevations);
    final startedAt = _trackStartedAt;

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    if (startedAt == null || points.length < 2) {
      if (!mounted) {
        return;
      }
      setState(() {
        _journeyStarted = false;
        _isTracking = false;
        _activeRoutePoints = const [];
        _recordedPoints = const [];
        _recordedElevations = const [];
        _trackStartedAt = null;
      });
      return;
    }

    setState(() {
      _isSavingTrack = true;
    });

    try {
      await BackendService.saveRoute(
        points: points,
        elevations: elevations,
        mode: 'driving-shortest',
        startTime: startedAt,
        endTime: DateTime.now(),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Явсан маршрут backend руу хадгалагдлаа')),
      );
      await _loadSavedTracks();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _journeyStarted = false;
          _isTracking = false;
          _isSavingTrack = false;
          _activeRoutePoints = const [];
          _recordedPoints = const [];
          _recordedElevations = const [];
          _trackStartedAt = null;
        });
      }
    }
  }

  Future<void> _loadSelectedRoute() async {
    final distance = const Distance().distance(
      _currentLocation,
      _destinationLocation,
    );
    if (distance < 25) {
      setState(() {
        _journeyStarted = false;
        _isRouteLoading = false;
        _activeRoutePoints = const [];
      });
      return;
    }

    final route = _buildRouteOption();
    setState(() {
      _activeRoutePoints = route.fallbackPoints;
    });

    try {
      final routes = await RoutingService.fetchRoutes(
        start: _currentLocation,
        end: _destinationLocation,
        profile: route.profile,
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
        _isRouteLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _buildRouteOption();
    final directDistanceKm =
        const Distance().distance(_currentLocation, _destinationLocation) /
        1000;

    return Scaffold(
      backgroundColor: AppColors.canvas,
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
              if (_savedTrackPolylines.isNotEmpty)
                PolylineLayer(polylines: _savedTrackPolylines),
              if (_journeyStarted && _activeRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _activeRoutePoints,
                      strokeWidth: 8,
                      borderStrokeWidth: 5,
                      color: AppColors.mapRoute,
                      borderColor: Colors.white.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              if (_journeyStarted && _recordedPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _recordedPoints,
                      strokeWidth: 6,
                      borderStrokeWidth: 2,
                      color: AppColors.accent,
                      borderColor: Colors.white.withValues(alpha: 0.72),
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
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.18, 0.62, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          if (!_journeyStarted)
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 54),
                  child: _buildDestinationPin(),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(children: [_buildTopChrome(), const Spacer()]),
            ),
          ),
          if (_journeyStarted && _isTracking)
            Positioned(
              top: 124,
              right: 16,
              child: SafeArea(
                child: _GlassChrome(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LiveDot(),
                      SizedBox(width: 8),
                      Text(
                        'Live track бичиж байна',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 330,
            child: Column(
              children: [
                _FloatingRoundButton(
                  icon: Icons.my_location_rounded,
                  active: _isUsingLiveLocation,
                  onTap: _recenterToCurrentLocation,
                ),
                const SizedBox(height: 10),
                MapZoomControls(
                  onZoomIn: () => _adjustZoom(1),
                  onZoomOut: () => _adjustZoom(-1),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.22,
            maxChildSize: 0.58,
            snap: true,
            snapSizes: const [0.28, 0.58],
            builder: (context, controller) {
              return _buildBottomSheet(
                controller: controller,
                route: route,
                directDistanceKm: directDistanceKm,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopChrome() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GlassChrome(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.near_me_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UBCab',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _journeyStarted
                                ? (_isTracking
                                      ? 'Tracking your live movement'
                                      : 'Preparing trip tracking')
                                : 'Choose destination with the center pin',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusPill(
                icon: _journeyStarted
                    ? Icons.trip_origin_rounded
                    : Icons.route_outlined,
                label: _journeyStarted
                    ? (_isTracking ? 'Live track идэвхтэй' : 'Trip эхэлж байна')
                    : 'Очих цэгээ тааруулж байна',
              ),
            ),
            const SizedBox(width: 10),
            _StatusPill(
              icon: Icons.traffic_rounded,
              label: _isTrafficLoading ? 'Traffic...' : 'Traffic overlay',
              trailing: Switch.adaptive(
                value: _showTrafficOverlay,
                onChanged: (value) {
                  setState(() {
                    _showTrafficOverlay = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSheet({
    required ScrollController controller,
    required _RouteOption route,
    required double directDistanceKm,
  }) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _journeyStarted
                                ? 'Аялал эхэлсэн'
                                : 'Очих газраа сонго',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _journeyStarted
                                ? 'Явсан зам чинь бодитоор бичигдэж байна. Дуусахад backend руу хадгална.'
                                : 'Map-ийг хөдөлгөж center pin-ээ тааруулаад дөт замын аяллаа эхлүүлнэ.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.navigation_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _LocationCard(
                  icon: Icons.radio_button_checked_rounded,
                  iconColor: AppColors.primary,
                  label: 'Эхлэх',
                  value: _locationLabel(_currentLocation),
                  helper: _isUsingLiveLocation
                      ? 'Live location'
                      : 'Simulator эсвэл fallback байршил',
                ),
                const SizedBox(height: 12),
                _LocationCard(
                  icon: Icons.place_rounded,
                  iconColor: AppColors.accent,
                  label: 'Очих',
                  value: _locationLabel(_destinationLocation),
                  helper: _journeyStarted
                      ? 'Selected destination'
                      : 'Center pin-ээр сонгогдоно',
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.alt_route_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Дөт зам',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  route.description,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${directDistanceKm.toStringAsFixed(1)} км',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SheetStat(
                              label: 'Route mode',
                              value: 'Shortest',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetStat(
                              label: 'Tracking',
                              value: _journeyStarted
                                  ? (_isTracking ? 'Live' : 'Starting')
                                  : 'Idle',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetStat(
                              label: 'Traffic',
                              value: _showTrafficOverlay ? 'On' : 'Off',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_locationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE7E5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _locationError!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _journeyStarted
                      ? Column(
                          key: const ValueKey('journey-started'),
                          children: [
                            FilledButton(
                              onPressed: _isRouteLoading || _isSavingTrack
                                  ? null
                                  : _finishJourney,
                              child: Text(
                                _isSavingTrack
                                    ? 'Маршрут хадгалж байна...'
                                    : _isRouteLoading
                                    ? 'Маршрут тооцоолж байна...'
                                    : 'Аяллыг дуусгах',
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isSavingTrack
                                    ? null
                                    : _cancelJourney,
                                child: const Text('Хадгалахгүйгээр цуцлах'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.visibility_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isSavingTrack
                                        ? 'GPS track-ийг backend руу хадгалж байна.'
                                        : _isRouteLoading
                                        ? 'Дотоод гудамж түлхүү ашиглах маршрутыг хайж байна.'
                                        : 'Хар route нь зөвлөсөн зам, ногоон route нь таны бодитоор явсан мөр.',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('journey-ready'),
                          children: [
                            FilledButton(
                              onPressed: _startJourney,
                              child: const Text('Аяллаа эхлүүлэх'),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(
                                  Icons.pan_tool_alt_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Map-ийг хөдөлгөхөд destination шинэчлэгдэнэ. Journey эхэлсний дараа live track автоматаар бичигдэнэ.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
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
    );
  }

  Widget _buildLocationDot() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.place_rounded,
            color: AppColors.primary,
            size: 34,
          ),
        ),
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }

  _RouteOption _buildRouteOption() {
    return _RouteOption(
      description:
          'Төв замын урсгалд түгжигдэхээс илүү жижиг автомашин замыг давуу үзнэ.',
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
            color: spot.color.withValues(alpha: 0.16),
            borderColor: spot.color.withValues(alpha: 0.72),
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

  Color _savedTrackColor(String mode) {
    switch (mode) {
      case 'wheelchair':
        return const Color(0xFF7E57C2).withValues(alpha: 0.48);
      case 'foot':
      case 'walk':
        return AppColors.success.withValues(alpha: 0.36);
      case 'heavy':
        return AppColors.warning.withValues(alpha: 0.38);
      default:
        return AppColors.routeBlue.withValues(alpha: 0.22);
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

  String _locationLabel(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }
}

class _RouteOption {
  const _RouteOption({
    required this.description,
    required this.profile,
    required this.fallbackPoints,
  });

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

class _FloatingRoundButton extends StatelessWidget {
  const _FloatingRoundButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? AppColors.primary : AppColors.muted,
        ),
      ),
    );
  }
}

class _GlassChrome extends StatelessWidget {
  const _GlassChrome({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _GlassChrome(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  helper,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  const _SheetStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
