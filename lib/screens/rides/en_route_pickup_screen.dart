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

class EnRoutePickupScreen extends StatefulWidget {
  const EnRoutePickupScreen({super.key});

  @override
  State<EnRoutePickupScreen> createState() => _EnRoutePickupScreenState();
}

class _EnRoutePickupScreenState extends State<EnRoutePickupScreen> {
  String? _rideId;
  Ride? _ride;

  // Route and map related
  final MapController _mapController = MapController();
  final loc.Location _location = loc.Location();
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  Timer? _locationTimer;

  // Route info
  double _routeDistanceKm = 0;
  double _routeDurationMin = 0;
  String? _currentInstruction;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });

      // Calculate route if we have pickup location
      if (_pickupLocation != null) {
        await _calculateRoute();
      }

      // Update location every 3 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final locationData = await _location.getLocation();
          setState(() {
            _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
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
      if (_ride != null && _ride!.pickupLat != null && _ride!.pickupLng != null) {
        _pickupLocation = LatLng(_ride!.pickupLat!, _ride!.pickupLng!);
      }
    });

    // Calculate route if we have both current location and pickup
    if (_currentLocation != null && _pickupLocation != null) {
      await _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _pickupLocation == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final response = await ApiService.getRoute(
        startLat: _currentLocation!.latitude,
        startLng: _currentLocation!.longitude,
        endLat: _pickupLocation!.latitude,
        endLng: _pickupLocation!.longitude,
      );

      if (response['code'] == 'Ok' && response['routes'] != null) {
        final routes = response['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];

          // Parse geometry
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
        return 'You have arrived at pickup';
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

  Future<void> _arrivedAtPickup() async {
    if (_rideId == null) return;
    try {
      await context.read<RideProvider>().startRide(_rideId!);
      Navigator.pushReplacementNamed(context, '/passenger-pickup', arguments: {'rideId': _rideId});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLocation ?? _pickupLocation ?? LatLng(-1.2864, 36.8172);

    return Scaffold(
      body: Stack(
        children: [
          // Map with route
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: center,
              zoom: 15.0,
              maxZoom: 18.0,
              minZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tiles.locationiq.com/v3/streets/r/{z}/{x}/{y}.png?key=pk.48e2dedac41ff32af8621c2414ee25e8',
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
                  if (_pickupLocation != null)
                    Marker(
                      point: _pickupLocation!,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
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
                            '${_routeDistanceKm.toStringAsFixed(1)} km • ${_routeDurationMin.round()} min to pickup',
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

          // Passenger info card
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
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Picking up ${_ride?.rider?.fullName ?? 'Passenger'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${_ride?.pickupAddress ?? 'Pickup Location'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async => _rideId != null
                        ? await ChatCallService.initiateCall(context: context, rideId: int.parse(_rideId!))
                        : null,
                    icon: const Icon(Icons.phone, color: Color(0xFF0066CC)),
                  ),
                  IconButton(
                    onPressed: () async => _rideId != null
                        ? await ChatCallService.openChat(
                            context: context,
                            rideId: int.parse(_rideId!),
                            passengerName: _ride?.rider?.fullName ?? "Passenger",
                          )
                        : null,
                    icon: const Icon(Icons.message, color: Color(0xFF0066CC)),
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
                  const Text(
                    'En route to pickup',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Follow navigation to reach passenger',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Distance to pickup'),
                            Text(
                              '${_routeDistanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ETA'),
                            Text(
                              '${_routeDurationMin.round()} min',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated fare'),
                            Text(
                              '\$${_ride?.fare?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0066CC),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _arrivedAtPickup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Arrived at Pickup',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
}