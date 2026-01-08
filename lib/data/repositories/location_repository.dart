import '../models/models.dart';
import '../services/api_service.dart';

class LocationRepository {
  // Create/Update location
  Future<Location> createLocation(Map<String, dynamic> locationData) async {
    try {
      final response = await ApiService.createLocation(locationData);

      if (response['success'] == true) {
        return Location.fromJson(response['data']);
      } else {
        throw Exception(
            response['message'] ?? 'Failed to create/update location');
      }
    } catch (e) {
      throw Exception('Failed to create/update location: $e');
    }
  }

  // Update live location during trip
  Future<Location> updateLiveLocation(Map<String, dynamic> locationData) async {
    try {
      final response = await ApiService.updateLiveLocation(locationData);

      if (response['success'] == true) {
        return Location.fromJson(response['data']);
      } else {
        throw Exception(
            response['message'] ?? 'Failed to update live location');
      }
    } catch (e) {
      throw Exception('Failed to update live location: $e');
    }
  }

  // Start live tracking
  Future<Map<String, dynamic>> startLiveTracking(String tripId) async {
    try {
      final response = await ApiService.startLiveTracking(tripId);

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to start live tracking');
      }
    } catch (e) {
      throw Exception('Failed to start live tracking: $e');
    }
  }

  // Stop live tracking
  Future<Map<String, dynamic>> stopLiveTracking() async {
    try {
      final response = await ApiService.stopLiveTracking();

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to stop live tracking');
      }
    } catch (e) {
      throw Exception('Failed to stop live tracking: $e');
    }
  }

  // Get live tracking status
  Future<Map<String, dynamic>> getLiveTrackingStatus(String tripId) async {
    try {
      final response = await ApiService.getLiveTrackingStatus(tripId);

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get live tracking status');
      }
    } catch (e) {
      throw Exception('Failed to get live tracking status: $e');
    }
  }

  // Get my location
  Future<Location> getMyLocation() async {
    try {
      final response = await ApiService.getMyLocation();

      if (response['success'] == true) {
        return Location.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get my location');
      }
    } catch (e) {
      throw Exception('Failed to get my location: $e');
    }
  }

  // Get my location history
  Future<List<Location>> getMyLocationHistory({
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final response = await ApiService.getMyLocationHistory(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          return data.map((location) => Location.fromJson(location)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get location history');
      }
    } catch (e) {
      throw Exception('Failed to get location history: $e');
    }
  }

  // Get driver location for ride
  Future<Location> getDriverLocationForRide(String rideId) async {
    try {
      final response = await ApiService.getDriverLocationForRide(rideId);

      if (response['success'] == true) {
        return Location.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get driver location');
      }
    } catch (e) {
      throw Exception('Failed to get driver location: $e');
    }
  }

  // Calculate ETA
  Future<ETAResult> calculateETA({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final response = await ApiService.calculateETA(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );

      if (response['success'] == true) {
        return ETAResult.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to calculate ETA');
      }
    } catch (e) {
      throw Exception('Failed to calculate ETA: $e');
    }
  }

  // Find nearby users
  Future<List<NearbyUser>> findNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
    String? userType,
  }) async {
    try {
      final response = await ApiService.findNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        userType: userType,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          return data.map((user) => NearbyUser.fromJson(user)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to find nearby users');
      }
    } catch (e) {
      throw Exception('Failed to find nearby users: $e');
    }
  }

  // Find nearby users (GET version)
  Future<List<NearbyUser>> findNearbyUsersQuery({
    required double lat,
    required double lng,
    double radius = 5.0,
    String? userType,
  }) async {
    try {
      final response = await ApiService.findNearbyUsersQuery(
        lat: lat,
        lng: lng,
        radius: radius,
        userType: userType,
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          return data.map((user) => NearbyUser.fromJson(user)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to find nearby users');
      }
    } catch (e) {
      throw Exception('Failed to find nearby users: $e');
    }
  }
}
