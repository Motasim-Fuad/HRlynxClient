// Updated LogoutController
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/splash_screen/splash_screen.dart';
import 'package:get/get.dart';
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

      // Clear all tokens
      await TokenStorage.clearAllTokens();
      await TokenStorage.clearAllPersonaSessions();
      //await TokenStorage.clearSelectedPersonaId();

      Get.snackbar("Success", "Logged out successfully");

      // Navigate to login screen
      Get.offAll(() => SplashScreen());

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