// lib/app/services/subscription_manager.dart - PRODUCTION READY

import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/main_screen/main_screen_view.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  static SubscriptionManager get instance => _instance;
  static String get ADMIN_EMAIL => dotenv.env['ADMIN_ACCESS_EMAIL'] ?? '';

  Future<void> handlePostLoginNavigation() async {
    try {
      print('\n🔐 ========================================');
      print('🔐 POST-LOGIN NAVIGATION');
      print('🔐 ========================================\n');

      final userId = await _getUserIdSafely();
      if (userId == null) {
        print('❌ No user ID');
        _navigateToSubscriptionScreen();
        return;
      }

      if (await _isAdminUser()) {
        print('🔑 Admin → MainScreen');
        _navigateToMainScreen();
        return;
      }

      final controllerReady = await _ensurePaymentControllerReady(userId);
      if (!controllerReady) {
        print('⚠️ Controller failed');
        _navigateToSubscriptionScreen();
        return;
      }

      await _restorePurchasesAndSync();

      final hasActiveSubscription = await _checkRevenueCatSubscription();
      print('📊 Subscription: $hasActiveSubscription');

      if (hasActiveSubscription) {
        print('✅ Active → MainScreen');
        await TokenStorage.saveSubscriptionCheckDone(true);
        _navigateToMainScreen();
        return;
      }

      final isFirstTime = await _isFirstTimeUser();
      print('📊 First time: $isFirstTime');

      _navigateToSubscriptionScreen();

      print('\n✅ POST-LOGIN COMPLETE\n');

    } catch (e, stackTrace) {
      print('\n❌ POST-LOGIN ERROR');
      print('Error: $e');
      print('Stack: $stackTrace\n');
      _navigateToSubscriptionScreen();
    }
  }

  Future<int?> _getUserIdSafely() async {
    try {
      print('🔍 Getting user ID...');

      final userId = await TokenStorage.getUserId().timeout(
        Duration(seconds: 3),
        onTimeout: () {
          print('⚠️ User ID timeout');
          return null;
        },
      );

      if (userId == null || userId <= 0) {
        print('❌ Invalid user ID');
        return null;
      }

      print('✅ User ID: $userId');
      return userId;

    } catch (e) {
      print('❌ User ID error: $e');
      return null;
    }
  }

  Future<bool> _isAdminUser() async {
    try {
      if (ADMIN_EMAIL.isEmpty) return false;

      final userEmail = await TokenStorage.getUserEmail().timeout(
        Duration(seconds: 3),
        onTimeout: () => null,
      );

      return userEmail != null &&
          userEmail.toLowerCase() == ADMIN_EMAIL.toLowerCase();
    } catch (e) {
      print('⚠️ Admin check error: $e');
      return false;
    }
  }

  Future<bool> _ensurePaymentControllerReady(int userId) async {
    try {
      print('\n🔧 Setting up PaymentController...');

      if (Get.isRegistered<PaymentController>()) {
        try {
          Get.delete<PaymentController>(force: true);
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          print('⚠️ Cleanup error: $e');
        }
      }

      try {
        Get.put(PaymentController(userId: userId));
      } catch (e) {
        print('❌ Controller creation failed: $e');
        return false;
      }

      final controller = Get.find<PaymentController>();

      int attempts = 0;
      const maxAttempts = 50;

      while (!controller.isRevenueCatAvailable.value && attempts < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 100));
        attempts++;
      }

      if (!controller.isRevenueCatAvailable.value) {
        print('❌ RevenueCat not available');
        return false;
      }

      if (!controller.isRevenueCatUserLoggedIn.value) {
        print('❌ RevenueCat not logged in');
        return false;
      }

      print('✅ Controller ready');
      print('✅ User: ${controller.revenueCatActualUserId}');
      return true;

    } catch (e) {
      print('❌ Controller error: $e');
      return false;
    }
  }

  Future<void> _restorePurchasesAndSync() async {
    try {
      print('\n🔄 Restoring...');

      final controller = Get.find<PaymentController>();

      await controller.restorePurchases().timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ Restore timeout');
        },
      );

      await Future.delayed(Duration(milliseconds: 1500));

      await controller.getCustomerInfo().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Customer info timeout');
        },
      );

      print('✅ Restore complete');

    } catch (e) {
      print('⚠️ Restore error: $e');
    }
  }

  Future<bool> _isFirstTimeUser() async {
    try {
      print('\n🔍 Checking first time...');

      final checkDone = await TokenStorage.getSubscriptionCheckDone().timeout(
        Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (checkDone == true) {
        print('✅ Returning user');
        return false;
      }

      try {
        final controller = Get.find<PaymentController>();
        final customerInfo = controller.customerInfo.value;

        if (customerInfo != null) {
          final hasHistory =
              customerInfo.allPurchasedProductIdentifiers.isNotEmpty ||
                  customerInfo.nonSubscriptionTransactions.isNotEmpty ||
                  customerInfo.entitlements.all.isNotEmpty;

          if (hasHistory) {
            print('✅ Has history');
            await TokenStorage.saveSubscriptionCheckDone(true);
            return false;
          }
        }
      } catch (e) {
        print('⚠️ History check error: $e');
      }

      print('ℹ️ First time user');
      return true;

    } catch (e) {
      print('⚠️ First time check error: $e');
      return true;
    }
  }

  Future<bool> _checkRevenueCatSubscription() async {
    try {
      print('\n🔍 Checking subscription...');

      final controller = Get.find<PaymentController>();

      try {
        await controller.getCustomerInfo().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Customer info timeout');
          },
        );
      } catch (e) {
        print('⚠️ Customer info error: $e');
      }

      final customerInfo = controller.customerInfo.value;

      if (customerInfo == null) {
        print('⚠️ No customer info');
        return false;
      }

      final hasActive = customerInfo.entitlements.active.isNotEmpty;

      if (hasActive) {
        print('✅ Active entitlements:');
        customerInfo.entitlements.active.forEach((key, value) {
          print('   - $key');
          print('     Product: ${value.productIdentifier}');
          print('     Expires: ${value.expirationDate}');
        });
      } else {
        print('⚠️ No active entitlements');
      }

      return hasActive;

    } catch (e) {
      print('❌ Subscription check error: $e');
      return false;
    }
  }

  void _navigateToSubscriptionScreen() {
    try {
      Future.delayed(Duration(milliseconds: 100), () {
        Get.offAll(() => SubscriptionScreen());
      });
    } catch (e) {
      print('❌ SubscriptionScreen nav failed: $e');
    }
  }

  void _navigateToMainScreen() {
    try {
      Future.delayed(Duration(milliseconds: 100), () {
        Get.offAll(() => MainScreen());
      });
    } catch (e) {
      print('❌ MainScreen nav failed: $e');
      _navigateToSubscriptionScreen();
    }
  }

  static Future<void> markSubscriptionScreenShown() async {
    try {
      await TokenStorage.saveSubscriptionCheckDone(true);

      final verified = await TokenStorage.verifySubscriptionFlagSaved(true);

      if (verified) {
        print('✅ Subscription marked');
      } else {
        print('⚠️ Verification failed');
      }
    } catch (e) {
      print('❌ Mark error: $e');
    }
  }
}