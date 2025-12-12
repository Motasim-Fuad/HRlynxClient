// ✅ FIXED VERSION - Works perfectly with Optimized PaymentController
// lib/app/services/subscription_manager.dart

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

  /// ✅ MAIN ENTRY POINT - RevenueCat ONLY (FIXED)
  Future<void> handlePostLoginNavigation() async {
    try {
      print('\n🔐 ========================================');
      print('🔐 POST-LOGIN NAVIGATION (FIXED)');
      print('🔐 ========================================\n');

      // ✅ STEP 1: Get userId
      final userId = await TokenStorage.getUserId();
      if (userId == null) {
        print('❌ No user ID found');
        _navigateToSubscriptionScreen();
        return;
      }
      print('✅ User ID: $userId');

      // ✅ STEP 2: Initialize PaymentController with userId
      await _ensurePaymentControllerReady(userId);

      // ✅ STEP 3: Restore purchases (sync with RevenueCat)
      await _restorePurchasesAndSync();

      // ✅ STEP 4: Check RevenueCat subscription status FIRST
      final hasActiveSubscription = await _checkRevenueCatSubscription();
      print('📊 Active subscription: $hasActiveSubscription');

      if (hasActiveSubscription) {
        // ✅ User has active subscription → Go to MainScreen
        print('✅ Active subscription → MainScreen');
        await TokenStorage.saveSubscriptionCheckDone(true);
        _navigateToMainScreen();
        return;
      }

      // ✅ STEP 5: No subscription → Check if first time user
      final isFirstTime = await _isFirstTimeUser();
      print('📊 First time user: $isFirstTime');

      if (isFirstTime) {
        print('🆕 First time → SubscriptionScreen');
        _navigateToSubscriptionScreen();
        return;
      }

      // ✅ Returning user but no subscription → SubscriptionScreen
      print('⚠️ Returning user, no subscription → SubscriptionScreen');
      _navigateToSubscriptionScreen();

      print('\n✅ Navigation complete\n');

    } catch (e) {
      print('❌ Critical error: $e');
      _navigateToSubscriptionScreen(); // Safe fallback
    }
  }

  /// ✅ STEP 1: Initialize PaymentController
  Future<void> _ensurePaymentControllerReady(int userId) async {
    try {
      print('\n🔧 Setting up PaymentController...');

      // Clean up old controller
      if (Get.isRegistered<PaymentController>()) {
        Get.delete<PaymentController>();
      }

      // Create new controller
      Get.put(PaymentController(userId: userId));
      final controller = Get.find<PaymentController>();

      // Wait for RevenueCat initialization
      int attempts = 0;
      const maxAttempts = 30;

      while (!controller.isRevenueCatAvailable.value && attempts < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 100));
        attempts++;
      }

      if (!controller.isRevenueCatAvailable.value) {
        throw Exception('RevenueCat timeout');
      }

      if (!controller.isRevenueCatUserLoggedIn.value) {
        throw Exception('RevenueCat user not logged in');
      }

      print('✅ PaymentController ready');
      print('✅ Actual User ID: ${controller.revenueCatActualUserId}');

    } catch (e) {
      print('❌ Error in PaymentController setup: $e');
      rethrow;
    }
  }

  /// ✅ STEP 2: Restore purchases and sync
  Future<void> _restorePurchasesAndSync() async {
    try {
      print('\n🔄 Restoring purchases...');
      final controller = Get.find<PaymentController>();

      await controller.restorePurchases();
      await Future.delayed(Duration(milliseconds: 1500));
      await controller.getCustomerInfo();

      print('✅ Restore complete');
    } catch (e) {
      print('⚠️ Restore error (non-critical): $e');
    }
  }

  /// ✅ STEP 3: Check if first time user (RevenueCat ONLY)
  Future<bool> _isFirstTimeUser() async {
    try {
      print('\n🔍 Checking first time status...');

      // ✅ Check 1: Local flag
      final checkDone = await TokenStorage.getSubscriptionCheckDone();
      if (checkDone == true) {
        print('✅ Returning user (local flag)');
        return false;
      }

      // ✅ Check 2: RevenueCat purchase history
      final controller = Get.find<PaymentController>();
      final customerInfo = controller.customerInfo.value;

      if (customerInfo != null) {
        final hasHistory = customerInfo.allPurchasedProductIdentifiers.isNotEmpty ||
            customerInfo.nonSubscriptionTransactions.isNotEmpty ||
            customerInfo.entitlements.all.isNotEmpty;

        if (hasHistory) {
          print('✅ Has purchase history');
          await TokenStorage.saveSubscriptionCheckDone(true);
          return false;
        }
      }

      // ✅ No history → First time user
      print('ℹ️ First time user');
      return true;

    } catch (e) {
      print('⚠️ Error checking status: $e');
      return true; // Safe default
    }
  }

  /// ✅ STEP 4: Check RevenueCat subscription (FIXED - No user ID check)
  Future<bool> _checkRevenueCatSubscription() async {
    try {
      print('\n🔍 Checking RevenueCat subscription...');

      final controller = Get.find<PaymentController>();
      final customerInfo = controller.customerInfo.value;

      if (customerInfo == null) {
        print('⚠️ No customer info');
        return false;
      }

      // RevenueCat already verified user during login
      final hasActive = customerInfo.entitlements.active.isNotEmpty;

      if (hasActive) {
        print('✅ Active entitlements found:');
        customerInfo.entitlements.active.forEach((key, value) {
          print('   - $key');
          print('     Product: ${value.productIdentifier}');
          print('     Expires: ${value.expirationDate}');
          print('     Will Renew: ${value.willRenew}');
        });
      } else {
        print('⚠️ No active entitlements');
      }

      return hasActive;

    } catch (e) {
      print('❌ Error checking subscription: $e');
      return false;
    }
  }

  /// ✅ Navigation helpers
  void _navigateToSubscriptionScreen() {
    Get.offAll(() => SubscriptionScreen());
  }

  void _navigateToMainScreen() {
    Get.offAll(() => MainScreen());
  }

  /// ✅ Mark subscription screen shown
  static Future<void> markSubscriptionScreenShown() async {
    try {
      await TokenStorage.saveSubscriptionCheckDone(true);
      final verified = await TokenStorage.verifySubscriptionFlagSaved(true);

      if (verified) {
        print('✅ Subscription screen marked as shown');
      } else {
        print('⚠️ Flag verification failed');
      }
    } catch (e) {
      print('❌ Error marking subscription: $e');
    }
  }
}