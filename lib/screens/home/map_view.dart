import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../../data/providers/app_provider.dart';
import '../../data/providers/ride_provider.dart';
import '../../data/services/api_service.dart';
import '../../data/services/driver_location_service.dart';
import '../../data/models/models.dart' as models;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MapController _mapController = MapController();
  LatLng _currentLocation =
      LatLng(-1.2864, 36.8172); // Nairobi coordinates as default
  Location _location = Location();
  bool _locationLoaded = false;
  String _approvalStatus = 'pending';
  bool _statusLoaded = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkDriverStatus();
    // Load pending rides initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingRides();
    });
  }

  Future<void> _checkDriverStatus() async {
    try {
      final response = await ApiService.getDriverStatus();
      print('📋 Driver status response: $response');

      if (response['data'] != null) {
        setState(() {
          _approvalStatus = response['data']['approvalStatus'] ?? 'pending';
          _statusLoaded = true;
        });
      }
    } catch (e) {
      print('🔴 Error checking driver status: $e');
      // If error, assume pending (driver might not be registered yet)
      setState(() {
        _approvalStatus = 'pending';
        _statusLoaded = true;
      });
    }
  }

  void _loadPendingRides() {
    final rideProvider = context.read<RideProvider>();
    rideProvider.getPendingRides();
  }

  Future<void> _toggleOnlineStatus(
      DriverLocationService locationService) async {
    if (locationService.isOnline) {
      // Go offline
      await locationService.goOffline();
    } else {
      // Go online with current location
      await locationService.goOnline(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
      );
      // Load pending rides
      _loadPendingRides();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      LocationData locationData = await _location.getLocation();
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        _locationLoaded = true;
      });

      // Update location to DriverLocationService if online
      final locationService = context.read<DriverLocationService>();
      if (locationService.isOnline) {
        locationService.updateCurrentLocation(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();
    final appProvider = context.watch<AppProvider>();
    final locationService = context.watch<DriverLocationService>();
    final pendingRides = rideProvider.userRides
        .where((ride) => ride.status == 'requested')
        .toList();

    // Also include ride requests from the location service
    final locationServiceRides = locationService.pendingRideRequests;
    final allRides = [...pendingRides];

    // Add rides from location service that aren't already in the list
    for (var ride in locationServiceRides) {
      final rideId = ride['id']?.toString();
      if (rideId != null && !allRides.any((r) => r.id.toString() == rideId)) {
        // Convert to ride format or just use the pending rides
      }
    }

    // Get user data from AppProvider
    models.User? currentUser;
    if (appProvider.currentUserData != null) {
      currentUser = models.User.fromJson(appProvider.currentUserData!);
    }

    // Update current location from location service if available
    if (locationService.currentLocation != null) {
      _currentLocation = LatLng(
        locationService.currentLocation!['latitude'] ??
            _currentLocation.latitude,
        locationService.currentLocation!['longitude'] ??
            _currentLocation.longitude,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map with Mapbox tiles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation,
              zoom: 15.0,
              maxZoom: 18.0,
              minZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tiles.locationiq.com/v3/streets/r/{z}/{x}/{y}.png?key=pk.48e2dedac41ff32af8621c2414ee25e8',
                userAgentPackageName: 'com.kva.driver',
              ),
              MarkerLayer(
                markers: [
                  // Driver location marker (Google Maps style)
                  Marker(
                    point: _currentLocation,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: locationService.isOnline
                              ? Colors.green
                              : Colors.grey,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: locationService.isOnline
                            ? Colors.green
                            : Colors.grey,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Pending Verification Banner
          if (_statusLoaded && _approvalStatus != 'approved')
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _approvalStatus == 'rejected'
                      ? Colors.red[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _approvalStatus == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _approvalStatus == 'rejected'
                          ? Icons.cancel
                          : Icons.hourglass_empty,
                      color: _approvalStatus == 'rejected'
                          ? Colors.red
                          : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _approvalStatus == 'rejected'
                                ? 'Application Rejected'
                                : 'Account Pending Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _approvalStatus == 'rejected'
                                  ? Colors.red[800]
                                  : Colors.orange[800],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _approvalStatus == 'rejected'
                                ? 'Your application was not approved. Please contact support for more details.'
                                : 'Your documents are being reviewed. This usually takes 1-2 business days.',
                            style: TextStyle(
                              color: _approvalStatus == 'rejected'
                                  ? Colors.red[700]
                                  : Colors.orange[700],
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

          // Online/Offline status pill (top center, Google Maps style)
          Positioned(
            top: MediaQuery.of(context).padding.top +
                (_statusLoaded && _approvalStatus != 'approved' ? 100 : 16),
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User avatar/profile indicator
                    if (currentUser != null) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        child: Text(
                          currentUser!.firstName.isNotEmpty
                              ? currentUser!.firstName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentUser?.fullName ?? 'Driver',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: locationService.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              locationService.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: locationService.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 20,
                      child: Switch(
                        value: locationService.isOnline,
                        onChanged: _approvalStatus == 'approved'
                            ? (value) async {
                                await _toggleOnlineStatus(locationService);
                              }
                            : null,
                        activeColor: Colors.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Map controls (bottom right, Google Maps style)
          Positioned(
            bottom: 120,
            right: 16,
            child: Column(
              children: [
                // Location button
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.black87),
                    onPressed: () {
                      _mapController.move(_currentLocation, 15.0);
                    },
                  ),
                ),

                // Zoom controls
                Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () {
                          final currentZoom = _mapController.zoom;
                          if (currentZoom < 18.0) {
                            _mapController.move(
                                _mapController.center, currentZoom + 1);
                          }
                        },
                      ),
                      const Divider(height: 1, thickness: 1),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: () {
                          final currentZoom = _mapController.zoom;
                          if (currentZoom > 10.0) {
                            _mapController.move(
                                _mapController.center, currentZoom - 1);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Available rides panel (bottom, Google Maps style)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with drag handle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0066CC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Available Rides',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${allRides.length} nearby',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ride list
                  Expanded(
                    child: allRides.isEmpty
                        ? Center(
                            child: Text(
                              'No ride requests available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: allRides.length,
                            itemBuilder: (context, index) {
                              final ride = allRides[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    // Ride info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ride #${ride.id}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${ride.pickupAddress ?? 'Pickup Location'} → ${ride.dropoffAddress ?? 'Dropoff Location'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on,
                                                  size: 12,
                                                  color: Colors.green[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '\$${ride.fare?.toStringAsFixed(2) ?? '0.00'} • ${ride.distance?.toStringAsFixed(1) ?? '0.0'} km',
                                                style: TextStyle(
                                                  color: Colors.green[600],
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Accept button
                                    ElevatedButton(
                                      onPressed: locationService.isOnline &&
                                              !rideProvider.isLoading
                                          ? () async {
                                              try {
                                                await rideProvider.acceptRide(
                                                    ride.id.toString());
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Ride #${ride.id} accepted!')),
                                                );
                                                // Navigate to en-route pickup screen
                                                Navigator.pushNamed(
                                                    context, '/en-route-pickup',
                                                    arguments: {
                                                      'rideId':
                                                          ride.id.toString(),
                                                    });
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Failed to accept ride: $e')),
                                                );
                                              }
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            locationService.isOnline &&
                                                    !rideProvider.isLoading
                                                ? Colors.green
                                                : Colors.grey,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        textStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: rideProvider.isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Text('Accept'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom navigation space
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
}
