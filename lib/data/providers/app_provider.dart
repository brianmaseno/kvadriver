import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  Driver? _currentDriver;
  bool _isAuthenticated = false;
  String? _currentPhone;
  int? _currentUserId;
  Map<String, dynamic>? _registrationData;
  Map<String, dynamic>? _currentUserData; // Store user data from login
  bool _initialized = false;

  Driver? get currentDriver => _currentDriver;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentPhone => _currentPhone;
  int? get currentUserId => _currentUserId;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  bool get isInitialized => _initialized;

  /// Normalize phone number to E.164 format with + prefix
  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');

    // Already has + prefix
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Kenyan format without + (e.g., 254XXXXXXXXX)
    if (cleaned.startsWith('254') && cleaned.length >= 12) {
      return '+$cleaned';
    }

    // Kenyan local format (07XXXXXXXX or 7XXXXXXXX)
    if (RegExp(r'^0?7\d{8}$').hasMatch(cleaned)) {
      return '+254${cleaned.substring(cleaned.length - 9)}';
    }

    // US format (10 digits or 1 + 10 digits)
    if (RegExp(r'^1?\d{10}$').hasMatch(cleaned)) {
      final digits = cleaned.substring(cleaned.length - 10);
      return '+1$digits';
    }

    // Default: add + prefix
    return '+$cleaned';
  }

  // Set current phone number (used during signup flow)
  void setCurrentPhone(String phone) {
    _currentPhone = _normalizePhoneNumber(phone);
    notifyListeners();
  }

  // Initialize authentication state from stored data
  Future<void> initializeAuth() async {
    if (_initialized) return;

    try {
      final token = await TokenService.getAccessToken();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final phone = prefs.getString('user_phone');
      final userDataString = prefs.getString('user_data');

      if (token != null && token.isNotEmpty) {
        await ApiService.setAuthToken(token);
        _isAuthenticated = true;
        if (userId != null) _currentUserId = userId;
        if (phone != null) _currentPhone = phone;

        // Load stored user data
        if (userDataString != null) {
          try {
            _currentUserData =
                Map<String, dynamic>.from(json.decode(userDataString));
          } catch (e) {
            print('Failed to parse stored user data: $e');
          }
        }
      }
    } catch (e) {
      print('Auth initialization failed: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  // Request OTP for login
  Future<bool> requestOtp(String phone) async {
    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      print('📱 Requesting OTP for phone: $normalizedPhone (original: $phone)');

      final response = await ApiService.requestOtp(normalizedPhone);
      print('📱 OTP Request Response: $response');

      if (response['success'] == true) {
        _currentPhone = normalizedPhone;
        return true;
      }

      // Handle specific error cases
      final error = response['error']?.toString() ?? '';
      if (error.contains('Too many requests') || error.contains('429')) {
        print('⚠️ Rate limited - wait before trying again');
      } else if (error.isNotEmpty) {
        print('⚠️ OTP request error: $error');
      }

      return false;
    } catch (e) {
      print('🔴 OTP request failed: $e');
      return false;
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      print('🔐 Verifying OTP for phone: $normalizedPhone');

      final response = await ApiService.verifyOtp(normalizedPhone, otp);
      if (response['accessToken'] != null) {
        await ApiService.setAuthToken(response['accessToken']);

        // Save tokens
        await TokenService.saveTokens(
          response['accessToken'],
          response['refreshToken'] ?? response['accessToken'],
        );

        _isAuthenticated = true;
        _currentPhone = normalizedPhone;
        _currentUserId = response['user']?['id'];
        _currentUserData = response['user'];

        final prefs = await SharedPreferences.getInstance();
        if (_currentUserId != null)
          await prefs.setInt('user_id', _currentUserId!);
        await prefs.setString('user_phone', normalizedPhone);

        // Save user data
        if (_currentUserData != null) {
          await prefs.setString('user_data', json.encode(_currentUserData!));
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('OTP verification failed: $e');
      return false;
    }
  }

  // Store registration data (no API call yet)
  void storeRegistrationData(String name, Map<String, dynamic> data) {
    _registrationData = {
      'name': name,
      ...data,
    };
  }

  // Register user
  Future<bool> registerUser(
      String name, String email, String phone, String city) async {
    try {
      final normalizedPhone = _normalizePhoneNumber(phone);
      print('👤 AppProvider: Starting user registration');
      print(
          '👤 Name: $name, Email: $email, Phone: $normalizedPhone (original: $phone), City: $city');

      final nameParts = name.trim().split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      String lastName = nameParts.length >= 2 ? nameParts.last : 'Driver';

      final userData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': normalizedPhone,
        'role': 'driver',
      };

      print('👤 User data prepared: $userData');

      final response = await ApiService.registerUser(userData);
      print('👤 Registration response: $response');

      // Check if user already exists - this is actually success for our flow
      if (response.containsKey('error') && response['error'] != null) {
        final errorMsg = response['error'].toString().toLowerCase();
        print('👤 Error message: "$errorMsg"');
        if (errorMsg.contains('already registered') ||
            errorMsg.contains('phone number already')) {
          print('👤 User already exists - proceeding to OTP');
          return true;
        }
        print('👤 Other error: $errorMsg');
        return false;
      }

      final success = response['success'] == true ||
          response['message'] != null ||
          response['data'] != null;
      print('👤 Registration success: $success');

      return success;
    } catch (e) {
      print('🔴 User registration failed: $e');
      return false;
    }
  }

  // Complete driver registration with vehicle info
  Future<bool> completeDriverRegistration(
      Map<String, dynamic> vehicleData) async {
    if (_currentUserId == null) {
      print('🔴 No userId available for driver registration');
      return false;
    }
    try {
      print('🚗 AppProvider: Starting driver registration');
      print('🚗 UserId: $_currentUserId');
      print('🚗 Vehicle data: $vehicleData');

      final driverData = {
        'ssn': 'SSN-${DateTime.now().millisecondsSinceEpoch}'
      };

      print('🚗 Driver data: $driverData');
      print('🚗 Final vehicle data: $vehicleData');

      final response = await ApiService.registerDriver(
          _currentUserId!, driverData, vehicleData);
      print('🚗 Driver registration response: $response');

      // Check if driver profile already exists or access denied (403) - treat as success
      if (response.containsKey('error') && response['error'] != null) {
        final errorMsg = response['error'].toString().toLowerCase();
        print('🚗 Error message: "$errorMsg"');
        if (errorMsg.contains('driver profile already exists') ||
            errorMsg.contains('already exists') ||
            errorMsg.contains('access denied') ||
            errorMsg.contains('already registered')) {
          print('🚗 Driver already registered - proceeding to home');
          await _markDriverRegistrationComplete();
          _registrationData = null;
          notifyListeners();
          return true;
        }
        print('🚗 Other error: $errorMsg');
        return false;
      }

      // Check message field as well
      if (response.containsKey('message') && response['message'] != null) {
        final msg = response['message'].toString().toLowerCase();
        if (msg.contains('access denied') || msg.contains('already')) {
          print(
              '🚗 Driver already registered (from message) - proceeding to home');
          await _markDriverRegistrationComplete();
          _registrationData = null;
          notifyListeners();
          return true;
        }
      }

      final success = response['success'] == true ||
          response['message'] != null ||
          response['data'] != null;
      print('🚗 Driver registration success: $success');

      if (success) {
        await _markDriverRegistrationComplete();
        _registrationData = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('🔴 Driver registration failed: $e');
      return false;
    }
  }

  // Mark driver registration as complete in local storage
  Future<void> _markDriverRegistrationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_registration_complete', true);
    if (_currentUserId != null) {
      await prefs.setBool(
          'driver_registration_complete_${_currentUserId}', true);
    }
  }

  // Check if driver has completed registration
  Future<bool> hasCompletedDriverRegistration() async {
    if (_currentUserId == null) {
      print('No userId available for checking driver registration');
      return false;
    }

    // First check local storage
    final prefs = await SharedPreferences.getInstance();
    final isComplete =
        prefs.getBool('driver_registration_complete_${_currentUserId}') ??
            false;
    if (isComplete) {
      print('Driver registration already complete (from local storage)');
      return true;
    }

    try {
      final response = await ApiService.registerDriver(
          _currentUserId!, {'ssn': 'CHECK'}, {});
      // If error says "already exists", driver is registered
      if (response.containsKey('error') && response['error'] != null) {
        final errorMsg = response['error'].toString().toLowerCase();
        if (errorMsg.contains('already exists')) {
          print('Driver profile exists - registration complete');
          await _markDriverRegistrationComplete();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking driver registration: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await ApiService.logout();
    await TokenService.clearTokens();

    _currentDriver = null;
    _isAuthenticated = false;
    _currentPhone = null;
    _currentUserId = null;
    _currentUserData = null;
    _registrationData = null;
    _initialized = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_phone');
    await prefs.remove('user_data');
    // Don't remove driver registration status on logout - it's permanent

    notifyListeners();
  }
}
