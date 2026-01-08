import '../models/models.dart';
import '../services/api_service.dart';

class RideRepository {
  // Get user rides (for driver)
  Future<List<Ride>> getUserRides({
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await ApiService.getUserRides(
        status: status,
        limit: limit,
        offset: offset,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          return data.map((ride) => Ride.fromJson(ride)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to get user rides');
      }
    } catch (e) {
      throw Exception('Failed to get user rides: $e');
    }
  }

  // Get ride by ID
  Future<Ride> getRideById(String rideId) async {
    try {
      final response = await ApiService.getRideById(rideId);

      if (response['success'] == true) {
        return Ride.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get ride details');
      }
    } catch (e) {
      throw Exception('Failed to get ride details: $e');
    }
  }

  // Accept ride
  Future<Ride> acceptRide(String rideId) async {
    try {
      final response = await ApiService.acceptRide(rideId);

      if (response['success'] == true) {
        return Ride.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to accept ride');
      }
    } catch (e) {
      throw Exception('Failed to accept ride: $e');
    }
  }

  // Start ride
  Future<Ride> startRide(String rideId) async {
    try {
      final response = await ApiService.startRide(rideId);

      if (response['success'] == true) {
        return Ride.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to start ride');
      }
    } catch (e) {
      throw Exception('Failed to start ride: $e');
    }
  }

  // Complete ride
  Future<Ride> completeRide(
    String rideId, {
    double? finalFare,
    String? paymentMethod,
    double? odometerReading,
    String? notes,
  }) async {
    try {
      final response = await ApiService.completeRide(
        rideId,
        finalFare: finalFare,
        paymentMethod: paymentMethod,
        odometerReading: odometerReading,
        notes: notes,
      );

      if (response['success'] == true) {
        return Ride.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to complete ride');
      }
    } catch (e) {
      throw Exception('Failed to complete ride: $e');
    }
  }

  // Update ride status
  Future<Ride> updateRideStatus(String rideId, String status) async {
    try {
      final response = await ApiService.updateRideStatus(rideId, status);

      if (response['success'] == true) {
        return Ride.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update ride status');
      }
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  // Start live tracking for a trip
  Future<void> startLiveTracking(String tripId) async {
    try {
      await ApiService.startLiveTracking(tripId);
    } catch (e) {
      throw Exception('Failed to start live tracking: $e');
    }
  }

  // Stop live tracking
  Future<void> stopLiveTracking() async {
    try {
      await ApiService.stopLiveTracking();
    } catch (e) {
      throw Exception('Failed to stop live tracking: $e');
    }
  }

  // Get all pending ride requests (for drivers to see available rides)
  Future<List<Ride>> getAllPendingRides({
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await ApiService.getAllPendingRides(
        limit: limit,
        offset: offset,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          return data.map((ride) => Ride.fromJson(ride)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to get pending rides');
      }
    } catch (e) {
      print('Failed to get pending rides: $e');
      return []; // Return empty list on error instead of throwing
    }
  }
}