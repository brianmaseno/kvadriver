import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  static const _userDataKey = 'user_data';
  static const _baseUrl = 'https://kva.it.com/v1';

  static Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    // Calculate expiry time (30 days from now for long session)
    final expiryTime =
        DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
    await _storage.write(key: _tokenExpiryKey, value: expiryTime.toString());
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = await _storage.read(key: _userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getValidAccessToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final expiryString = await _storage.read(key: _tokenExpiryKey);

    if (accessToken == null) return null;

    // If no expiry set, token is still valid (backward compatibility)
    if (expiryString == null) return accessToken;

    final expiryTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));

    // If token expires in less than 1 day, try to refresh it
    if (DateTime.now().isAfter(expiryTime.subtract(const Duration(days: 1)))) {
      final refreshedToken = await refreshAccessToken();
      // If refresh fails, return current token if not expired yet
      if (refreshedToken != null) return refreshedToken;
      if (DateTime.now().isBefore(expiryTime)) return accessToken;
      return null;
    }

    return accessToken;
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: _userDataKey);
  }

  static Future<bool> hasValidTokens() async {
    return await getValidAccessToken() != null;
  }

  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        return newAccessToken;
      }
      return null;
    } catch (e) {
      print('🔴 Token refresh failed: $e');
      return null;
    }
  }
}
