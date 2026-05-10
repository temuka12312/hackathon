import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../api/backend_service.dart';
import '../api/routing_service.dart';
import '../pages/journey_setup_page.dart';
import '../theme/app_colors.dart';
import '../widgets/map_zoom_controls.dart';

class HomePageController extends ChangeNotifier {
  VoidCallback? _startJourney;
  VoidCallback? _finishJourney;
  bool _journeyStarted = false;
  bool _busy = false;

  bool get journeyStarted => _journeyStarted;
  bool get busy => _busy;

  void bind({
    required VoidCallback onStartJourney,
    required VoidCallback onFinishJourney,
  }) {
    _startJourney = onStartJourney;
    _finishJourney = onFinishJourney;
  }

  void unbind() {
    _startJourney = null;
    _finishJourney = null;
  }

  void updateState({required bool journeyStarted, required bool busy}) {
    if (_journeyStarted == journeyStarted && _busy == busy) {
      return;
    }
    _journeyStarted = journeyStarted;
    _busy = busy;
    notifyListeners();
  }

  void handlePrimaryAction() {
    if (_busy) {
      return;
    }
    if (_journeyStarted) {
      _finishJourney?.call();
    } else {
      _startJourney?.call();
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.controller});

  final HomePageController? controller;

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

  List<LatLng> _activeRoutePoints = const [];
  List<LatLng> _recordedPoints = const [];
  List<double> _recordedElevations = const [];
  bool _isUsingLiveLocation = false;
  bool _isInitializingLocation = true;
  bool _hasCustomDestination = false;
  bool _journeyStarted = false;
  bool _isSavingTrack = false;
  bool _isRouteLoading = false;
  DateTime? _trackStartedAt;
  StreamSubscription<Position>? _locationSubscription;
  List<Polyline> _savedTrackPolylines = const [];
  String _selectedTransportMode = 'driving-shortest';

  @override
  void initState() {
    super.initState();
    widget.controller?.bind(
      onStartJourney: () {
        _openJourneySetupSheet();
      },
      onFinishJourney: () {
        _finishJourney();
      },
    );
    _initializeLocation();
    _loadSavedTracks();
    _syncControllerState();
  }

  @override
  void dispose() {
    widget.controller?.unbind();
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller?.unbind();
    widget.controller?.bind(
      onStartJourney: () {
        _openJourneySetupSheet();
      },
      onFinishJourney: () {
        _finishJourney();
      },
    );
    _syncControllerState();
  }

  String _backendMode(String profile) => switch (profile) {
    'foot-walking' => 'walk',
    'wheelchair' => 'wheelchair',
    'heavy-vehicle' => 'heavy',
    _ => 'car',
  };

