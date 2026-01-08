import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_service.dart';

class ApiService {
  // Using ngrok forwarded URL for remote backend access
  static const String baseUrl = 'https://jccw7xbl-4000.uks1.devtunnels.ms/v1';
  static String? _authToken;

  static Future<void> setAuthToken(String token) async {
    _authToken = token;
  }

  static Future<String?> getAuthToken() async {
    if (_authToken != null) return _authToken;
    _authToken = await TokenService.getAccessToken();
    return _authToken;
  }

  static Future<void> clearAuthToken() async {
    _authToken = null;
    await TokenService.clearTokens();
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getAuthToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<http.Response> _makeRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _getHeaders();
    var response = await request(headers);

    if (response.statusCode == 401) {
      final newToken = await TokenService.refreshAccessToken();
      if (newToken != null) {
        await setAuthToken(newToken);
        headers = await _getHeaders();
        response = await request(headers);
      }
    }
    return response;
  }

  // User Registration
  static Future<Map<String, dynamic>> registerUser(
      Map<String, dynamic> userData) async {
    try {
      print('🔵 API: Registering user');
      final response = await _makeRequest((headers) => http.post(
            Uri.parse('$baseUrl/users/register'),
            headers: headers,
            body: jsonEncode(userData),
          ));
      print('🔵 Response Status: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 User Registration Error: $e');
      rethrow;
    }
  }

  // Request OTP
  static Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      print('🟡 API: Requesting OTP');
      print('🟡 URL: $baseUrl/auth/request-otp');
      print('🟡 Body: ${jsonEncode({'phoneNumber': phoneNumber})}');

      // For OTP requests, don't include auth headers as user might not be authenticated yet
      final headers = {
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-otp'),
        headers: headers,
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      print('🟡 Response Status: ${response.statusCode}');
      print('🟡 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 OTP Request Error: $e');
      rethrow;
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(
      String phoneNumber, String otp) async {
    try {
      print('🟢 API: Verifying OTP');
      print('🟢 URL: $baseUrl/auth/verify-otp');
      print('🟢 Body: ${jsonEncode({'phoneNumber': phoneNumber, 'otp': otp})}');

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: headers,
        body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
      );

      print('🟢 Response Status: ${response.statusCode}');
      print('🟢 Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      if (data['accessToken'] != null && data['refreshToken'] != null) {
        await TokenService.saveTokens(
            data['accessToken'], data['refreshToken']);
        setAuthToken(data['accessToken']);
      }
      return data;
    } catch (e) {
      print('🔴 OTP Verification Error: $e');
      rethrow;
    }
  }

  // Upload image and get URL
  static Future<String?> uploadImage(String imagePath) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/image'));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);

