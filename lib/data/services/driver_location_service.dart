import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:location/location.dart';
import 'api_service.dart';

/// Service for managing driver location updates when online
/// Updates location every 2 seconds and checks for ride requests
class DriverLocationService extends ChangeNotifier {
  static final DriverLocationService _instance =
      DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  // Location plugin
  final Location _location = Location();

  // State
  bool _isOnline = false;
  bool _isUpdating = false;
  Timer? _locationTimer;
  LocationData? _currentLocation;
  List<Map<String, dynamic>> _pendingRideRequests = [];
  Map<String, dynamic>? _urgentRideRequest;
  String? _errorMessage;

  // Update interval (2 seconds)
  static const Duration _updateInterval = Duration(seconds: 2);

  // Getters
  bool get isOnline => _isOnline;
  bool get isUpdating => _isUpdating;
  Map<String, dynamic>? get currentLocation => _currentLocation != null
      ? {
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude
        }
      : _externalLocation;
  List<Map<String, dynamic>> get pendingRideRequests => _pendingRideRequests;
  Map<String, dynamic>? get urgentRideRequest => _urgentRideRequest;
  String? get errorMessage => _errorMessage;
  bool get hasRideRequests =>
      _urgentRideRequest != null || _pendingRideRequests.isNotEmpty;

  // External location (set from map view)
  Map<String, dynamic>? _externalLocation;

  /// Update current location externally (from map view)
  void updateCurrentLocation(
      {required double latitude, required double longitude}) {
    _externalLocation = {'latitude': latitude, 'longitude': longitude};
    notifyListeners();
  }

  /// Go online - start location updates
  Future<bool> goOnline({double? latitude, double? longitude}) async {
    if (_isOnline) return true;

    try {
      // Check location permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _errorMessage = 'Location service is required to go online';
          notifyListeners();
          return false;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _errorMessage = 'Location permission is required to go online';
          notifyListeners();
          return false;
        }
      }

      // Get initial location (use provided or fetch)
      if (latitude != null && longitude != null) {
        _externalLocation = {'latitude': latitude, 'longitude': longitude};
      }

      _currentLocation = await _location.getLocation();

      // Use external location if device location unavailable
      final lat = _currentLocation?.latitude ?? latitude;
      final lng = _currentLocation?.longitude ?? longitude;

      if (lat == null || lng == null) {
        _errorMessage = 'Unable to get current location';
        notifyListeners();
        return false;
      }

