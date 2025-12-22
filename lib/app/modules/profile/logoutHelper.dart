// Updated LogoutController
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/log_in_view.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class LogoutController extends GetxController {
  final AuthRepository authRepo = AuthRepository();
  final isLoading = false.obs;

  Future<void> logout() async {
    try {
      isLoading.value = true;




      // Disconnect notification service FIRST
      await cleanupNotificationService();

      // Call logout API
      await authRepo.LogOut();

      try {
        await Purchases.logOut();
        print('✅ RevenueCat logged out successfully');
      } catch (e) {
        print('⚠️ RevenueCat logout failed (non-critical): $e');
      }

      // Clear all tokens
      await TokenStorage.clearAllTokens();
      await TokenStorage.clearAllPersonaSessions();

      Get.snackbar("Success", "Logged out successfully");

      // Navigate to login screen
      Get.offAll(() => LogInView());

    } catch (e) {
      Get.snackbar("Error", "Logout failed: ${e.toString()}");
      print('❌ Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Cleanup notification service
  Future<void> cleanupNotificationService() async {
    try {
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = NotificationService.instance;

        // Disconnect WebSocket properly
        await notificationService.disconnectWebSocket();

        // Clear notifications
        notificationService.clearAllNotifications();

        print('✅ Notification service cleaned up successfully');
      }
    } catch (e) {
      print('❌ Error cleaning up notification service: $e');
    }
  }
}