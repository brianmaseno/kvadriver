import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final response = await ApiService.getNotifications(
        page: 1,
        limit: _pageSize,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          _hasMore = data['pagination']?['hasMore'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getNotifications(
        page: _currentPage + 1,
        limit: _pageSize,
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _notifications.addAll(
            List<Map<String, dynamic>>.from(data['notifications'] ?? []),
          );
          _currentPage++;
          _hasMore = data['pagination']?['hasMore'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading more notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    try {
      await ApiService.markNotificationAsRead(id);
      setState(() {
        _notifications[index]['isRead'] = true;
        _notifications[index]['readAt'] = DateTime.now().toIso8601String();
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
          notification['readAt'] = DateTime.now().toIso8601String();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(int id, int index) async {
    try {
      await ApiService.deleteNotification(id);
      setState(() {
        _notifications.removeAt(index);
      });
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'ride_requested':
        return Icons.local_taxi;
      case 'ride_accepted':
        return Icons.check_circle;
      case 'ride_started':
        return Icons.play_circle;
      case 'ride_completed':
        return Icons.flag;
      case 'ride_cancelled':
        return Icons.cancel;
      case 'payment_received':
        return Icons.payment;
      case 'rating_received':
        return Icons.star;
      case 'driver_approved':
        return Icons.verified;
      case 'driver_rejected':
        return Icons.block;
      case 'chat_message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'ride_requested':
        return Colors.blue;
      case 'ride_accepted':
        return Colors.green;
      case 'ride_started':
        return Colors.orange;
      case 'ride_completed':
        return Colors.green;
      case 'ride_cancelled':
        return Colors.red;
      case 'payment_received':
        return Colors.green;
      case 'rating_received':
        return Colors.amber;
      case 'driver_approved':
        return Colors.green;
      case 'driver_rejected':
        return Colors.red;
      case 'chat_message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return timeago.format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: _isLoading && _notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _notifications.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildNotificationItem(
                        _notifications[index],
                        index,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will see ride requests and updates here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    final type = notification['type'] ?? 'system';
    final isRead = notification['isRead'] == true;
    final id = notification['id'];

    return Dismissible(
      key: Key('notification_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(id, index),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(id, index);
          }
          _handleNotificationTap(notification);
        },
        child: Container(
          color: isRead ? null : Colors.blue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'Notification',
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['body'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification['createdAt']),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final rideId = notification['rideId'] ?? data['rideId'];

    switch (type) {
      case 'ride_requested':
      case 'ride_accepted':
      case 'ride_started':
      case 'ride_completed':
      case 'ride_cancelled':
        if (rideId != null) {
          // Navigate to ride details
          Navigator.of(context).pushNamed('/ride-details', arguments: rideId);
        }
        break;
      case 'payment_received':
        Navigator.of(context).pushNamed('/earnings');
        break;
      case 'rating_received':
        Navigator.of(context).pushNamed('/ratings');
        break;
      case 'chat_message':
        if (rideId != null) {
          Navigator.of(context).pushNamed('/chat', arguments: rideId);
        }
        break;
      default:
        // Just mark as read, no navigation
        break;
    }
  }
}