  void _syncControllerState() {
    widget.controller?.updateState(
      journeyStarted: _journeyStarted,
      busy: _isRouteLoading || _isSavingTrack,
    );
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
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUsingLiveLocation = false;
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
    _syncControllerState();

    await _loadSelectedRoute();
    await _startLiveTracking();
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
        _activeRoutePoints = const [];
        _recordedPoints = const [];
        _recordedElevations = const [];
        _trackStartedAt = null;
      });
      _syncControllerState();
      return;
    }

    setState(() {
      _isSavingTrack = true;
    });
    _syncControllerState();

    try {
      await BackendService.saveRoute(
        points: points,
        elevations: elevations,
        mode: _backendMode(_selectedTransportMode),
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
          _isSavingTrack = false;
          _activeRoutePoints = const [];
          _recordedPoints = const [];
          _recordedElevations = const [];
          _trackStartedAt = null;
        });
        _syncControllerState();
      }
    }
  }

  Future<void> _openJourneySetupSheet() async {
    if (_journeyStarted || !mounted) {
      return;
    }

    final directDistanceKm =
        const Distance().distance(_currentLocation, _destinationLocation) /
        1000;
    final selectedProfile = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => JourneySetupPage(
          initialProfile: _selectedTransportMode,
          directDistanceKm: directDistanceKm,
        ),
      ),
    );

    if (!mounted || selectedProfile == null) {
      return;
    }

    setState(() {
      _selectedTransportMode = selectedProfile;
    });

    await _startJourney();
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
      _syncControllerState();
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
      _syncControllerState();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRouteLoading = false;
      });
      _syncControllerState();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned(
            right: 16,
            bottom: 126,
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
          if (!_journeyStarted)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: IgnorePointer(
                child: _GlassChrome(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.swipe_up_alt_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Destination сонгоод төв товч дарж төрлөө сонгоно.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_journeyStarted)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _GlassChrome(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  _isSavingTrack
                      ? 'GPS track-ийг backend руу хадгалж байна.'
                      : _isRouteLoading
                      ? 'Маршрут тооцоолж байна.'
                      : 'Хар route нь зөвлөсөн зам, ногоон route нь таны бодитоор явсан мөр.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                                ? 'Trip in progress'
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
                    ? 'Аялал эхэлсэн'
                    : 'Очих цэгээ тааруулж байна',
              ),
            ),
          ],
        ),
      ],
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
    return _routeOptions.firstWhere(
      (option) => option.profile == _selectedTransportMode,
      orElse: () => _routeOptions.first,
    );
  }

  List<_RouteOption> get _routeOptions => [
    _RouteOption(
      label: 'Машин',
      shortStat: 'Car',
      profile: 'driving-car',
      icon: Icons.directions_car_filled_rounded,
      description: 'Ердийн автомашины тэнцвэртэй маршрут сонгоно.',
      fallbackPoints: _buildFallbackRoute(const [
        [0.00, 0.00],
        [0.16, 0.18],
        [0.38, 0.40],
        [0.66, 0.72],
        [1.00, 1.00],
      ]),
    ),
    _RouteOption(
      label: 'Явган',
      shortStat: 'Walk',
      profile: 'foot-walking',
      icon: Icons.directions_walk_rounded,
      description: 'Явган хүний зам, гарц ашигласан алхалтын маршрут.',
      fallbackPoints: _buildFallbackRoute(const [
        [0.00, 0.00],
        [0.20, 0.15],
        [0.42, 0.36],
        [0.72, 0.68],
        [1.00, 1.00],
      ]),
    ),
    _RouteOption(
      label: 'Wheelchair',
      shortStat: 'Access',
      profile: 'wheelchair',
      icon: Icons.accessible_forward_rounded,
      description: 'Налуу, гадаргуу, шатгүй хэсгийг давуу үзнэ.',
      fallbackPoints: _buildFallbackRoute(const [
        [0.00, 0.00],
        [0.15, 0.12],
        [0.36, 0.32],
        [0.64, 0.70],
        [1.00, 1.00],
      ]),
    ),
    _RouteOption(
      label: 'Том машин',
      shortStat: 'HGV',
      profile: 'heavy-vehicle',
      icon: Icons.local_shipping_rounded,
      description: 'Том оврын автомашинд боломжтой замыг баримтална.',
      fallbackPoints: _buildFallbackRoute(const [
        [0.00, 0.00],
        [0.12, 0.24],
        [0.34, 0.48],
        [0.62, 0.78],
        [1.00, 1.00],
      ]),
    ),
    _RouteOption(
      label: 'Хурдан зам',
      shortStat: 'Fast',
      profile: 'taxi-fast',
      icon: Icons.local_taxi_rounded,
      description:
          'Төв зам, гол өргөн урсгалаар хамгийн хурдан хүрэх маршрутыг сонгоно.',
      fallbackPoints: _buildFallbackRoute(const [
        [0.00, 0.00],
        [0.18, 0.26],
        [0.40, 0.52],
        [0.70, 0.84],
        [1.00, 1.00],
      ]),
    ),
    _RouteOption(
      label: 'Дөт зам',
      shortStat: 'Short',
      profile: 'driving-shortest',
      icon: Icons.alt_route_rounded,
      description:
          'Төв замын урсгалд түгжигдэхээс илүү жижиг автомашин замыг давуу үзнэ.',
      fallbackPoints: _buildFallbackRoute(const [
        [0.00, 0.00],
        [0.14, 0.20],
        [0.33, 0.44],
        [0.58, 0.76],
        [1.00, 1.00],
      ]),
    ),
  ];

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

  Color _savedTrackColor(String mode) {
    switch (mode) {
      case 'wheelchair':
        return const Color(0xFF7E57C2).withValues(alpha: 0.48);
      case 'foot-walking':
      case 'foot':
      case 'walk':
        return AppColors.success.withValues(alpha: 0.36);
      case 'heavy':
      case 'heavy-vehicle':
        return AppColors.warning.withValues(alpha: 0.38);
      case 'taxi-fast':
        return const Color(0xFFFFC107).withValues(alpha: 0.42);
      default:
        return AppColors.routeBlue.withValues(alpha: 0.22);
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
    required this.label,
    required this.shortStat,
    required this.description,
    required this.profile,
    required this.icon,
    required this.fallbackPoints,
  });

  final String label;
  final String shortStat;
  final String description;
  final String profile;
  final IconData icon;
  final List<LatLng> fallbackPoints;
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
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
        ],
      ),
    );
  }
}