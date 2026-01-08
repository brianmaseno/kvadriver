// lib/screens/rides/ride_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/services/websocket_chat_service.dart';
import '../../data/services/api_service.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;
  final String? riderName;

  const RideChatScreen({
    super.key,
    required this.rideId,
    this.riderName,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = true;
  Map<String, dynamic>? _partnerInfo;
  String? _errorMessage;
  bool _showPartnerDetails = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);

    try {
      // Get chat info via REST first
      final response = await ApiService.getChatInfo(widget.rideId);
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _partnerInfo = response['data']['partner'];
        });
      }
    } catch (e) {
      print('Error getting chat info: $e');
    }

    // Connect to WebSocket and join chat
    final chatService = context.read<WebSocketChatService>();
    await chatService.connect();
    await chatService.joinRideChat(widget.rideId);

    setState(() => _isLoading = false);

    // Scroll to bottom after messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatService = context.read<WebSocketChatService>();
    chatService.sendMessage(message);
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open phone dialer')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    // Leave chat room
    final chatService = context.read<WebSocketChatService>();
    chatService.leaveRideChat();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketChatService>(
      builder: (context, chatService, _) {
        // Update partner info from WebSocket if available
        final partner = chatService.partnerInfo ?? _partnerInfo;
        final messages = chatService.messages;
        final isTyping = chatService.isPartnerTyping;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0066CC),
            foregroundColor: Colors.white,
            elevation: 0,
            title: GestureDetector(
              onTap: () =>
                  setState(() => _showPartnerDetails = !_showPartnerDetails),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      partner?['name']
                              ?.toString()
                              .substring(0, 1)
                              .toUpperCase() ??
                          'R',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          partner?['name'] ?? widget.riderName ?? 'Rider',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isTyping)
                          const Text(
                            'typing...',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          const Text(
                            'Passenger',
                            style: TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Call button
              if (partner?['phoneNumber'] != null)
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.white),
                  onPressed: () => _makePhoneCall(partner!['phoneNumber']),
                  tooltip: 'Call Rider',
                ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () =>
                    setState(() => _showPartnerDetails = !_showPartnerDetails),
              ),
            ],
          ),
          body: Column(
            children: [
              // Partner details card (expandable)
              if (_showPartnerDetails && partner != null)
                _buildPartnerDetailsCard(partner),

              // Connection status
              if (!chatService.isConnected)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chatService.isConnecting
                            ? 'Connecting...'
                            : 'Reconnecting...',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message['senderType'] == 'driver';
                              final showDate = index == 0 ||
                                  _shouldShowDate(
                                    messages[index - 1]['createdAt'],
                                    message['createdAt'],
                                  );

                              return Column(
                                children: [
                                  if (showDate)
                                    _buildDateSeparator(message['createdAt']),
                                  _buildMessageBubble(message, isMe),
                                ],
                              );
                            },
                          ),
              ),

              // Typing indicator
              if (isTyping)
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTypingDot(0),
                            _buildTypingDot(1),
                            _buildTypingDot(2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Message input
              _buildMessageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartnerDetailsCard(Map<String, dynamic> partner) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green.shade100,
                child: Text(
                  partner['name']?.toString().substring(0, 1).toUpperCase() ??
                      'R',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner['name'] ?? 'Rider',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Passenger',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Call button
              if (partner['phoneNumber'] != null)
                ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(partner['phoneNumber']),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
          if (partner['phoneNumber'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  partner['phoneNumber'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDate(String? prevDate, String? currentDate) {
    if (prevDate == null || currentDate == null) return true;

    final prev = DateTime.tryParse(prevDate);
    final current = DateTime.tryParse(currentDate);

    if (prev == null || current == null) return false;

    return prev.day != current.day ||
        prev.month != current.month ||
        prev.year != current.year;
  }

  Widget _buildDateSeparator(String? dateStr) {
    if (dateStr == null) return const SizedBox();

    final date = DateTime.tryParse(dateStr);
    if (date == null) return const SizedBox();

    final now = DateTime.now();
    String dateText;

    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Today';
    } else if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final timeStr = message['createdAt'];
    String time = '';
    if (timeStr != null) {
      final dateTime = DateTime.tryParse(timeStr);
      if (dateTime != null) {
        time = DateFormat('HH:mm').format(dateTime.toLocal());
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0066CC) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['message'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message['isRead'] == true ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message['isRead'] == true
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade500,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final chatService = context.read<WebSocketChatService>();

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              onChanged: (value) {
                chatService.sendTyping(value.isNotEmpty);
              },
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0066CC),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
