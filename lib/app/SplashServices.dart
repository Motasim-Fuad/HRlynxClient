// splash_service.dart


// import 'package:get/get.dart';
// import 'package:hr/app/api_servies/token.dart';
// import 'package:hr/app/modules/main_screen/main_screen_view.dart';
//
// import 'modules/splash_screen/splash_screen.dart' show SplashScreen;
//
// class SplashService {
//   Future<void> checkLoginStatus() async {
//     final token = await TokenStorage.getLoginAccessToken();
//
//     if (token != null && token.isNotEmpty) {
//       // Navigate to MainScreen
//       Get.offAll(() => MainScreen());
//     } else {
//       // Navigate to SplashScreen
//       Get.offAll(() => SplashScreen());
//     }
//   }
// }


/// upper code also right////-------



import 'package:get/get.dart';
import 'package:hr/app/api_servies/firebase_message.dart';
import 'package:hr/app/api_servies/notification_services.dart';
import 'package:hr/app/api_servies/token.dart';
import 'package:hr/app/modules/main_screen/main_screen_view.dart';
import 'modules/splash_screen/splash_screen.dart' show SplashScreen;



class SplashService {
  Future<void> checkLoginStatus() async {
    final token = await TokenStorage.getLoginAccessToken();

    if (token != null && token.isNotEmpty) {
      // Initialize notification service for logged-in user
      await initializeNotificationService();

      // ✅ FCM token backend এ পাঠান logged in user এর জন্য
      await sendFCMTokenForLoggedInUser();

      // Navigate to MainScreen
      Get.offAll(() => MainScreen());
    } else {
      // Navigate to SplashScreen
      Get.offAll(() => SplashScreen());
    }
  }

  // Initialize notification service
  Future<void> initializeNotificationService() async {
    try {
      // Register notification service if not already registered
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }

      // Get instance and enable connection
      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();

      print('✅ Notification service initialized successfully from splash');
    } catch (e) {
      print('❌ Error initializing notification service from splash: $e');
    }
  }

  // ✅ নতুন function: Already logged in user দের জন্য FCM token পাঠানো
  Future<void> sendFCMTokenForLoggedInUser() async {
    try {
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();
      print('✅ FCM token sent for already logged in user from splash');
    } catch (e) {
      print('❌ Error sending FCM token for logged in user from splash: $e');
      // Error হলেও app crash না করে continue করবে
    }
  }
}