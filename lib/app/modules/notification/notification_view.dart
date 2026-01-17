import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Obx(() => Column(
              children: [
                Row(
                  children: [
                    Text(
                      'All Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (notificationService.unreadCount.value > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${notificationService.unreadCount.value} unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                if (notificationService.connectionStatus.value != 'Connected')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notificationService.connectionStatus.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )),
          ),

          // Notifications list
          Expanded(
            child: Obx(() {
              if (notificationService.notifications.isEmpty) {
                return const EmptyNotificationsView();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  try {
                    print('🔄 User triggered refresh');
                    await notificationService.fetchAllNotifications();
                    print('✅ Refresh completed');
                  } catch (e) {
                    print('❌ Error refreshing notifications: $e');
                    Get.snackbar(
                      'Error',
                      'Failed to refresh notifications',
                      snackPosition: SnackPosition.TOP,
                    );
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notificationService.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationService.notifications[index];

                    return NotificationTile(
                      key: ValueKey(notification.id), // ✅ ADD UNIQUE KEY
                      notification: notification,
                      onTap: () => _handleNotificationTap(context, notification, notificationService),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(
      BuildContext context,
      NotificationModel notification,
      NotificationService notificationService
      ) async {
    try {
      print('🎯 Notification tapped: ${notification.id} - ${notification.title}');

      if (!notification.isRead) {
        print('📖 Marking notification ${notification.id} as read...');
        final success = await notificationService.markAsRead(notification.id);
        if (success) {
          print('✅ Successfully marked notification ${notification.id} as read');
        } else {
          print('❌ Failed to mark notification ${notification.id} as read');
        }
      }

      _showNotificationDetail(context, notification);

    } catch (e, stackTrace) {
      print('❌ Error handling notification tap: $e');
      print('📍 Stack trace: $stackTrace');

      if (context.mounted) {
        Get.snackbar(
          'Error',
          'Failed to open notification',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _showNotificationDetail(BuildContext context, NotificationModel notification) {
    try {
      print('📱 Showing notification detail for: ${notification.id}');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => NotificationDetailSheet(notification: notification),
      );
    } catch (e) {
      print('❌ Error showing notification detail: $e');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title),
          content: Text(notification.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : Colors.blue[100]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            try {
              print('🎯 Tile tapped for notification: ${notification.id}');
              onTap();
            } catch (e) {
              print('❌ Error in tile onTap: $e');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.notificationType),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.notificationType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title.isNotEmpty ? notification.title : 'No Title',
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Text(
                        notification.message.isNotEmpty ? notification.message : 'No message content',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          // ✅ ID section removed - only time shown
                        ],
                      ),
                    ],
                  ),
                ),

                if (!notification.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    try {
      switch (type.toLowerCase()) {
        case 'email':
          return Colors.orange;
        case 'push':
          return Colors.blue;
        case 'in_app':
          return Colors.green;
        case 'message':
          return Colors.purple;
        case 'update':
          return Colors.teal;
        case 'alert':
          return Colors.red;
        default:
          return Colors.grey;
      }
    } catch (e) {
      print('❌ Error getting notification color: $e');
      return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    try {
      switch (type.toLowerCase()) {
        case 'email':
          return Icons.email;
        case 'push':
          return Icons.notifications;
        case 'in_app':
          return Icons.info;
        case 'message':
          return Icons.message;
        case 'update':
          return Icons.system_update;
        case 'alert':
          return Icons.warning;
        default:
          return Icons.notifications;
      }
    } catch (e) {
      print('❌ Error getting notification icon: $e');
      return Icons.notifications;
    }
  }
}

class NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailSheet({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.notificationType),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.notificationType),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title.isNotEmpty ? notification.title : 'No Title',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    try {
                      Navigator.pop(context);
                    } catch (e) {
                      print('❌ Error closing detail sheet: $e');
                    }
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: notification.isRead ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          notification.isRead ? Icons.check_circle : Icons.circle,
                          size: 16,
                          color: notification.isRead ? Colors.green[700] : Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.isRead ? 'READ' : 'UNREAD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: notification.isRead ? Colors.green[700] : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      notification.message.isNotEmpty ? notification.message : 'No message content available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    try {
      switch (type.toLowerCase()) {
        case 'email':
          return Colors.orange;
        case 'push':
          return Colors.blue;
        case 'in_app':
          return Colors.green;
        case 'message':
          return Colors.purple;
        case 'update':
          return Colors.teal;
        case 'alert':
          return Colors.red;
        default:
          return Colors.grey;
      }
    } catch (e) {
      print('❌ Error getting notification color: $e');
      return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    try {
      switch (type.toLowerCase()) {
        case 'email':
          return Icons.email;
        case 'push':
          return Icons.notifications;
        case 'in_app':
          return Icons.info;
        case 'message':
          return Icons.message;
        case 'update':
          return Icons.system_update;
        case 'alert':
          return Icons.warning;
        default:
          return Icons.notifications;
      }
    } catch (e) {
      print('❌ Error getting notification icon: $e');
      return Icons.notifications;
    }
  }
}

class EmptyNotificationsView extends StatelessWidget {
  const EmptyNotificationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!\nNew notifications will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final notificationService = Get.find<NotificationService>();
                await notificationService.fetchAllNotifications();
              } catch (e) {
                print('❌ Error refreshing notifications: $e');
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}