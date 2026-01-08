import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../firebase_options.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📱 Background message: ${message.messageId}');
  // Handle background message here if needed
}

/// Notification types matching backend
class NotificationType {
  static const String newRideRequest = 'new_ride_request';
  static const String rideRequestExpired = 'ride_request_expired';
  static const String rideAccepted = 'ride_accepted';
  static const String rideCancelled = 'ride_cancelled';
  static const String rideCompleted = 'ride_completed';
  static const String paymentReceived = 'payment_received';
  static const String newMessage = 'new_message';
}

/// Notification service for handling push notifications (Driver App)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callbacks for handling notification actions
  Function(String rideId, Map<String, dynamic> rideDetails)? onNewRideRequest;
  Function(String rideId)? onRideRequestExpired;
  Function(String rideId)? onRideCancelled;
  Function(String rideId)? onRideCompleted;
  Function(String rideId, String amount)? onPaymentReceived;
  Function(String rideId, String senderId, String senderName)? onNewMessage;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    await _getFcmToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ NotificationService initialized (Driver)');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true, // Important for driver ride requests
      provisional: false,
      sound: true,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Ride requests channel (HIGH priority for drivers)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'ride_requests',
          'Ride Requests',
          description: 'New ride request notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // Ride updates channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'ride_updates',
          'Ride Updates',
          description: 'Updates about your current ride',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Payments channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'payments',
          'Payments',
          description: 'Payment and earnings notifications',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Messages channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'messages',
          'Messages',
          description: 'Chat messages from riders',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Default channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'default',
          'General',
          description: 'General notifications',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  /// Get FCM token
  Future<String?> _getFcmToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: ${_fcmToken?.substring(0, 20)}...');
      return _fcmToken;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String newToken) {
    debugPrint('📱 FCM Token refreshed');
    _fcmToken = newToken;
    // Re-register with backend
    registerTokenWithBackend();
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification
      _showLocalNotification(
        title: notification.title ?? 'KVA Driver',
        body: notification.body ?? '',
        payload: jsonEncode(data),
        channelId: data['channelId'] ?? 'default',
      );
    }

    // Process notification data
    _processNotificationData(data);
  }

  /// Handle notification tap (when app is in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notification tapped: ${message.data}');
    _processNotificationData(message.data, isTap: true);
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _processNotificationData(data, isTap: true);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Process notification data and trigger callbacks
  void _processNotificationData(Map<String, dynamic> data, {bool isTap = false}) {
    final type = data['type'] as String?;
    final rideId = data['rideId'] as String?;

    if (rideId == null && type != NotificationType.paymentReceived) return;

    switch (type) {
      case NotificationType.newRideRequest:
        final rideDetails = {
          'pickupLat': data['pickupLat'],
          'pickupLng': data['pickupLng'],
          'fare': data['fare'],
        };
        onNewRideRequest?.call(rideId!, rideDetails);
        break;
      case NotificationType.rideRequestExpired:
        onRideRequestExpired?.call(rideId!);
        break;
      case NotificationType.rideCancelled:
        onRideCancelled?.call(rideId!);
        break;
      case NotificationType.rideCompleted:
        onRideCompleted?.call(rideId!);
        break;
      case NotificationType.paymentReceived:
        final amount = data['amount'] as String? ?? '';
        onPaymentReceived?.call(rideId ?? '', amount);
        break;
      case NotificationType.newMessage:
        final senderId = data['senderId'] as String? ?? '';
        final senderName = data['senderName'] as String? ?? '';
        onNewMessage?.call(rideId!, senderId, senderName);
        break;
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: channelId == 'ride_requests' ? Importance.max : Importance.high,
      priority: Priority.high,
      showWhen: true,
      fullScreenIntent: channelId == 'ride_requests', // Full screen for new rides
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'ride_requests':
        return 'Ride Requests';
      case 'ride_updates':
        return 'Ride Updates';
      case 'payments':
        return 'Payments';
      case 'messages':
        return 'Messages';
      default:
        return 'General';
    }
  }

  /// Register FCM token with backend
  Future<bool> registerTokenWithBackend({String? baseUrl}) async {
    if (_fcmToken == null) {
      await _getFcmToken();
    }

    if (_fcmToken == null) {
      debugPrint('❌ No FCM token available');
      return false;
    }

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        debugPrint('❌ No auth token, cannot register FCM token');
        return false;
      }

      final url = baseUrl ?? 'http://localhost:4000';
      final response = await http.post(
        Uri.parse('$url/v1/notifications/register-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcmToken': _fcmToken,
          'deviceType': Platform.isAndroid ? 'android' : 'ios',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token registered with backend');
        return true;
      } else {
        debugPrint('❌ Failed to register FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Unregister token (call on logout)
  Future<void> unregisterToken({String? baseUrl}) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final url = baseUrl ?? 'http://localhost:4000';
      await http.post(
        Uri.parse('$url/v1/notifications/unregister-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('✅ FCM token unregistered');
    } catch (e) {
      debugPrint('❌ Error unregistering FCM token: $e');
    }
  }

  /// Subscribe to a topic (e.g., driver_online for receiving ride requests)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('📱 Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('📱 Unsubscribed from topic: $topic');
  }

  /// Subscribe to driver-specific topics when going online
  Future<void> goOnline() async {
    await subscribeToTopic('drivers_online');
    debugPrint('🟢 Driver online - subscribed to ride requests');
  }

  /// Unsubscribe from driver topics when going offline
  Future<void> goOffline() async {
    await unsubscribeFromTopic('drivers_online');
    debugPrint('🔴 Driver offline - unsubscribed from ride requests');
  }
}
