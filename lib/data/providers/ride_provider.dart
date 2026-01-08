import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/ride_repository.dart';

class RideProvider extends ChangeNotifier {
  final RideRepository _rideRepository = RideRepository();

  List<Ride> _userRides = [];
  Ride? _currentRide;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Ride> get userRides => _userRides;
  Ride? get currentRide => _currentRide;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get user rides (for driver)
  Future<void> getUserRides({
    String? status,
    int? limit,
    int? offset,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userRides = await _rideRepository.getUserRides(
        status: status,
        limit: limit,
        offset: offset,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get ride by ID
  Future<void> getRideById(String rideId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRide = await _rideRepository.getRideById(rideId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Accept ride
  Future<void> acceptRide(String rideId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRide = await _rideRepository.acceptRide(rideId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start ride
  Future<void> startRide(String rideId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRide = await _rideRepository.startRide(rideId);
      // Start live tracking for this trip
      await _rideRepository.startLiveTracking(rideId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete ride
  Future<void> completeRide(
    String rideId, {
    double? finalFare,
    String? paymentMethod,
    double? odometerReading,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRide = await _rideRepository.completeRide(
        rideId,
        finalFare: finalFare,
        paymentMethod: paymentMethod,
        odometerReading: odometerReading,
        notes: notes,
      );
      // Stop live tracking after completing the ride
      await _rideRepository.stopLiveTracking();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String rideId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRide = await _rideRepository.updateRideStatus(rideId, status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear current ride
  void clearCurrentRide() {
    _currentRide = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh user rides
  Future<void> refreshUserRides() async {
    await getUserRides();
  }

  // Get active rides (ongoing rides for driver)
  Future<void> getActiveRides() async {
    await getUserRides(status: 'ongoing');
  }

  // Get pending rides (available rides for driver to accept)
  Future<void> getPendingRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userRides = await _rideRepository.getAllPendingRides();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}