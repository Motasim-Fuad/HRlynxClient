// lib/app/SplashServices.dart

import 'package:get/get.dart';
import 'api_servies/firebase_message.dart';
import 'api_servies/notification_services.dart';
import 'api_servies/token.dart' show TokenStorage;
import 'modules/main_screen/main_screen_view.dart' show MainScreen;
import 'modules/splash_screen/splash_screen.dart' show SplashScreen;

class SplashService {
  Future<void> checkLoginStatus() async {
    final token = await TokenStorage.getLoginAccessToken();

    if (token != null && token.isNotEmpty) {
      print('✅ User is logged in (token found)');

      // Initialize services for logged-in user
      await _initializeUserServices();

      // Navigate to last screen (MainScreen)
      // User will be already logged in, so go to main screen directly
      print('   → Navigating to MainScreen');
      Get.offAll(() => MainScreen());

    } else {
      print('❌ User not logged in (no token)');
      print('   → Navigating to SplashScreen');
      Get.offAll(() => SplashScreen());
    }
  }

  /// ============================================
  /// Initialize notification services
  /// ============================================
  Future<void> _initializeUserServices() async {
    try {
      // Initialize notification service
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }

      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();

      // Send FCM token
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();

      print('✅ User services initialized (notifications + FCM)');
    } catch (e) {
      print('❌ Error initializing user services: $e');
    }
  }
}