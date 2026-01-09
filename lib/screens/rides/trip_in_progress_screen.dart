import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import '../../data/providers/ride_provider.dart';
import '../../data/models/models.dart';
import '../../data/services/chat_call_service.dart';
import '../../data/services/api_service.dart';
import '../../widgets/rating_popup.dart';

class TripInProgressScreen extends StatefulWidget {
  const TripInProgressScreen({super.key});

  @override
  State<TripInProgressScreen> createState() => _TripInProgressScreenState();
}

class _TripInProgressScreenState extends State<TripInProgressScreen> {
  String? _rideId;
  Ride? _ride;
  String _tripTime = '0:00';
  String _distance = '0.0 km';

  // Route and map related
  final MapController _mapController = MapController();
  final loc.Location _location = loc.Location();
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  LatLng? _dropoffLocation;
  Timer? _locationTimer;
  Timer? _tripTimer;
  int _tripSeconds = 0;

  // Route info
  double _routeDistanceKm = 0;
  double _routeDurationMin = 0;
  String? _currentInstruction;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['rideId'] != null) {
        _rideId = args['rideId'];
        _loadRideDetails();
      }
    });
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _tripTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationUpdates() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return;
      }

      // Get initial location
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
      });

      // Calculate route with current location
      if (_dropoffLocation != null) {
        await _calculateRoute();
      }

      // Update location every 3 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final locationData = await _location.getLocation();
          setState(() {
            _currentLocation =
                LatLng(locationData.latitude!, locationData.longitude!);
          });

          // Update driver location to server
          await ApiService.updateDriverLocation(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!,
            heading: locationData.heading,
            speed: locationData.speed,
          );
        } catch (e) {
          debugPrint('Error updating location: $e');
        }
      });
    } catch (e) {
      debugPrint('Error starting location updates: $e');
    }
  }

  Future<void> _loadRideDetails() async {
    if (_rideId == null) return;
    final rideProvider = context.read<RideProvider>();
    await rideProvider.getRideById(_rideId!);

    setState(() {
      _ride = rideProvider.currentRide;
      if (_ride != null &&
          _ride!.dropoffLat != null &&
          _ride!.dropoffLng != null) {
        _dropoffLocation = LatLng(_ride!.dropoffLat!, _ride!.dropoffLng!);
      }
    });

    // Calculate route if we have both current location and dropoff
    if (_currentLocation != null && _dropoffLocation != null) {
      await _calculateRoute();
    }

    _startTripTimer();
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _dropoffLocation == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final response = await ApiService.getRoute(
        startLat: _currentLocation!.latitude,
        startLng: _currentLocation!.longitude,
        endLat: _dropoffLocation!.latitude,
        endLng: _dropoffLocation!.longitude,
      );

      if (response['code'] == 'Ok' && response['routes'] != null) {
        final routes = response['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];

          // Parse geometry (GeoJSON coordinates)
          final geometry = route['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            setState(() {
              _routePoints = coordinates.map<LatLng>((coord) {
                return LatLng(coord[1].toDouble(), coord[0].toDouble());
              }).toList();
            });
          }

          // Parse distance and duration
          setState(() {
            _routeDistanceKm = (route['distance'] ?? 0) / 1000;
            _routeDurationMin = (route['duration'] ?? 0) / 60;
            _distance = '${_routeDistanceKm.toStringAsFixed(1)} km';
          });

          // Get first step instruction
          final legs = route['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            final steps = legs[0]['steps'] as List?;
            if (steps != null && steps.isNotEmpty) {
              setState(() {
                _currentInstruction = _buildInstruction(steps[0]);
              });
            }
          }

          // Fit map to show route
          _fitMapToRoute();
        }
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  String _buildInstruction(Map<String, dynamic> step) {
    final maneuver = step['maneuver'];
    if (maneuver == null) return 'Continue';

    final type = maneuver['type'] ?? '';
    final modifier = maneuver['modifier'] ?? '';
    final name = step['name'] ?? 'the road';

    switch (type) {
      case 'turn':
        return 'Turn $modifier onto $name';
      case 'new name':
        return 'Continue onto $name';
      case 'arrive':
        return 'You have arrived';
      case 'depart':
        return 'Head $modifier on $name';
      default:
        return 'Continue on $name';
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isEmpty) return;

    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLng = _routePoints[0].longitude;
    double maxLng = _routePoints[0].longitude;

    for (final point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    _mapController.fitBounds(
      LatLngBounds(
        LatLng(minLat - latPadding, minLng - lngPadding),
        LatLng(maxLat + latPadding, maxLng + lngPadding),
      ),
      options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
    );
  }

  void _startTripTimer() {
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _tripSeconds++;
        final minutes = _tripSeconds ~/ 60;
        final seconds = _tripSeconds % 60;
        _tripTime = '$minutes:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  Future<void> _completeTrip() async {
    if (_rideId == null) return;
    try {
      await context.read<RideProvider>().completeRide(_rideId!);

      // Show rating popup
      if (mounted) {
        await RatingPopup.show(
          context,
          rideId: int.parse(_rideId!),
          partnerName: _ride?.rider?.fullName ?? 'Passenger',
          isDriver: true,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/ride-complete',
            arguments: {'rideId': _rideId},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLocation ??
        (_ride?.pickupLat != null && _ride?.dropoffLat != null
            ? LatLng(
                ((_ride!.pickupLat!) + (_ride!.dropoffLat!)) / 2,
                ((_ride!.pickupLng!) + (_ride!.dropoffLng!)) / 2,
              )
            : LatLng(-1.2864, 36.8172));

    return Scaffold(
      body: Stack(
        children: [
          // Map with route
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: center,
              zoom: 14.0,
              maxZoom: 18.0,
              minZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tiles.locationiq.com/v3/streets/r/{z}/{x}/{y}.png?key=pk.48e2dedac41ff32af8621c2414ee25e8',
                userAgentPackageName: 'com.kva.driver',
              ),

              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF0066CC),
                      strokeWidth: 5,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Current location (driver)
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0066CC),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                  // Pickup location
                  if (_ride?.pickupLat != null && _ride?.pickupLng != null)
                    Marker(
                      point: LatLng(_ride!.pickupLat!, _ride!.pickupLng!),
                      child: const Icon(
                        Icons.radio_button_checked,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),

                  // Destination
                  if (_dropoffLocation != null)
                    Marker(
                      point: _dropoffLocation!,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Navigation instruction card (top)
          if (_currentInstruction != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066CC),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentInstruction!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_routeDistanceKm.toStringAsFixed(1)} km • ${_routeDurationMin.round()} min remaining',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Trip info card
          SafeArea(
            child: Container(
              margin: EdgeInsets.only(
                top: _currentInstruction != null ? 90 : 16,
                left: 16,
                right: 16,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(Icons.access_time, _tripTime, 'Time'),
                  _buildInfoItem(Icons.straighten, _distance, 'Distance'),
                  _buildInfoItem(
                    Icons.attach_money,
                    '\$${_ride?.fare?.toStringAsFixed(2) ?? '0.00'}',
                    'Fare',
                  ),
                ],
              ),
            ),
          ),

          // Map controls (right side)
          Positioned(
            right: 16,
            bottom: 280,
            child: Column(
              children: [
                // Center on route button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.route),
                    onPressed: _fitMapToRoute,
                    tooltip: 'Show full route',
                  ),
                ),
                const SizedBox(height: 8),
                // Center on location button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: () {
                      if (_currentLocation != null) {
                        _mapController.move(_currentLocation!, 16);
                      }
                    },
                    tooltip: 'My location',
                  ),
                ),
                const SizedBox(height: 8),
                // Recalculate route button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isLoadingRoute
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: _isLoadingRoute ? null : _calculateRoute,
                    tooltip: 'Recalculate route',
                  ),
                ),
              ],
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Trip in progress',
                      style: TextStyle(
                          color: Colors.blue[700], fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          _ride?.rider?.firstName?.isNotEmpty == true
                              ? _ride!.rider!.firstName![0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ride?.rider?.fullName ?? 'Passenger',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Going to ${_ride?.dropoffAddress ?? 'Destination'}',
                              style: const TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async => _rideId != null
                                ? await ChatCallService.initiateCall(
                                    context: context,
                                    rideId: int.parse(_rideId!))
                                : null,
                            icon: const Icon(Icons.phone,
                                color: Color(0xFF0066CC)),
                          ),
                          IconButton(
                            onPressed: () async => _rideId != null
                                ? await ChatCallService.openChat(
                                    context: context,
                                    rideId: int.parse(_rideId!),
                                    passengerName:
                                        _ride?.rider?.fullName ?? "Passenger",
                                  )
                                : null,
                            icon: const Icon(Icons.message,
                                color: Color(0xFF0066CC)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Destination',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text(
                                _ride?.dropoffAddress ?? 'Loading...',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'ETA: ${_routeDurationMin.round()} min',
                          style: const TextStyle(
                              color: Color(0xFF0066CC),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _completeTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Complete Trip',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
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

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0066CC)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
