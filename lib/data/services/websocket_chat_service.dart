// lib/data/services/websocket_chat_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

/// WebSocket chat service for real-time messaging
class WebSocketChatService extends ChangeNotifier {
  static final WebSocketChatService _instance =
      WebSocketChatService._internal();
  factory WebSocketChatService() => _instance;
  WebSocketChatService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _currentRideId;

  // Chat state
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _partnerInfo;
  bool _isPartnerTyping = false;
  int _unreadCount = 0;
  String? _errorMessage;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get currentRideId => _currentRideId;
  List<Map<String, dynamic>> get messages => _messages;
  Map<String, dynamic>? get partnerInfo => _partnerInfo;
  bool get isPartnerTyping => _isPartnerTyping;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;

  /// Connect to chat WebSocket
  Future<bool> connect() async {
    if (_isConnected || _isConnecting) return _isConnected;

    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = ApiService.getAuthToken();
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      // Get base URL without /v1 and extract host
      String baseUrl = ApiService.baseUrl;
      // Remove /v1 suffix if present
      if (baseUrl.endsWith('/v1')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 3);
      }

      _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setPath('/chat-socket')
            .setAuth({'token': token})
            .setQuery({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _setupEventListeners();

      // Wait for connection
      final completer = Completer<bool>();

      _socket!.onConnect((_) {
        print('💬 Chat WebSocket connected');
        _isConnected = true;
        _isConnecting = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(true);
      });

      _socket!.onConnectError((error) {
        print('🔴 Chat WebSocket connection error: $error');
        _errorMessage = 'Connection failed';
        _isConnected = false;
        _isConnecting = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(false);
      });

      // Timeout after 10 seconds
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          _isConnecting = false;
          _errorMessage = 'Connection timeout';
          notifyListeners();
          completer.complete(false);
        }
      });

      return await completer.future;
    } catch (e) {
      print('🔴 Error connecting to chat: $e');
      _errorMessage = 'Connection error: $e';
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Setup socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onDisconnect((_) {
      print('💬 Chat WebSocket disconnected');
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('error', (data) {
      print('🔴 Chat error: $data');
      _errorMessage = data['message'] ?? 'Chat error';
      notifyListeners();
    });

    _socket!.on('chat-joined', (data) {
      print('✅ Joined chat for ride ${data['rideId']}');
      _partnerInfo = data['partner'];
      _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
      _unreadCount = 0;
      notifyListeners();
    });

    _socket!.on('new-message', (data) {
      print('📨 New message received');
      final message = Map<String, dynamic>.from(data);
      _messages.add(message);

      // Increment unread if message is from partner
      if (_partnerInfo != null && message['senderId'] == _partnerInfo!['id']) {
        _unreadCount++;
      }
      notifyListeners();
    });

    _socket!.on('user-typing', (data) {
      _isPartnerTyping = data['isTyping'] == true;
      notifyListeners();

      // Auto-clear typing after 3 seconds
      if (_isPartnerTyping) {
        Timer(const Duration(seconds: 3), () {
          _isPartnerTyping = false;
          notifyListeners();
        });
      }
    });

    _socket!.on('messages-read', (data) {
      // Update message read status
      final readBy = data['readBy'];
      for (var msg in _messages) {
        if (msg['senderId'] != readBy) {
          msg['isRead'] = true;
        }
      }
      notifyListeners();
    });

    _socket!.on('user-joined', (data) {
      print('👋 User ${data['userId']} joined chat');
    });

    _socket!.on('user-left', (data) {
      print('👋 User ${data['userId']} left chat');
    });
  }

  /// Join a ride chat room
  Future<void> joinRideChat(String rideId) async {
    if (!_isConnected) {
      final connected = await connect();
      if (!connected) return;
    }

    _currentRideId = rideId;
    _messages = [];
    _partnerInfo = null;
    _unreadCount = 0;
    notifyListeners();

    _socket?.emit('join-ride-chat', {'rideId': int.tryParse(rideId) ?? rideId});
  }

  /// Leave current ride chat
  void leaveRideChat() {
    if (_currentRideId != null && _socket != null) {
      _socket!.emit('leave-ride-chat',
          {'rideId': int.tryParse(_currentRideId!) ?? _currentRideId});
    }
    _currentRideId = null;
    _messages = [];
    _partnerInfo = null;
    _isPartnerTyping = false;
    notifyListeners();
  }

  /// Send a message
  void sendMessage(String message, {String messageType = 'text'}) {
    if (_currentRideId == null || !_isConnected || message.trim().isEmpty)
      return;

    _socket?.emit('send-message', {
      'rideId': int.tryParse(_currentRideId!) ?? _currentRideId,
      'message': message.trim(),
      'messageType': messageType,
    });
  }

  /// Send typing indicator
  void sendTyping(bool isTyping) {
    if (_currentRideId == null || !_isConnected) return;

    _socket?.emit('typing', {
      'rideId': int.tryParse(_currentRideId!) ?? _currentRideId,
      'isTyping': isTyping,
    });
  }

  /// Mark messages as read
  void markMessagesAsRead() {
    if (_currentRideId == null || !_isConnected) return;

    _socket?.emit('mark-read', {
      'rideId': int.tryParse(_currentRideId!) ?? _currentRideId,
    });
    _unreadCount = 0;
    notifyListeners();
  }

  /// Disconnect from chat
  void disconnect() {
    leaveRideChat();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