      // Call backend to go online
      final response = await ApiService.goOnline(
        latitude: lat,
        longitude: lng,
        heading: _currentLocation?.heading,
        speed: _currentLocation?.speed,
        accuracy: _currentLocation?.accuracy,
      );

      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'Failed to go online';
        notifyListeners();
        return false;
      }

      _isOnline = true;
      _errorMessage = null;

      // Start periodic location updates
      _startLocationUpdates();

      notifyListeners();
      print('🟢 Driver is now ONLINE');
      return true;
    } catch (e) {
      print('🔴 Error going online: $e');
      _errorMessage = 'Failed to go online: $e';
      notifyListeners();
      return false;
    }
  }

  /// Go offline - stop location updates
  Future<bool> goOffline() async {
    if (!_isOnline) return true;

    try {
      // Stop location updates first
      _stopLocationUpdates();

      // Call backend to go offline
      final response = await ApiService.goOffline();

      _isOnline = false;
      _pendingRideRequests = [];
      _urgentRideRequest = null;
      _errorMessage = null;

      notifyListeners();
      print('🔴 Driver is now OFFLINE');
      return true;
    } catch (e) {
      print('🔴 Error going offline: $e');
      _errorMessage = 'Failed to go offline: $e';
      notifyListeners();
      return false;
    }
  }

  /// Start periodic location updates (every 2 seconds)
  void _startLocationUpdates() {
    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(_updateInterval, (timer) async {
      if (!_isOnline) {
        timer.cancel();
        return;
      }

      await _updateLocation();
    });

    print('📍 Started location updates (every 2 seconds)');
  }

  /// Stop periodic location updates
  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isUpdating = false;
    print('📍 Stopped location updates');
  }

  /// Update driver location and check for ride requests
  Future<void> _updateLocation() async {
    if (_isUpdating) return; // Prevent overlapping updates

    _isUpdating = true;

    try {
      // Get current location
      _currentLocation = await _location.getLocation();

      if (_currentLocation == null) {
        _isUpdating = false;
        return;
      }

      // Send location update to backend
      final response = await ApiService.updateDriverLocation(
        latitude: _currentLocation!.latitude!,
        longitude: _currentLocation!.longitude!,
        heading: _currentLocation!.heading,
        speed: _currentLocation!.speed,
        accuracy: _currentLocation!.accuracy,
      );

      if (response['success'] == true) {
        final data = response['data'];

        // Check for pending ride requests
        if (data != null) {
          final hasPending = data['hasPendingRequests'] ?? false;
          final nearbyRides = data['nearbyRides'] as List<dynamic>? ?? [];

          if (hasPending || nearbyRides.isNotEmpty) {
            _pendingRideRequests =
                nearbyRides.map((r) => r as Map<String, dynamic>).toList();

            // Set the most urgent request (first one)
            if (_pendingRideRequests.isNotEmpty) {
              _urgentRideRequest = _pendingRideRequests.first;
              print('🚨 New ride request available!');
            }

            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('🔴 Error updating location: $e');
    } finally {
      _isUpdating = false;
    }
  }

  /// Manually check for ride requests
  Future<void> checkRideRequests() async {
    try {
      final response = await ApiService.checkRideRequests();

      if (response['success'] == true) {
        final data = response['data'];

        if (data != null) {
          final hasRequests = data['hasRequests'] ?? false;

          if (hasRequests) {
            // Check for direct (urgent) requests first
            final directRequests =
                data['directRequests'] as List<dynamic>? ?? [];
            final nearbyRides = data['nearbyRides'] as List<dynamic>? ?? [];

            if (directRequests.isNotEmpty) {
              _urgentRideRequest = directRequests.first as Map<String, dynamic>;
              _pendingRideRequests =
                  directRequests.map((r) => r as Map<String, dynamic>).toList();
            } else if (nearbyRides.isNotEmpty) {
              _pendingRideRequests =
                  nearbyRides.map((r) => r as Map<String, dynamic>).toList();
              _urgentRideRequest = _pendingRideRequests.first;
            }

            notifyListeners();
          } else {
            _pendingRideRequests = [];
            _urgentRideRequest = null;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('🔴 Error checking ride requests: $e');
    }
  }

  /// Clear the current urgent ride request (after accepting/denying)
  void clearUrgentRequest() {
    _urgentRideRequest = null;
    if (_pendingRideRequests.isNotEmpty) {
      _pendingRideRequests.removeAt(0);
      if (_pendingRideRequests.isNotEmpty) {
        _urgentRideRequest = _pendingRideRequests.first;
      }
    }
    notifyListeners();
  }

  /// Accept a ride request
  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    try {
      final response = await ApiService.acceptRide(rideId);

      if (response['success'] == true) {
        // Clear the request from pending
        _pendingRideRequests.removeWhere((r) => r['id'].toString() == rideId);
        if (_urgentRideRequest != null &&
            _urgentRideRequest!['id'].toString() == rideId) {
          _urgentRideRequest = null;
        }
        notifyListeners();
      }

      return response;
    } catch (e) {
      print('🔴 Error accepting ride: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Deny a ride request
  Future<Map<String, dynamic>> denyRide(String rideId, {String? reason}) async {
    try {
      final response = await ApiService.denyRide(rideId, reason: reason);

      // Clear the request from pending regardless of response
      _pendingRideRequests.removeWhere((r) => r['id'].toString() == rideId);
      if (_urgentRideRequest != null &&
          _urgentRideRequest!['id'].toString() == rideId) {
        _urgentRideRequest =
            _pendingRideRequests.isNotEmpty ? _pendingRideRequests.first : null;
      }
      notifyListeners();

      return response;
    } catch (e) {
      print('🔴 Error denying ride: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }
}