      return jsonResponse['imageUrl'];
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  // Driver Registration with vehicle info
  static Future<Map<String, dynamic>> registerDriver(int userId,
      Map<String, dynamic> driverData, Map<String, dynamic> vehicleData) async {
    try {
      print('🟣 API: Starting driver registration');
      final requestBody = {
        'userId': userId,
        'driver': driverData,
        'vehicle': vehicleData
      };
      final response = await _makeRequest((headers) => http.post(
            Uri.parse('$baseUrl/driver/register'),
            headers: headers,
            body: jsonEncode(requestBody),
          ));
      print('🟣 Response Status: ${response.statusCode}');
      print('🟣 Response Body: ${response.body}');

      // Handle 403 Forbidden - might mean driver already registered or permission issue
      if (response.statusCode == 403) {
        final body = jsonDecode(response.body);
        final message = body['message'] ?? 'Access denied';
        print('🟣 403 Response: $message');
        return {
          'success': message.toLowerCase().contains('already'),
          'message': message,
          'error': message
        };
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Driver Registration Error: $e');
      rethrow;
    }
  }

  // Get user rides (for driver)
  static Future<Map<String, dynamic>> getUserRides({
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      final uri = Uri.parse('$baseUrl/ride/user').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response =
          await _makeRequest((headers) => http.get(uri, headers: headers));
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 User Rides Error: $e');
      rethrow;
    }
  }

  // Get all pending ride requests (for drivers to see available rides)
  static Future<Map<String, dynamic>> getAllPendingRides({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      final uri = Uri.parse('$baseUrl/ride/available').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('🚕 API: Getting all pending rides');
      print('🚕 URL: $uri');

      final response =
          await _makeRequest((headers) => http.get(uri, headers: headers));

      print('🚕 Response Status: ${response.statusCode}');
      print('🚕 Response Body: ${response.body}');

      // Handle non-200 responses gracefully
      if (response.statusCode == 403) {
        print('🔴 Access denied - user may not have driver role');
        return {
          'success': false,
          'rides': [],
          'error': 'Access denied',
          'message': 'Driver access required'
        };
      }

      if (response.statusCode == 404) {
        print('🔴 Endpoint not found - returning empty rides list');
        return {'success': true, 'rides': [], 'message': 'No available rides'};
      }

      if (response.statusCode != 200) {
        print('🔴 Error response: ${response.statusCode}');
        return {
          'success': false,
          'rides': [],
          'error': 'Failed to fetch rides'
        };
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get All Pending Rides Error: $e');
      return {'success': false, 'rides': [], 'error': e.toString()};
    }
  }

  // Get ride by ID
  static Future<Map<String, dynamic>> getRideById(String rideId) async {
    try {
      final response = await _makeRequest((headers) =>
          http.get(Uri.parse('$baseUrl/ride/$rideId'), headers: headers));
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Ride Error: $e');
      rethrow;
    }
  }

  // Accept ride (Driver)
  static Future<Map<String, dynamic>> acceptRide(String rideId) async {
    try {
      final response = await _makeRequest((headers) => http
          .put(Uri.parse('$baseUrl/ride/$rideId/accept'), headers: headers));
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Accept Ride Error: $e');
      rethrow;
    }
  }

  // Start ride (Driver)
  static Future<Map<String, dynamic>> startRide(String rideId) async {
    try {
      final response = await _makeRequest((headers) =>
          http.put(Uri.parse('$baseUrl/ride/$rideId/start'), headers: headers));
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Start Ride Error: $e');
      rethrow;
    }
  }

  // Complete ride (Driver)
  static Future<Map<String, dynamic>> completeRide(
    String rideId, {
    double? finalFare,
    String? paymentMethod,
    double? odometerReading,
    String? notes,
  }) async {
    try {
      final requestBody = <String, dynamic>{};
      if (finalFare != null) requestBody['finalFare'] = finalFare;
      if (paymentMethod != null) requestBody['paymentMethod'] = paymentMethod;
      if (odometerReading != null)
        requestBody['odometerReading'] = odometerReading;
      if (notes != null) requestBody['notes'] = notes;
      final response = await _makeRequest((headers) => http.put(
            Uri.parse('$baseUrl/ride/$rideId/complete'),
            headers: headers,
            body: jsonEncode(requestBody),
          ));
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Complete Ride Error: $e');
      rethrow;
    }
  }

  // Update ride status (Driver)
  static Future<Map<String, dynamic>> updateRideStatus(
      String rideId, String status) async {
    try {
      final requestBody = {'status': status};

      print('🔄 API: Updating ride status');
      print('🔄 URL: $baseUrl/ride/$rideId/status');
      final headers = await _getHeaders();
      print('🔄 Headers: $headers');
      print('🔄 Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl/ride/$rideId/status'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🔄 Response Status: ${response.statusCode}');
      print('🔄 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Update Ride Status Error: $e');
      rethrow;
    }
  }

  // Get ride quote
  static Future<Map<String, dynamic>> getRideQuote(
      String pickup, String dropoff) async {
    try {
      final queryParams = {
        'pickup': pickup,
        'dropoff': dropoff,
      };

      final uri = Uri.parse('$baseUrl/ride/quote')
          .replace(queryParameters: queryParams);

      print('💰 API: Getting ride quote');
      print('💰 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('💰 Response Status: ${response.statusCode}');
      print('💰 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Ride Quote Error: $e');
      rethrow;
    }
  }

  // Get nearby drivers
  static Future<Map<String, dynamic>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radius = 5000,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };

      final uri = Uri.parse('$baseUrl/ride/nearby')
          .replace(queryParameters: queryParams);

      print('🚗 API: Getting nearby drivers');
      print('🚗 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('🚗 Response Status: ${response.statusCode}');
      print('🚗 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Nearby Drivers Error: $e');
      rethrow;
    }
  }

  // Request a ride
  static Future<Map<String, dynamic>> requestRide({
    required String pickupAddress,
    required String dropoffAddress,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    try {
      // Transform parameter names to match API expectations
      final requestBody = {
        'pickupAddress': pickupAddress,
        'dropoffAddress': dropoffAddress,
        'pickupLatitude': pickupLat,
        'pickupLongitude': pickupLng,
        'dropoffLatitude': dropoffLat,
        'dropoffLongitude': dropoffLng,
      };

      print('🚕 API: Requesting ride');
      print('🚕 URL: $baseUrl/ride/request');
      final headers = await _getHeaders();
      print('🚕 Headers: $headers');
      print('🚕 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/ride/request'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🚕 Response Status: ${response.statusCode}');
      print('🚕 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Request Ride Error: $e');
      rethrow;
    }
  }

  // Cancel ride
  static Future<Map<String, dynamic>> cancelRide(String rideId) async {
    try {
      print('❌ API: Cancelling ride');
      print('❌ URL: $baseUrl/ride/$rideId/cancel');

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/ride/$rideId/cancel'),
        headers: headers,
      );

      print('❌ Response Status: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Cancel Ride Error: $e');
      rethrow;
    }
  }

  // ===== LOCATION/MAPS METHODS =====

  // Create/Update location
  static Future<Map<String, dynamic>> createLocation(
      Map<String, dynamic> locationData) async {
    try {
      print('📍 API: Creating/updating location');
      print('📍 URL: $baseUrl/locations');
      final headers = await _getHeaders();
      print('📍 Headers: $headers');
      print('📍 Body: ${jsonEncode(locationData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/locations'),
        headers: headers,
        body: jsonEncode(locationData),
      );

      print('📍 Response Status: ${response.statusCode}');
      print('📍 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Create Location Error: $e');
      rethrow;
    }
  }

  // Update live location during trip
  static Future<Map<String, dynamic>> updateLiveLocation(
      Map<String, dynamic> locationData) async {
    try {
      print('📍 API: Updating live location');
      print('📍 URL: $baseUrl/locations/live');
      final headers = await _getHeaders();
      print('📍 Headers: $headers');
      print('📍 Body: ${jsonEncode(locationData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/locations/live'),
        headers: headers,
        body: jsonEncode(locationData),
      );

      print('📍 Response Status: ${response.statusCode}');
      print('📍 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Update Live Location Error: $e');
      rethrow;
    }
  }

  // Start live tracking
  static Future<Map<String, dynamic>> startLiveTracking(String tripId) async {
    try {
      print('▶️ API: Starting live tracking for trip: $tripId');

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/locations/live/start'),
        headers: headers,
        body: jsonEncode({'tripId': tripId}),
      );

      print('▶️ Response Status: ${response.statusCode}');
      print('▶️ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Start Live Tracking Error: $e');
      rethrow;
    }
  }

