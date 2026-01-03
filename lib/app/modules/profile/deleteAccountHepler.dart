// DeleteAccountController.dart
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/log_in_view.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class DeleteAccountController extends GetxController {
  final AuthRepository authRepo = AuthRepository();
  final isLoading = false.obs;

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;

      // Disconnect notification service FIRST
      await cleanupNotificationService();

      // Call delete account API
      await authRepo.deleteAccount();

      // Clear all tokens and data
      await TokenStorage.clearAllTokens();
      await TokenStorage.clearAllPersonaSessions();

      Get.snackbar(
        "Success",
        "Account deleted successfully",
        snackPosition: SnackPosition.TOP,
      );

      // Navigate to login screen
      Get.offAll(() => LogInView());

    } catch (e) {
      Get.snackbar(
        "Error",
        "Account deletion failed: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
      print('❌ Delete account error: $e');
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
        // notificationService.clearAllNotifications();

        print('✅ Notification service cleaned up successfully');
      }
    } catch (e) {
      print('❌ Error cleaning up notification service: $e');
    }
  }
}