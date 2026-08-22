import 'dart:async';
import 'package:get/get.dart';
import 'api_servies/firebase_message.dart';
import 'api_servies/notification_services.dart';
import 'api_servies/token.dart' show TokenStorage;
import 'modules/main_screen/main_screen_view.dart' show MainScreen;
import 'modules/splash_screen/splash_screen.dart' show SplashScreen;

class SplashService {

  Future<void> checkLoginStatus() async {
    String? token;

    try {
      print('CHECKING LOGIN');

      try {
        token = await TokenStorage.getLoginAccessToken().timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('Token timeout');
            return null;
          },
        );
      } catch (e) {
        print('Token error: $e');
        token = null;
      }

      if (token == null || token.isEmpty || token == 'null') {
        print('No token');
        print('→ SplashScreen');
        await _safeNavigateToSplashScreen();
        return;
      }

      print('Token found');
      print('→ User logged in');

      _initializeUserServicesAsync();

      await _safeNavigateToMainScreen();

      print('LOGIN CHECK COMPLETE');

    } catch (e, stackTrace) {
      print('LOGIN CHECK ERROR');
      print('Error: $e');
      print('Stack: $stackTrace');

      await _safeNavigateToSplashScreen();
    }
  }

  void _initializeUserServicesAsync() {
    Future.microtask(() async {
      try {
        print('USER SERVICES (BACKGROUND)');

        await _initializeNotificationService();
        await _sendFCMToken();

        print('USER SERVICES READY');

      } catch (e, stackTrace) {
        print('USER SERVICES ERROR');
        print('Error: $e');
        print('Stack: $stackTrace');
      }
    });
  }

  Future<void> _initializeNotificationService() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        print('NotificationService (${attempts + 1}/$maxAttempts)...');

        if (!Get.isRegistered<NotificationService>()) {
          Get.put(NotificationService());
          print('Service registered');
        }

        final service = NotificationService.instance;

        await service.enableConnection().timeout(
          Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Connection timeout'),
        );

        print('NotificationService ready');
        return;

      } catch (e) {
        attempts++;
        print('Attempt $attempts failed: $e');

        if (attempts >= maxAttempts) {
          print('NotificationService failed - continuing');
          return;
        }

        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  Future<void> _sendFCMToken() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        print('Sending FCM token (${attempts + 1}/$maxAttempts)...');

        final firebaseMsg = FirebaseMeg();

        await firebaseMsg.sendFCMTokenAfterLogin().timeout(
          Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('FCM send timeout'),
        );

        print('FCM token sent');
        return;

      } catch (e) {
        attempts++;
        print('FCM attempt $attempts failed: $e');

        if (attempts >= maxAttempts) {
          print('FCM send failed - continuing');
          return;
        }

        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  Future<void> _safeNavigateToSplashScreen() async {
    try {
      await Future.delayed(Duration(milliseconds: 100));

      if (Get.currentRoute == '/SplashScreen') {
        print('Already on SplashScreen');
        return;
      }

      print('→ SplashScreen');
      Get.offAll(() => SplashScreen());
      print('Navigation successful');

    } catch (e, stackTrace) {
      print('SplashScreen navigation failed: $e');
      print('Stack: $stackTrace');

      try {
        await Future.delayed(Duration(milliseconds: 500));
        Get.offAll(() => SplashScreen());
      } catch (finalError) {
        print('Final attempt failed: $finalError');
      }
    }
  }

  Future<void> _safeNavigateToMainScreen() async {
    try {
      await Future.delayed(Duration(milliseconds: 100));

      if (Get.currentRoute == '/MainScreen') {
        print('Already on MainScreen');
        return;
      }

      print('→ MainScreen');
      Get.offAll(() => MainScreen());
      print('Navigation successful');

    } catch (e, stackTrace) {
      print('MainScreen navigation failed: $e');
      print('Stack: $stackTrace');

      try {
        print('Fallback to SplashScreen');
        await Future.delayed(Duration(milliseconds: 500));
        Get.offAll(() => SplashScreen());
      } catch (finalError) {
        print('Final attempt failed: $finalError');
      }
    }
  }

  Future<void> retryInitialization() async {
    print('Manual retry');
    await checkLoginStatus();
  }
}
