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

      await cleanupNotificationService();

      await authRepo.LogOut();

      try {
        await Purchases.logOut();
        print('RevenueCat logged out successfully');
      } catch (e) {
        print('RevenueCat logout failed (non-critical): $e');
      }

      await TokenStorage.clearAllTokens();
      await TokenStorage.clearAllPersonaSessions();

      Get.snackbar("Success", "Logged out successfully");

      Get.offAll(() => LogInView());

    } catch (e) {
      Get.snackbar("Error", "Logout failed: ${e.toString()}");
      print('Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  static Future<void> forceLogout({String reason = 'Session expired'}) async {
    try {
      print('Force logout triggered: $reason');

      try {
        if (Get.isRegistered<NotificationService>()) {
          final notificationService = NotificationService.instance;
          await notificationService.disconnectWebSocket();
          print('Notification service cleaned up');
        }
      } catch (e) {
        print('Error cleaning up notification service: $e');
      }

      try {
        await Purchases.logOut();
        print('RevenueCat logged out');
      } catch (e) {
        print('RevenueCat logout failed: $e');
      }

      await TokenStorage.clearAllTokens();
      await TokenStorage.clearAllPersonaSessions();

      Get.snackbar(
        "Session Expired",
        reason,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
      );

      Get.offAll(() => LogInView());

    } catch (e) {
      print('Force logout error: $e');
    }
  }

  Future<void> cleanupNotificationService() async {
    try {
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = NotificationService.instance;
        await notificationService.disconnectWebSocket();
        print('Notification service cleaned up successfully');
      }
    } catch (e) {
      print('Error cleaning up notification service: $e');
    }
  }
}
