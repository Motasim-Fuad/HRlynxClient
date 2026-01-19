import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/log_in_view.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class LogoutController extends GetxController {
  final AuthRepository authRepo = AuthRepository();
  final isLoading = false.obs;

  /// ✅ Regular logout (button click)
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

  /// ✅ NEW: Force logout (for 401 errors) - Called from NetworkApiServices
  static Future<void> forceLogout({String reason = 'Session expired'}) async {
    try {
      print('🚨 Force logout triggered: $reason');

      // Cleanup notification service
      try {
        if (Get.isRegistered<NotificationService>()) {
          final notificationService = NotificationService.instance;
          await notificationService.disconnectWebSocket();
          print('✅ Notification service cleaned up');
        }
      } catch (e) {
        print('❌ Error cleaning up notification service: $e');
      }

      // Cleanup RevenueCat
      try {
        await Purchases.logOut();
        print('✅ RevenueCat logged out');
      } catch (e) {
        print('⚠️ RevenueCat logout failed: $e');
      }

      // Clear all tokens
      await TokenStorage.clearAllTokens();
      await TokenStorage.clearAllPersonaSessions();

      // Show message
      Get.snackbar(
        "Session Expired",
        reason,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
      );

      // Navigate to login
      Get.offAll(() => LogInView());

    } catch (e) {
      print('❌ Force logout error: $e');
    }
  }

  // Cleanup notification service
  Future<void> cleanupNotificationService() async {
    try {
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = NotificationService.instance;
        await notificationService.disconnectWebSocket();
        print('✅ Notification service cleaned up successfully');
      }
    } catch (e) {
      print('❌ Error cleaning up notification service: $e');
    }
  }
}