import 'package:get/get.dart';
import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'api_servies/firebase_message.dart';
import 'api_servies/notification_services.dart';
import 'api_servies/token.dart' show TokenStorage;
import 'modules/main_screen/main_screen_view.dart' show MainScreen;
import 'modules/splash_screen/splash_screen.dart' show SplashScreen;
import 'modules/payment/subcription_view.dart';

class SplashService {
  Future<void> checkLoginStatus() async {
    final token = await TokenStorage.getLoginAccessToken();

    if (token != null && token.isNotEmpty) {
      print('✅ User is logged in');

      // Initialize notification service for logged-in user
      await initializeNotificationService();
      await sendFCMTokenForLoggedInUser();

      // ✅ Check if this is first login after signup
      final isFirstLogin = await _isFirstLogin();

      if (isFirstLogin) {
        print('🆕 First time login detected → Showing SubscriptionScreen');
        // Mark as subscription screen shown
        await _markLoginDone();
        Get.offAll(() => SubscriptionScreen());
        return;
      }

      // ✅ For returning users, check subscription status from RevenueCat
      print('🔄 Returning user - Checking subscription status...');
      final hasActiveSubscription = await _checkSubscriptionStatus();

      if (hasActiveSubscription) {
        print('💎 Active subscription found → Going to MainScreen');
        Get.offAll(() => MainScreen());
      } else {
        print('⚠️ No active subscription → Showing SubscriptionScreen');
        Get.offAll(() => SubscriptionScreen());
      }
    } else {
      print('❌ User not logged in → Going to SplashScreen');
      Get.offAll(() => SplashScreen());
    }
  }

  /// Check if this is the first login after signup
  Future<bool> _isFirstLogin() async {
    try {
      final subscriptionCheckDone = await TokenStorage.getSubscriptionCheckDone();
      // If flag is null or false, it's first login
      return subscriptionCheckDone != true;
    } catch (e) {
      print('⚠️ Error checking first login: $e');
      return true; // Default to true for safety
    }
  }

  /// Mark that subscription screen has been shown
  Future<void> _markLoginDone() async {
    try {
      await TokenStorage.saveSubscriptionCheckDone(true);
      print('✅ Subscription check flag marked as done');
    } catch (e) {
      print('❌ Error marking login done: $e');
    }
  }

  /// Check if user has active subscription from RevenueCat
  Future<bool> _checkSubscriptionStatus() async {
    try {
      // Initialize PaymentController if not exists
      if (!Get.isRegistered<PaymentController>()) {
        Get.put(PaymentController());
      }

      // Initialize UserIsSubcribedController if not exists
      if (!Get.isRegistered<UserIsSubcribedController>()) {
        Get.put(UserIsSubcribedController());
      }

      final subController = Get.find<UserIsSubcribedController>();

      // Force refresh subscription status from RevenueCat
      await subController.checkAndUpdateSubscriptionStatus();

      // Check if subscription is active and not canceled
      // RevenueCat manages expiry/cancellation automatically
      final hasActive = subController.isActive.value && !subController.isCanceled.value;

      print('📊 Subscription Status Check:');
      print('   isActive: ${subController.isActive.value}');
      print('   isCanceled: ${subController.isCanceled.value}');
      print('   Result: $hasActive');

      return hasActive;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      // On error, default to false to show subscription screen
      return false;
    }
  }

  /// Initialize notification service
  Future<void> initializeNotificationService() async {
    try {
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }

      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();

      print('✅ Notification service initialized successfully from splash');
    } catch (e) {
      print('❌ Error initializing notification service from splash: $e');
    }
  }

  /// Send FCM token for logged in user
  Future<void> sendFCMTokenForLoggedInUser() async {
    try {
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();
      print('✅ FCM token sent for already logged in user from splash');
    } catch (e) {
      print('❌ Error sending FCM token for logged in user from splash: $e');
    }
  }
}