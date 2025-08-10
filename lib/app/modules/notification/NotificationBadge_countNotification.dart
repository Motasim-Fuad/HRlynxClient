import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/notification_services.dart' show NotificationService;
import 'package:hr/app/modules/profile/logoutHelper.dart' show LogoutController;
import 'notification_view.dart';

// Notification Badge Widget for AppBar
class NotificationBadge extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBadge({
    Key? key,
    this.iconColor,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make sure notification service is registered
    if (!Get.isRegistered<NotificationService>()) {
      return IconButton(
        onPressed: () => Get.to(() => const NotificationView()),
        icon: Icon(
          Icons.notifications_outlined,
          color: iconColor ?? Colors.white,
          size: iconSize,
        ),
      );
    }

    final notificationService = NotificationService.instance;

    return Obx(() => Stack(
      children: [
        IconButton(
          onPressed: () => Get.to(() => const NotificationView()),
          icon: Icon(
            Icons.notifications_outlined,
            color: iconColor ?? Colors.white,
            size: iconSize,
          ),
        ),
        if (notificationService.unreadCount.value > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                notificationService.unreadCount.value > 99
                    ? '99+'
                    : '${notificationService.unreadCount.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    ));
  }
}

// Notification Bell Widget for Dashboard
class NotificationBell extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showBadge;

  const NotificationBell({
    Key? key,
    this.size = 32.0,
    this.color,
    this.showBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationService>()) {
      return GestureDetector(
        onTap: () => Get.to(() => const NotificationView()),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: size,
            color: color ?? Colors.black87,
          ),
        ),
      );
    }

    final notificationService = NotificationService.instance;

    return Obx(() => GestureDetector(
      onTap: () => Get.to(() => const NotificationView()),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              size: size,
              color: color ?? Colors.black87,
            ),
            if (showBadge && notificationService.unreadCount.value > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationService.unreadCount.value > 9
                        ? '9+'
                        : '${notificationService.unreadCount.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }
}

// Connection Status Widget
class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationService>()) {
      return const SizedBox.shrink();
    }

    final notificationService = NotificationService.instance;

    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: notificationService.isConnected.value
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notificationService.isConnected.value
              ? Colors.green
              : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
                  ? Colors.green[700]
                  : Colors.red[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ));
  }
}

// Example usage in your main screen:
class MainScreenExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your App'),
        actions: [
          // Add notification badge to app bar
          const NotificationBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Connection status at top
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ConnectionStatusWidget(),
              ],
            ),
          ),

          // Your main content here
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Your Main Content'),
                  const SizedBox(height: 20),

                  // Notification bell widget
                  const NotificationBell(),

                  const SizedBox(height: 20),

                  // Logout button example
                  ElevatedButton(
                    onPressed: () {
                      Get.find<LogoutController>().logout();
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}