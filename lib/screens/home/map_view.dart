import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/providers/app_provider.dart';
import '../../data/providers/ride_provider.dart';
import '../../data/services/api_service.dart';
import '../../data/services/driver_location_service.dart';
import '../../data/models/models.dart' as models;
import '../../data/widgets/ride_request_popup.dart';

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
  bool _showRidePopup = false;
  Map<String, dynamic>? _currentRideRequest;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkDriverStatus();
    // Load pending rides initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingRides();
      _listenForRideRequests();
    });
  }

  void _listenForRideRequests() {
    final locationService = context.read<DriverLocationService>();
    // Listen to ride requests from location service
    locationService.addListener(() {
      if (locationService.pendingRideRequests.isNotEmpty && mounted) {
        final newRequest = locationService.pendingRideRequests.last;
        setState(() {
          _currentRideRequest = newRequest;
          _showRidePopup = true;
        });
      }
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

    // Filter to only show active ride requests (not cancelled, expired, or already taken)
    final pendingRides = rideProvider.userRides
        .where((ride) =>
            ride.status == 'requested' &&
            ride.status != 'cancelled' &&
            ride.status != 'expired' &&
            ride.status != 'accepted')
        .toList();

    // Also include ride requests from the location service
    final locationServiceRides = locationService.pendingRideRequests;
    final allRides = [...pendingRides];

    // Add rides from location service that aren't already in the list
    for (var ride in locationServiceRides) {
      final rideId = ride['id']?.toString();
      final rideStatus = ride['status']?.toString();
      // Only add if active and not already in list
      if (rideId != null &&
          rideStatus == 'requested' &&
          !allRides.any((r) => r.id.toString() == rideId)) {
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

          // Online/Offline status button (top center - BIGGER and more prominent)
          Positioned(
            top: MediaQuery.of(context).padding.top +
                (_statusLoaded && _approvalStatus != 'approved' ? 110 : 16),
            left: 20,
            right: 20,
            child: Center(
              child: GestureDetector(
                onTap: _approvalStatus == 'approved'
                    ? () async {
                        await _toggleOnlineStatus(locationService);
                      }
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You must be verified to go online',
                              style: GoogleFonts.geologica(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: locationService.isOnline
                          ? [Colors.green[600]!, Colors.green[700]!]
                          : _approvalStatus == 'approved'
                              ? [Colors.grey[600]!, Colors.grey[700]!]
                              : [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (locationService.isOnline
                                ? Colors.green
                                : _approvalStatus == 'approved'
                                    ? Colors.grey
                                    : Colors.orange)
                            .withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User avatar
                      if (currentUser != null) ...[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              currentUser!.firstName.isNotEmpty
                                  ? currentUser!.firstName[0].toUpperCase()
                                  : 'D',
                              style: GoogleFonts.geologica(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentUser?.fullName ?? 'Driver',
                            style: GoogleFonts.geologica(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                locationService.isOnline
                                    ? 'ONLINE - Accepting Rides'
                                    : _approvalStatus == 'approved'
                                        ? 'OFFLINE - Tap to go online'
                                        : 'PENDING VERIFICATION',
                                style: GoogleFonts.geologica(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Toggle icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          locationService.isOnline
                              ? Icons.power_settings_new
                              : Icons.power_off,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
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
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with drag handle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0066CC), Color(0xFF0052A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Available Rides',
                          style: GoogleFonts.geologica(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${allRides.length} nearby',
                            style: GoogleFonts.geologica(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _loadPendingRides(),
                        ),
                      ],
                    ),
                  ),

                  // Ride list
                  Expanded(
                    child: allRides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  locationService.isOnline
                                      ? Icons.hourglass_empty
                                      : Icons.wifi_off,
                                  color: Colors.grey[400],
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  locationService.isOnline
                                      ? 'Waiting for ride requests...'
                                      : 'Go online to receive rides',
                                  style: GoogleFonts.geologica(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: allRides.length,
                            itemBuilder: (context, index) {
                              final ride = allRides[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
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
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0066CC)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '#${ride.id?.toString().substring(0, 6) ?? 'N/A'}',
                                                  style: GoogleFonts.geologica(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color:
                                                        const Color(0xFF0066CC),
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '\$${ride.fare?.toStringAsFixed(2) ?? '0.00'}',
                                                style: GoogleFonts.geologica(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.circle,
                                                  size: 8,
                                                  color: Colors.green[600]),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  ride.pickupAddress ??
                                                      'Pickup Location',
                                                  style: GoogleFonts.geologica(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.circle,
                                                  size: 8,
                                                  color: Colors.red[600]),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  ride.dropoffAddress ??
                                                      'Dropoff Location',
                                                  style: GoogleFonts.geologica(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${ride.distance?.toStringAsFixed(1) ?? '0.0'} km away',
                                            style: GoogleFonts.geologica(
                                              color: Colors.grey[500],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

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
                                                      'Ride accepted!',
                                                      style: GoogleFonts
                                                          .geologica(),
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
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
                                                      'Failed to accept ride: $e',
                                                      style: GoogleFonts
                                                          .geologica(),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
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
                                            horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: rideProvider.isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              'Accept',
                                              style: GoogleFonts.geologica(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
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
