// lib/app/SplashServices.dart - PRODUCTION READY

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
      print('🔍 ========================================');
      print('🔍 CHECKING LOGIN');
      print('🔍 ========================================\n');

      try {
        token = await TokenStorage.getLoginAccessToken().timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ Token timeout');
            return null;
          },
        );
      } catch (e) {
        print('❌ Token error: $e');
        token = null;
      }

      if (token == null || token.isEmpty || token == 'null') {
        print('❌ No token');
        print('   → SplashScreen\n');
        await _safeNavigateToSplashScreen();
        return;
      }

      print('✅ Token found');
      print('   → User logged in');

      _initializeUserServicesAsync();

      await _safeNavigateToMainScreen();

      print('\n✅ LOGIN CHECK COMPLETE\n');

    } catch (e, stackTrace) {
      print('❌ ========================================');
      print('❌ LOGIN CHECK ERROR');
      print('❌ ========================================');
      print('Error: $e');
      print('Stack: $stackTrace\n');

      await _safeNavigateToSplashScreen();
    }
  }

  void _initializeUserServicesAsync() {
    Future.microtask(() async {
      try {
        print('\n🔧 ========================================');
        print('🔧 USER SERVICES (BACKGROUND)');
        print('🔧 ========================================\n');

        await _initializeNotificationService();
        await _sendFCMToken();

        print('\n✅ USER SERVICES READY\n');

      } catch (e, stackTrace) {
        print('\n⚠️ ========================================');
        print('⚠️ USER SERVICES ERROR');
        print('⚠️ ========================================');
        print('Error: $e');
        print('Stack: $stackTrace\n');
      }
    });
  }

  Future<void> _initializeNotificationService() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        print('📬 NotificationService (${attempts + 1}/$maxAttempts)...');

        if (!Get.isRegistered<NotificationService>()) {
          Get.put(NotificationService());
          print('   ✅ Service registered');
        }

        final service = NotificationService.instance;

        await service.enableConnection().timeout(
          Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('Connection timeout'),
        );

        print('✅ NotificationService ready');
        return;

      } catch (e) {
        attempts++;
        print('❌ Attempt $attempts failed: $e');

        if (attempts >= maxAttempts) {
          print('⚠️ NotificationService failed - continuing');
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
        print('🔐 Sending FCM token (${attempts + 1}/$maxAttempts)...');

        final firebaseMsg = FirebaseMeg();

        await firebaseMsg.sendFCMTokenAfterLogin().timeout(
          Duration(seconds: 8),
          onTimeout: () => throw TimeoutException('FCM send timeout'),
        );

        print('✅ FCM token sent');
        return;

      } catch (e) {
        attempts++;
        print('❌ FCM attempt $attempts failed: $e');

        if (attempts >= maxAttempts) {
          print('⚠️ FCM send failed - continuing');
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
        print('ℹ️ Already on SplashScreen');
        return;
      }

      print('🚀 → SplashScreen');
      Get.offAll(() => SplashScreen());
      print('✅ Navigation successful');

    } catch (e, stackTrace) {
      print('❌ SplashScreen navigation failed: $e');
      print('Stack: $stackTrace');

      try {
        await Future.delayed(Duration(milliseconds: 500));
        Get.offAll(() => SplashScreen());
      } catch (finalError) {
        print('❌ Final attempt failed: $finalError');
      }
    }
  }

  Future<void> _safeNavigateToMainScreen() async {
    try {
      await Future.delayed(Duration(milliseconds: 100));

      if (Get.currentRoute == '/MainScreen') {
        print('ℹ️ Already on MainScreen');
        return;
      }

      print('🚀 → MainScreen');
      Get.offAll(() => MainScreen());
      print('✅ Navigation successful');

    } catch (e, stackTrace) {
      print('❌ MainScreen navigation failed: $e');
      print('Stack: $stackTrace');

      try {
        print('⚠️ Fallback to SplashScreen');
        await Future.delayed(Duration(milliseconds: 500));
        Get.offAll(() => SplashScreen());
      } catch (finalError) {
        print('❌ Final attempt failed: $finalError');
      }
    }
  }

  Future<void> retryInitialization() async {
    print('\n🔄 Manual retry');
    await checkLoginStatus();
  }
}