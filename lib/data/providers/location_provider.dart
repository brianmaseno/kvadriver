import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/location_repository.dart';

class LocationProvider extends ChangeNotifier {
  final LocationRepository _locationRepository = LocationRepository();

  Location? _currentLocation;
  List<Location> _locationHistory = [];
  List<NearbyUser> _nearbyUsers = [];
  ETAResult? _currentETA;
  Map<String, dynamic>? _liveTrackingStatus;
  bool _isLoading = false;
  String? _error;

  // Getters
  Location? get currentLocation => _currentLocation;
  List<Location> get locationHistory => _locationHistory;
  List<NearbyUser> get nearbyUsers => _nearbyUsers;
  ETAResult? get currentETA => _currentETA;
  Map<String, dynamic>? get liveTrackingStatus => _liveTrackingStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create/Update location
  Future<void> createLocation(Map<String, dynamic> locationData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentLocation = await _locationRepository.createLocation(locationData);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update live location during trip
  Future<void> updateLiveLocation(Map<String, dynamic> locationData) async {
    try {
      _currentLocation =
          await _locationRepository.updateLiveLocation(locationData);
      // Don't set loading state for live updates to avoid UI flickering
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Start live tracking
  Future<void> startLiveTracking(String tripId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _locationRepository.startLiveTracking(tripId);
      _liveTrackingStatus = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stop live tracking
  Future<void> stopLiveTracking() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _locationRepository.stopLiveTracking();
      _liveTrackingStatus = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get live tracking status
  Future<void> getLiveTrackingStatus(String tripId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _liveTrackingStatus =
          await _locationRepository.getLiveTrackingStatus(tripId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get my location
  Future<void> getMyLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentLocation = await _locationRepository.getMyLocation();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get my location history
  Future<void> getMyLocationHistory({
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _locationHistory = await _locationRepository.getMyLocationHistory(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get driver location for ride
  Future<void> getDriverLocationForRide(String rideId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentLocation =
          await _locationRepository.getDriverLocationForRide(rideId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate ETA
  Future<void> calculateETA({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentETA = await _locationRepository.calculateETA(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Find nearby users
  Future<void> findNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
    String? userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nearbyUsers = await _locationRepository.findNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        userType: userType,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Find nearby users (GET version)
  Future<void> findNearbyUsersQuery({
    required double lat,
    required double lng,
    double radius = 5.0,
    String? userType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nearbyUsers = await _locationRepository.findNearbyUsersQuery(
        lat: lat,
        lng: lng,
        radius: radius,
        userType: userType,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear current location
  void clearCurrentLocation() {
    _currentLocation = null;
    notifyListeners();
  }

  // Clear current ETA
  void clearCurrentETA() {
    _currentETA = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh nearby users
  Future<void> refreshNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
    String? userType,
  }) async {
    await findNearbyUsers(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      userType: userType,
    );
  }

  // Get nearby riders (specific to drivers)
  Future<void> getNearbyRiders({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    await findNearbyUsersQuery(
      lat: latitude,
      lng: longitude,
      radius: radius,
      userType: 'rider',
    );
  }

  // Get nearby drivers (specific to riders)
  Future<void> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    await findNearbyUsersQuery(
      lat: latitude,
      lng: longitude,
      radius: radius,
      userType: 'driver',
    );
  }
}
