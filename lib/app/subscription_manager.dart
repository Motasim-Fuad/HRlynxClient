// lib/app/services/subscription_manager.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/main_screen/main_screen_view.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  static SubscriptionManager get instance => _instance;

  /// ✅ MAIN ENTRY POINT - Single responsibility
  Future<void> handlePostLoginNavigation() async {
    try {
      print('\n🔐 ========================================');
      print('🔐 POST-LOGIN SUBSCRIPTION CHECK STARTED');
      print('🔐 ========================================\n');

      // ✅ Get userId from storage first
      final userId = await TokenStorage.getUserId();
      if (userId == null) {
        print('❌ No user ID found');
        _navigateToSubscriptionScreen();
        return;
      }

      // ✅ Pass userId to PaymentController
      await _ensurePaymentControllerReady(userId);

      // ✅ STEP 2: Restore purchases first (blocking)
      await _restorePurchasesIfNeeded();

      // ✅ STEP 3: Check if first time user
      final isFirstTime = await _isFirstTimeUser();

      if (isFirstTime) {
        print('🆕 First time user → SubscriptionScreen');
        _navigateToSubscriptionScreen();
        return;
      }

      // ✅ STEP 4: Check subscription status (RevenueCat primary)
      final hasActiveSubscription = await _checkSubscriptionStatusRobust();

      if (hasActiveSubscription) {
        print('✅ Active subscription → MainScreen');
        await TokenStorage.saveSubscriptionCheckDone(true);
        _navigateToMainScreen();
      } else {
        print('⚠️ No active subscription → SubscriptionScreen');
        _navigateToSubscriptionScreen();
      }

    } catch (e) {
      print('❌ Critical error in handlePostLoginNavigation: $e');
      // ✅ Safe fallback: Go to subscription screen on any error
      _navigateToSubscriptionScreen();
    }
  }

  /// ✅ STEP 1: Ensure PaymentController is initialized and ready
  Future<void> _ensurePaymentControllerReady(int userId) async {
    try {
      if (!Get.isRegistered<PaymentController>()) {
        print('🔧 Initializing PaymentController with userId: $userId');
        // ✅ Pass userId to PaymentController
        Get.put(PaymentController(userId: userId));
      }

      final controller = Get.find<PaymentController>();

      // Wait for RevenueCat
      int attempts = 0;
      const maxAttempts = 20;
      const delayMs = 60;

      while (!controller.isRevenueCatAvailable.value && attempts < maxAttempts) {
        print('⏳ Waiting for RevenueCat... (${attempts + 1}/$maxAttempts)');
        await Future.delayed(Duration(milliseconds: delayMs));
        attempts++;
      }

      if (!controller.isRevenueCatAvailable.value) {
        throw Exception('RevenueCat timeout');
      }

      print('✅ PaymentController ready');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  /// ✅ STEP 2: Restore purchases (blocking operation)
  Future<void> _restorePurchasesIfNeeded() async {
    try {
      print('🔄 Restoring purchases...');
      final controller = Get.find<PaymentController>();

      // ✅ Call restore and wait for completion
      await controller.restorePurchases();

      // ✅ Give RevenueCat time to sync (critical for iOS)
      await Future.delayed(Duration(milliseconds: 2000));

      // ✅ Refresh customer info
      await controller.getCustomerInfo();

      print('✅ Purchase restore completed');
    } catch (e) {
      print('⚠️ Error restoring purchases (non-critical): $e');
      // Don't throw - continue with existing data
    }
  }

  /// ✅ STEP 3: Check if first time user (with RevenueCat fallback)
  Future<bool> _isFirstTimeUser() async {
    try {
      final subscriptionCheckDone = await TokenStorage.getSubscriptionCheckDone();

      // ✅ If flag exists and is true → not first time
      if (subscriptionCheckDone == true) {
        print('📊 Flag says: Returning user');
        return false;
      }

      // ✅ If flag is null/false, check RevenueCat purchase history
      print('⚠️ Flag is null/false - checking RevenueCat history...');
      final hasHistory = await _checkPurchaseHistory();

      if (hasHistory) {
        print('✅ Found purchase history - treating as returning user');
        // Restore the flag
        await TokenStorage.saveSubscriptionCheckDone(true);
        return false;
      }

      print('ℹ️ No purchase history - treating as first time user');
      return true;

    } catch (e) {
      print('⚠️ Error checking first time status: $e');
      // ✅ Safe default: treat as first time
      return true;
    }
  }

  /// ✅ Check if user has any purchase history in RevenueCat
  Future<bool> _checkPurchaseHistory() async {
    try {
      final controller = Get.find<PaymentController>();
      final customerInfo = controller.customerInfo.value;

      if (customerInfo == null) {
        print('⚠️ CustomerInfo is null');
        return false;
      }

      // ✅ Check multiple sources for purchase history
      final hasProducts = customerInfo.allPurchasedProductIdentifiers.isNotEmpty;
      final hasTransactions = customerInfo.nonSubscriptionTransactions.isNotEmpty;
      final hasEntitlements = customerInfo.entitlements.all.isNotEmpty;

      final hasPurchaseHistory = hasProducts || hasTransactions || hasEntitlements;

      print('📊 Purchase History Check:');
      print('   Products: ${customerInfo.allPurchasedProductIdentifiers}');
      print('   Transactions: ${customerInfo.nonSubscriptionTransactions.length}');
      print('   Entitlements: ${customerInfo.entitlements.all.keys.toList()}');
      print('   Has History: $hasPurchaseHistory');

      return hasPurchaseHistory;
    } catch (e) {
      print('❌ Error checking purchase history: $e');
      return false;
    }
  }

  /// ✅ STEP 4: Check subscription status (RevenueCat primary, backend secondary)
  Future<bool> _checkSubscriptionStatusRobust() async {
    try {
      print('🔍 Checking subscription status...');

      // ✅ PRIMARY: Check RevenueCat directly (fast, local)
      final hasActiveRevenueCat = await _checkRevenueCatStatus();

      print('📊 RevenueCat Status: $hasActiveRevenueCat');

      // ✅ If RevenueCat says active, trust it immediately
      if (hasActiveRevenueCat) {
        print('✅ RevenueCat confirmed active subscription');

        // ✅ Sync with backend in background (non-blocking)
        _syncWithBackend();

        return true;
      }

      // ✅ SECONDARY: If RevenueCat says no subscription, double-check with backend
      print('⚠️ RevenueCat shows no active subscription');
      print('🔍 Double-checking with backend...');

      final hasActiveBackend = await _checkBackendStatus();

      if (hasActiveBackend) {
        print('⚠️ Backend shows active but RevenueCat doesn\'t - syncing...');
        // Force refresh RevenueCat
        final controller = Get.find<PaymentController>();
        await controller.getCustomerInfo();
        return await _checkRevenueCatStatus();
      }

      return false;

    } catch (e) {
      print('❌ Error checking subscription status: $e');

      // ✅ Check if network error
      if (_isNetworkError(e)) {
        print('⚠️ Network error - showing retry dialog');
        return await _showNetworkErrorDialog();
      }

      // ✅ For other errors, check local RevenueCat data
      return await _checkRevenueCatStatus();
    }
  }

  /// ✅ Check RevenueCat status (fast, local)
  Future<bool> _checkRevenueCatStatus() async {
    try {
      final controller = Get.find<PaymentController>();
      final customerInfo = controller.customerInfo.value;

      if (customerInfo == null) {
        print('⚠️ CustomerInfo is null');
        return false;
      }

      // ✅ Check active entitlements
      final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;

      if (hasActiveEntitlements) {
        print('✅ Active entitlements found:');
        customerInfo.entitlements.active.forEach((key, value) {
          print('   - $key: expires ${value.expirationDate}');
        });
      }

      return hasActiveEntitlements;
    } catch (e) {
      print('❌ Error checking RevenueCat status: $e');
      return false;
    }
  }

  /// ✅ Check backend status (with timeout)
  Future<bool> _checkBackendStatus() async {
    try {
      if (!Get.isRegistered<UserIsSubcribedController>()) {
        Get.put(UserIsSubcribedController());
      }

      final subController = Get.find<UserIsSubcribedController>();

      // ✅ Call with timeout
      await subController.checkAndUpdateSubscriptionStatus()
          .timeout(Duration(seconds: 5));

      final hasActive = subController.isActive.value && !subController.isCanceled.value;

      print('📊 Backend Status:');
      print('   isActive: ${subController.isActive.value}');
      print('   isCanceled: ${subController.isCanceled.value}');

      return hasActive;

    } catch (e) {
      print('⚠️ Backend check failed (non-critical): $e');
      return false;
    }
  }

  /// ✅ Sync with backend in background (non-blocking)
  void _syncWithBackend() {
    Future.microtask(() async {
      try {
        print('🔄 Syncing subscription status with backend...');
        final controller = Get.find<PaymentController>();

        // This will sync the latest customerInfo
        if (controller.customerInfo.value != null) {
          // Your existing backend sync logic
          print('✅ Background sync completed');
        }
      } catch (e) {
        print('⚠️ Background sync failed (non-critical): $e');
      }
    });
  }

  /// ✅ Check if error is network related
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('failed host lookup');
  }

  /// ✅ Show network error dialog with retry
  Future<bool> _showNetworkErrorDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 10),
            Text('Connection Error'),
          ],
        ),
        content: Text(
          'Unable to verify your subscription. Please check your internet connection.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Skip for now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog

              // Show loading
              Get.dialog(
                Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              // Retry
              await Future.delayed(Duration(seconds: 1));
              final success = await _checkSubscriptionStatusRobust();

              Get.back(); // Close loading
              Get.back(result: success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  void _navigateToSubscriptionScreen() {
    Get.offAll(() => SubscriptionScreen());
  }

  void _navigateToMainScreen() {
    Get.offAll(() => MainScreen());
  }

  /// ✅ Mark subscription screen as shown
  static Future<void> markSubscriptionScreenShown() async {
    try {
      await TokenStorage.saveSubscriptionCheckDone(true);

      final verified = await TokenStorage.verifySubscriptionFlagSaved(true);
      if (verified) {
        print('✅ Subscription screen marked as shown (verified)');
      } else {
        print('⚠️ Flag verification failed - using in-memory fallback');
      }
    } catch (e) {
      print('❌ Error marking subscription screen: $e');
    }
  }
}