  // Stop live tracking
  static Future<Map<String, dynamic>> stopLiveTracking() async {
    try {
      print('⏹️ API: Stopping live tracking');

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/locations/live/stop'),
        headers: headers,
      );

      print('⏹️ Response Status: ${response.statusCode}');
      print('⏹️ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Stop Live Tracking Error: $e');
      rethrow;
    }
  }

  // Get live tracking status
  static Future<Map<String, dynamic>> getLiveTrackingStatus(
      String tripId) async {
    try {
      final uri = Uri.parse('$baseUrl/locations/live/status/$tripId');

      print('📊 API: Getting live tracking status');
      print('📊 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('📊 Response Status: ${response.statusCode}');
      print('📊 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Live Tracking Status Error: $e');
      rethrow;
    }
  }

  // Get my location
  static Future<Map<String, dynamic>> getMyLocation() async {
    try {
      final uri = Uri.parse('$baseUrl/locations/me');

      print('📍 API: Getting my location');
      print('📍 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('📍 Response Status: ${response.statusCode}');
      print('📍 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get My Location Error: $e');
      rethrow;
    }
  }

  // Get my location history
  static Future<Map<String, dynamic>> getMyLocationHistory({
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('$baseUrl/locations/me/history')
          .replace(queryParameters: queryParams);

      print('📚 API: Getting my location history');
      print('📚 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('📚 Response Status: ${response.statusCode}');
      print('📚 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get My Location History Error: $e');
      rethrow;
    }
  }

  // Get driver location for ride
  static Future<Map<String, dynamic>> getDriverLocationForRide(
      String rideId) async {
    try {
      final uri = Uri.parse('$baseUrl/locations/ride/$rideId');

      print('🚗 API: Getting driver location for ride');
      print('🚗 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('🚗 Response Status: ${response.statusCode}');
      print('🚗 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Driver Location Error: $e');
      rethrow;
    }
  }

  // Calculate ETA
  static Future<Map<String, dynamic>> calculateETA({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final requestBody = {
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toLat': toLat,
        'toLng': toLng,
      };

      print('⏱️ API: Calculating ETA');
      print('⏱️ URL: $baseUrl/locations/eta');
      final headers = await _getHeaders();
      print('⏱️ Headers: $headers');
      print('⏱️ Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/locations/eta'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('⏱️ Response Status: ${response.statusCode}');
      print('⏱️ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Calculate ETA Error: $e');
      rethrow;
    }
  }

  // Find nearby users
  static Future<Map<String, dynamic>> findNearbyUsers({
    required double latitude,
    required double longitude,
    double? radius,
    String? userType,
  }) async {
    try {
      final requestBody = {
        'latitude': latitude,
        'longitude': longitude,
        if (radius != null) 'radius': radius,
        if (userType != null) 'userType': userType,
      };

      print('🔍 API: Finding nearby users');
      print('🔍 URL: $baseUrl/locations/nearby');
      final headers = await _getHeaders();
      print('🔍 Headers: $headers');
      print('🔍 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/locations/nearby'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Find Nearby Users Error: $e');
      rethrow;
    }
  }

  // Find nearby users (GET version)
  static Future<Map<String, dynamic>> findNearbyUsersQuery({
    required double lat,
    required double lng,
    double radius = 5.0,
    String? userType,
  }) async {
    try {
      final queryParams = {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'radius': radius.toString(),
        if (userType != null) 'userType': userType,
      };

      final uri = Uri.parse('$baseUrl/locations/nearby')
          .replace(queryParameters: queryParams);

      print('🔍 API: Finding nearby users (GET)');
      print('🔍 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('🔍 Response Status: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Find Nearby Users Query Error: $e');
      rethrow;
    }
  }

  // Location service health check
  static Future<Map<String, dynamic>> getLocationHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/locations/health');

      print('❤️ API: Checking location service health');
      print('❤️ URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('❤️ Response Status: ${response.statusCode}');
      print('❤️ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Location Health Check Error: $e');
      rethrow;
    }
  }

  // Get heatmap data (Admin)
  static Future<Map<String, dynamic>> getHeatmapData({
    String? bounds,
    String? userType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (bounds != null) queryParams['bounds'] = bounds;
      if (userType != null) queryParams['userType'] = userType;

      final uri = Uri.parse('$baseUrl/locations/analytics/heatmap').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('🗺️ API: Getting heatmap data');
      print('🗺️ URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('🗺️ Response Status: ${response.statusCode}');
      print('🗺️ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Heatmap Data Error: $e');
      rethrow;
    }
  }

  // Get driver status
  static Future<Map<String, dynamic>> getDriverStatus() async {
    try {
      print('🚗 API: Getting driver status');
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$baseUrl/driver/status'), headers: headers);
      print('🚗 Response Status: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Driver Status Error: $e');
      rethrow;
    }
  }

  // Update driver status
  static Future<Map<String, dynamic>> updateDriverStatus(String status) async {
    try {
      final requestBody = {'status': status};
      print('🚗 API: Updating driver status');
      print('🚗 URL: $baseUrl/driver/status');
      final headers = await _getHeaders();
      print('🚗 Headers: $headers');
      print('🚗 Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl/driver/status'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🚗 Response Status: ${response.statusCode}');
      print('🚗 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Update Driver Status Error: $e');
      rethrow;
    }
  }

  // Go online with location
  static Future<Map<String, dynamic>> goOnline({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
  }) async {
    try {
      final requestBody = {
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
      };

      print('🟢 API: Going online');
      print('🟢 URL: $baseUrl/driver/online');
      final headers = await _getHeaders();
      print('🟢 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/driver/online'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('🟢 Response Status: ${response.statusCode}');
      print('🟢 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Go Online Error: $e');
      rethrow;
    }
  }

  // Go offline
  static Future<Map<String, dynamic>> goOffline() async {
    try {
      print('🔴 API: Going offline');
      print('🔴 URL: $baseUrl/driver/offline');
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/driver/offline'),
        headers: headers,
      );

      print('🔴 Response Status: ${response.statusCode}');
      print('🔴 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Go Offline Error: $e');
      rethrow;
    }
  }

  // Update driver location (called every 2 seconds)
  static Future<Map<String, dynamic>> updateDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
  }) async {
    try {
      final requestBody = {
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
      };

      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/driver/location'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      print('🔴 Update Driver Location Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Check for ride requests
  static Future<Map<String, dynamic>> checkRideRequests(
      {double radius = 5.0}) async {
    try {
      final uri = Uri.parse('$baseUrl/driver/ride-requests').replace(
        queryParameters: {'radius': radius.toString()},
      );

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Check Ride Requests Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Deny a ride request
  static Future<Map<String, dynamic>> denyRide(String rideId,
      {String? reason}) async {
    try {
      final requestBody =
          reason != null ? {'reason': reason} : <String, dynamic>{};

      print('❌ API: Denying ride');
      print('❌ URL: $baseUrl/ride/$rideId/deny');
      final headers = await _getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/ride/$rideId/deny'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('❌ Response Status: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Deny Ride Error: $e');
      rethrow;
    }
  }

  // Get driver profile
  static Future<Map<String, dynamic>> getDriverProfile(int userId) async {
    try {
      final response = await _makeRequest((headers) => http.get(
          Uri.parse('$baseUrl/drivers/profile/$userId'),
          headers: headers));
      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Driver Profile Error: $e');
      rethrow;
    }
  }

  // ===== CHAT METHODS =====

  // Get chat access token
  static Future<Map<String, dynamic>> getChatToken() async {
    try {
      print('💬 API: Getting chat access token');
      print('💬 URL: $baseUrl/chat/token');

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/token'),
        headers: headers,
      );

      print('💬 Response Status: ${response.statusCode}');
      print('💬 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Chat Token Error: $e');
      rethrow;
    }
  }

  // Start ride chat
  static Future<Map<String, dynamic>> startRideChat(int rideId,
      {int? userId}) async {
    try {
      final requestBody = userId != null ? {'userId': userId} : {};

      print('💬 API: Starting ride chat');
      print('💬 URL: $baseUrl/chat/rides/$rideId/start');
      final headers = await _getHeaders();
      print('💬 Headers: $headers');
      print('💬 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/chat/rides/$rideId/start'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('💬 Response Status: ${response.statusCode}');
      print('💬 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Start Ride Chat Error: $e');
      rethrow;
    }
  }

  // End ride chat
  static Future<Map<String, dynamic>> endRideChat(int rideId,
      {int? userId}) async {
    try {
      final requestBody = userId != null ? {'userId': userId} : {};

      print('💬 API: Ending ride chat');
      print('💬 URL: $baseUrl/chat/rides/$rideId/end');
      final headers = await _getHeaders();
      print('💬 Headers: $headers');
      print('💬 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/chat/rides/$rideId/end'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('💬 Response Status: ${response.statusCode}');
      print('💬 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 End Ride Chat Error: $e');
      rethrow;
    }
  }

// CALLS METHODS — FIXED (no body!)
// REPLACE YOUR OLD initiateRideCall WITH THIS ONE
  static Future<Map<String, dynamic>> initiateRideCall(int rideId) async {
    try {
      print('API: Driver calling passenger for ride $rideId');
      print('URL: $baseUrl/calls/rides/$rideId/initiate');

      final headers = await _getHeaders();
      headers.remove('Content-Type'); // THIS FIXES 400 BAD REQUEST!

      final response = await http.post(
        Uri.parse('$baseUrl/calls/rides/$rideId/initiate'),
        headers: headers,
      );

      print('Call Response: ${response.statusCode}');
      print('Call Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Call failed: ${response.body}');
      }
    } catch (e) {
      print('Call Error: $e');
      rethrow;
    }
  }

  // End voice call
  static Future<Map<String, dynamic>> endCall(String callSid) async {
    try {
      print('📞 API: Ending voice call');
      print('📞 URL: $baseUrl/calls/$callSid/end');
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/calls/$callSid/end'),
        headers: headers,
      );

      print('📞 Response Status: ${response.statusCode}');
      print('📞 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 End Call Error: $e');
      rethrow;
    }
  }

  // Get call status
  static Future<Map<String, dynamic>> getCallStatus(String callSid) async {
    try {
      final uri = Uri.parse('$baseUrl/calls/$callSid/status');

      print('📞 API: Getting call status');
      print('📞 URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('📞 Response Status: ${response.statusCode}');
      print('📞 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Call Status Error: $e');
      rethrow;
    }
  }

  // ===== PAYMENT METHODS =====

  // Create payment intent for ride
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int rideId,
    int? amountCents,
  }) async {
    try {
      final requestBody = {
        'rideId': rideId,
        if (amountCents != null) 'amountCents': amountCents,
      };

      print('💳 API: Creating payment intent');
      print('💳 URL: $baseUrl/payments/intent');
      final headers = await _getHeaders();
      print('💳 Headers: $headers');
      print('💳 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/payments/intent'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('💳 Response Status: ${response.statusCode}');
      print('💳 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Create Payment Intent Error: $e');
      rethrow;
    }
  }

  // Get payment status
  static Future<Map<String, dynamic>> getPaymentStatus(int rideId) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/$rideId/status');

      print('💳 API: Getting payment status');
      print('💳 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('💳 Response Status: ${response.statusCode}');
      print('💳 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Payment Status Error: $e');
      rethrow;
    }
  }

  // Get payment receipt
  static Future<Map<String, dynamic>> getPaymentReceipt(int rideId) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/$rideId/receipt');

      print('📄 API: Getting payment receipt');
      print('📄 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('📄 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Payment Receipt Error: $e');
      rethrow;
    }
  }

  // Get payment receipt PDF
  static Future<http.StreamedResponse> getPaymentReceiptPdf(int rideId) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/$rideId/receipt/pdf');

      print('📄 API: Getting payment receipt PDF');
      print('📄 URL: $uri');

      final headers = await _getHeaders();
      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      final response = await request.send();

      print('📄 Response Status: ${response.statusCode}');

      return response;
    } catch (e) {
      print('🔴 Get Payment Receipt PDF Error: $e');
      rethrow;
    }
  }

  // ===== RATINGS METHODS =====

  // Submit rating and feedback for a ride (legacy method)
  static Future<Map<String, dynamic>> submitRatingLegacy(
      Map<String, dynamic> ratingData) async {
    try {
      print('⭐ API: Submitting rating');
      print('⭐ URL: $baseUrl/ratings');
      final headers = await _getHeaders();
      print('⭐ Headers: $headers');
      print('⭐ Body: ${jsonEncode(ratingData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: headers,
        body: jsonEncode(ratingData),
      );

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Submit Rating Error: $e');
      rethrow;
    }
  }

  // Get driver ratings and analytics
  static Future<Map<String, dynamic>> getDriverRatings(int driverId) async {
    try {
      final uri = Uri.parse('$baseUrl/ratings/driver/$driverId');

      print('⭐ API: Getting driver ratings');
      print('⭐ URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Driver Ratings Error: $e');
      rethrow;
    }
  }

  // Get detailed driver rating analytics
  static Future<Map<String, dynamic>> getDriverRatingAnalytics(
      int driverId) async {
    try {
      final uri = Uri.parse('$baseUrl/ratings/driver/$driverId/analytics');

      print('⭐ API: Getting driver rating analytics');
      print('⭐ URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Driver Rating Analytics Error: $e');
      rethrow;
    }
  }

  // Get ratings for a specific ride
  static Future<Map<String, dynamic>> getRideRatings(int rideId) async {
    try {
      final uri = Uri.parse('$baseUrl/ratings/ride/$rideId');

      print('⭐ API: Getting ride ratings');
      print('⭐ URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Ride Ratings Error: $e');
      rethrow;
    }
  }

  // Get platform-wide rating statistics
  static Future<Map<String, dynamic>> getPlatformRatingStats() async {
    try {
      final uri = Uri.parse('$baseUrl/ratings/platform-stats');

      print('⭐ API: Getting platform rating stats');
      print('⭐ URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Platform Rating Stats Error: $e');
      rethrow;
    }
  }

  // Get recent ratings across platform
  static Future<Map<String, dynamic>> getRecentRatings() async {
    try {
      final uri = Uri.parse('$baseUrl/ratings/recent');

      print('⭐ API: Getting recent ratings');
      print('⭐ URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Recent Ratings Error: $e');
      rethrow;
    }
  }

  // Get ratings that need moderation
  static Future<Map<String, dynamic>> getRatingsForModeration() async {
    try {
      final uri = Uri.parse('$baseUrl/ratings/moderation');

      print('⭐ API: Getting ratings for moderation');
      print('⭐ URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Ratings For Moderation Error: $e');
      rethrow;
    }
  }

  // Delete a rating
  static Future<Map<String, dynamic>> deleteRating(int ratingId) async {
    try {
      print('⭐ API: Deleting rating');
      print('⭐ URL: $baseUrl/ratings/$ratingId');
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/ratings/$ratingId'),
        headers: headers,
      );

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Delete Rating Error: $e');
      rethrow;
    }
  }

  // ===== USER PROFILE METHODS =====

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final uri = Uri.parse('$baseUrl/users/profile/$userId');

      print('👤 API: Getting user profile');
      print('👤 URL: $uri');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('👤 Response Status: ${response.statusCode}');
      print('👤 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get User Profile Error: $e');
      rethrow;
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile(
      int userId, Map<String, dynamic> profileData) async {
    try {
      print('👤 API: Updating user profile');
      print('👤 URL: $baseUrl/users/edit-profile/$userId');
      final headers = await _getHeaders();
      print('👤 Headers: $headers');
      print('👤 Body: ${jsonEncode(profileData)}');

      final response = await http.patch(
        Uri.parse('$baseUrl/users/edit-profile/$userId'),
        headers: headers,
        body: jsonEncode(profileData),
      );

      print('👤 Response Status: ${response.statusCode}');
      print('👤 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Update User Profile Error: $e');
      rethrow;
    }
  }

  // ===== WEBSOCKET CHAT METHODS =====

  // Get chat info for a ride (rider details)
  static Future<Map<String, dynamic>> getChatInfo(String rideId) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/rides/$rideId/info');

      print('💬 API: Getting chat info');
      print('💬 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('💬 Response Status: ${response.statusCode}');
      print('💬 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Chat Info Error: $e');
      rethrow;
    }
  }

  // Get chat messages for a ride
  static Future<Map<String, dynamic>> getChatMessages(
    String rideId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl/chat/rides/$rideId/messages').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('💬 API: Getting chat messages');
      print('💬 URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('💬 Response Status: ${response.statusCode}');
      print('💬 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Get Chat Messages Error: $e');
      rethrow;
    }
  }

  // Send chat message (REST fallback)
  static Future<Map<String, dynamic>> sendChatMessage(
    String rideId,
    String message, {
    String messageType = 'text',
  }) async {
    try {
      final requestBody = {
        'message': message,
        'messageType': messageType,
      };

      print('💬 API: Sending chat message');
      print('💬 URL: $baseUrl/chat/rides/$rideId/messages');
      final headers = await _getHeaders();
      print('💬 Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/chat/rides/$rideId/messages'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('💬 Response Status: ${response.statusCode}');
      print('💬 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Send Chat Message Error: $e');
      rethrow;
    }
  }

  // Mark messages as read
  static Future<Map<String, dynamic>> markMessagesAsRead(String rideId) async {
    try {
      print('💬 API: Marking messages as read');
      print('💬 URL: $baseUrl/chat/rides/$rideId/messages/read');

      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/chat/rides/$rideId/messages/read'),
        headers: headers,
      );

      print('💬 Response Status: ${response.statusCode}');
      print('💬 Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Mark Messages As Read Error: $e');
      rethrow;
    }
  }

  // ===== RATINGS METHODS =====

  // Submit rating for a ride
  static Future<Map<String, dynamic>> submitRating({
    required int rideId,
    required int rating,
    String? feedback,
    List<String>? categories,
  }) async {
    try {
      final requestBody = {
        'rideId': rideId,
        'rating': rating,
        if (feedback != null) 'feedback': feedback,
        if (categories != null && categories.isNotEmpty)
          'categories': categories,
      };

      print('⭐ API: Submitting rating');
      print('⭐ URL: $baseUrl/ratings');
      final headers = await _getHeaders();
      print('⭐ Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Submit Rating Error: $e');
      rethrow;
    }
  }

  // Check if user has rated a ride
  static Future<Map<String, dynamic>> checkRideRating(int rideId) async {
    try {
      final uri = Uri.parse('$baseUrl/ratings/ride/$rideId');

      print('⭐ API: Checking ride rating');
      print('⭐ URL: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('⭐ Response Status: ${response.statusCode}');
      print('⭐ Response Body: ${response.body}');

      return jsonDecode(response.body);
    } catch (e) {
      print('🔴 Check Ride Rating Error: $e');
      rethrow;
    }
  }

  // Get route between two points (using OSRM)
  static Future<Map<String, dynamic>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      // Using OSRM public routing API
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson&steps=true',
      );

      print('🗺️ API: Getting route');
      print('🗺️ URL: $uri');

      final response = await http.get(uri);

      print('🗺️ Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get route');
      }
    } catch (e) {
      print('🔴 Get Route Error: $e');
      rethrow;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );
    } catch (e) {
      print('Logout error: $e');
    }
    await clearAuthToken();
  }
}
