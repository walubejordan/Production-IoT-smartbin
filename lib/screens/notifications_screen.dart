import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'admin/bin_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _showUnreadOnly = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      final data = await apiService.getNotifications(
        isRead: _showUnreadOnly ? false : null,
      );

      setState(() {
        _notifications = data['data'];
        _unreadCount = data['unread_count'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.markNotificationRead(notificationId);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                _showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showUnreadOnly = !_showUnreadOnly);
              _loadNotifications();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showUnreadOnly
                            ? 'No unread notifications'
                            : 'No notifications',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead =
        notification['is_read'] == 1 || notification['is_read'] == true;
    final type = notification['type'] ?? 'info';

    Color iconColor;
    IconData icon;

    switch (type) {
      case 'critical':
        iconColor = Colors.red;
        icon = Icons.warning_amber;
        break;
      case 'warning':
        iconColor = Colors.orange;
        icon = Icons.info_outline;
        break;
      case 'success':
        iconColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      default:
        iconColor = Colors.blue;
        icon = Icons.notifications_outlined;
    }

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // Delete notification
        setState(() {
          _notifications.removeAt(_notifications.indexOf(notification));
        });
      },
      child: ListTile(
        tileColor: isRead ? null : Colors.blue.shade50,
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['message']),
            if (notification['bin_code'] != null ||
                notification['bin_location'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '${notification['bin_code'] ?? ''}${notification['bin_code'] != null && notification['bin_location'] != null ? ' • ' : ''}${notification['bin_location'] ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDateTime(notification['created_at']),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: !isRead
            ? const Icon(Icons.circle, color: Colors.blue, size: 12)
            : null,
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
          // Navigate to bin details if bin_id exists
          final binId = notification['bin_id'];
          if (binId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BinDetailScreen(binId: binId),
              ),
            );
          }
        },
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Unknown';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
