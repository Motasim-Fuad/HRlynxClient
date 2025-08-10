import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/notification_services.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();

    // final filteredNotifications = notificationService.notifications
    //     .where((n) => n.notificationType.toLowerCase() == 'in_app')
    //     .toList();

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
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // WebSocket connection indicator
          Obx(() => Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notificationService.isConnected.value
                        ? Colors.green
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  notificationService.isConnected.value ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: notificationService.isConnected.value
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),
          // Mark all as read button
          Obx(() => notificationService.unreadCount.value > 0
              ? IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              try {
                await notificationService.markAllAsRead();
                Get.snackbar(
                  'Success',
                  'All notifications marked as read',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              } catch (e) {
                print('❌ Error marking all as read: $e');
                Get.snackbar(
                  'Error',
                  'Failed to mark all as read',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
          )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          // Header with unread count and connection status
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
                // Connection status
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
                    await notificationService.fetchAllNotifications();
                  } catch (e) {
                    print('❌ Error refreshing notifications: $e');
                    Get.snackbar(
                      'Error',
                      'Failed to refresh notifications',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },


                // show all notification "in app , eamil ,push"

                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notificationService.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationService.notifications[index];
                    return NotificationTile(
                      notification: notification,
                      onTap: () => _handleNotificationTap(context, notification, notificationService),
                    );
                  },
                ),


                // // show just in app notification
                // child: ListView.builder(
                //   padding: const EdgeInsets.symmetric(vertical: 8),
                //   itemCount: filteredNotifications.length,
                //   itemBuilder: (context, index) {
                //     final notification = filteredNotifications[index];
                //     return NotificationTile(
                //       notification: notification,
                //       onTap: () => _handleNotificationTap(context, notification, notificationService),
                //     );
                //   },
                // ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Fixed notification tap handler with proper error handling
  Future<void> _handleNotificationTap(
      BuildContext context,
      NotificationModel notification,
      NotificationService notificationService
      ) async {
    try {
      print('🎯 Notification tapped: ${notification.id} - ${notification.title}');

      // Mark as read if not already read
      if (!notification.isRead) {
        print('📖 Marking notification ${notification.id} as read...');
        final success = await notificationService.markAsRead(notification.id);
        if (success) {
          print('✅ Successfully marked notification ${notification.id} as read');
        } else {
          print('❌ Failed to mark notification ${notification.id} as read');
        }
      }

      // Show notification detail
      _showNotificationDetail(context, notification);

    } catch (e, stackTrace) {
      print('❌ Error handling notification tap: $e');
      print('📍 Stack trace: $stackTrace');

      // Show user-friendly error message
      if (context.mounted) {
        Get.snackbar(
          'Error',
          'Failed to open notification',
          snackPosition: SnackPosition.BOTTOM,
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

      // Fallback: show simple dialog
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
                // Notification icon
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

                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
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

                      // Message
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

                      // Time and type
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
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.notificationType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              notification.notificationType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getNotificationColor(notification.notificationType),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread indicator
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
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
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

                  // Message content
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

                  // Additional data
                  // if (notification.data.isNotEmpty) ...[
                  //   const Text(
                  //     'Additional Information',
                  //     style: TextStyle(
                  //       fontSize: 18,
                  //       fontWeight: FontWeight.w600,
                  //       color: Colors.black87,
                  //     ),
                  //   ),
                  //   const SizedBox(height: 12),
                  //   Container(
                  //     width: double.infinity,
                  //     padding: const EdgeInsets.all(16),
                  //     decoration: BoxDecoration(
                  //       color: Colors.blue[50],
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(color: Colors.blue[100]!),
                  //     ),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: notification.data.entries.map((entry) {
                  //         return Padding(
                  //           padding: const EdgeInsets.only(bottom: 8),
                  //           child: Row(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children: [
                  //               SizedBox(
                  //                 width: 100,
                  //                 child: Text(
                  //                   '${entry.key}:',
                  //                   style: TextStyle(
                  //                     fontWeight: FontWeight.w600,
                  //                     color: Colors.blue[700],
                  //                   ),
                  //                 ),
                  //               ),
                  //               Expanded(
                  //                 child: Text(
                  //                   entry.value?.toString() ?? 'N/A',
                  //                   style: TextStyle(
                  //                     color: Colors.blue[600],
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         );
                  //       }).toList(),
                  //     ),
                  //   ),
                  //   const SizedBox(height: 24),
                  // ],

                  // Metadata
                  // const Text(
                  //   'Notification Details',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.w600,
                  //     color: Colors.black87,
                  //   ),
                  // ),
                  // const SizedBox(height: 12),
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey[50],
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(color: Colors.grey[200]!),
                  //   ),
                  //   child: Column(
                  //     children: [
                  //       _buildDetailRow(
                  //           'ID',
                  //           notification.id.toString(),
                  //           Icons.tag
                  //       ),
                  //       _buildDetailRow(
                  //           'Type',
                  //           notification.notificationType.toUpperCase(),
                  //           Icons.category
                  //       ),
                  //       _buildDetailRow(
                  //           'Created',
                  //           _formatDateTime(notification.createdAt),
                  //           Icons.schedule
                  //       ),
                  //       if (notification.sentAt != null)
                  //         _buildDetailRow(
                  //             'Sent',
                  //             _formatDateTime(notification.sentAt!),
                  //             Icons.send
                  //         ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildDetailRow(String label, String value, IconData icon) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Icon(
  //           icon,
  //           size: 20,
  //           color: Colors.grey[600],
  //         ),
  //         const SizedBox(width: 12),
  //         SizedBox(
  //           width: 80,
  //           child: Text(
  //             '$label:',
  //             style: TextStyle(
  //               fontWeight: FontWeight.w600,
  //               color: Colors.grey[700],
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value,
  //             style: TextStyle(
  //               color: Colors.grey[600],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // String _formatDateTime(String dateTimeString) {
  //   try {
  //     final dateTime = DateTime.parse(dateTimeString);
  //     return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  //   } catch (e) {
  //     print('❌ Error formatting date: $e');
  //     return 'Invalid date';
  //   }
  // }

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
          // Refresh button
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