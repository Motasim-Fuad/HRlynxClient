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

  Future<void> handlePostLoginNavigation() async {
    try {
      print('\n🔐 ========================================');
      print('🔐 POST-LOGIN SUBSCRIPTION CHECK STARTED');
      print('🔐 ========================================\n');

      final isFirstTime = await _isFirstTimeUser();

      if (isFirstTime) {
        print('🆕 First time user detected');
        print('   → Navigating to SubscriptionScreen');
        _navigateToSubscriptionScreen();
        return;
      }

      print('🔄 Returning user detected');
      print('   → Checking RevenueCat subscription status...');

      final hasActiveSubscription = await _checkSubscriptionStatus();

      if (hasActiveSubscription) {
        print('✅ Active subscription found');
        print('   → Navigating to MainScreen');
        _navigateToMainScreen();
      } else {
        print('⚠️ No active subscription found');
        print('   → Navigating to SubscriptionScreen');
        _navigateToSubscriptionScreen();
      }

      print('\n🔐 ========================================');
      print('🔐 POST-LOGIN CHECK COMPLETED');
      print('🔐 ========================================\n');

    } catch (e) {
      print('❌ Error in handlePostLoginNavigation: $e');
      _navigateToSubscriptionScreen();
    }
  }

  /// ✅ IMPROVED: Check if first time with RevenueCat fallback
  Future<bool> _isFirstTimeUser() async {
    try {
      final subscriptionCheckDone = await TokenStorage.getSubscriptionCheckDone();

      // ✅ If flag is null (cache cleared), check RevenueCat
      if (subscriptionCheckDone == null) {
        print('⚠️ Flag is null - checking RevenueCat for purchase history');

        final hasHistory = await _checkSubscriptionHistory();

        if (hasHistory) {
          print('✅ Found purchase history - treating as returning user');
          // Restore the flag
          await TokenStorage.saveSubscriptionCheckDone(true);
          return false; // Not first time
        }

        print('ℹ️ No purchase history found - treating as first time');
      }

      final isFirstTime = subscriptionCheckDone != true;

      print('📊 Subscription check flag: $subscriptionCheckDone');
      print('📊 Is first time: $isFirstTime');

      return isFirstTime;
    } catch (e) {
      print('⚠️ Error checking first time status: $e');
      return true;
    }
  }

  /// ✅ IMPROVED: Check if user has any purchase history in RevenueCat
  Future<bool> _checkSubscriptionHistory() async {
    try {
      // Initialize controllers if needed
      if (!Get.isRegistered<PaymentController>()) {
        Get.put(PaymentController());
      }

      final paymentController = Get.find<PaymentController>();

      // ✅ Wait for RevenueCat to actually initialize with timeout
      int retries = 0;
      const maxRetries = 15; // Increased from 10
      const delayMs = 500;

      while (paymentController.customerInfo.value == null && retries < maxRetries) {
        print('⏳ Waiting for RevenueCat to initialize... (${retries + 1}/$maxRetries)');
        await Future.delayed(Duration(milliseconds: delayMs));
        retries++;
      }

      if (paymentController.customerInfo.value == null) {
        print('❌ RevenueCat initialization timeout after ${maxRetries * delayMs}ms');
        return false;
      }

      final customerInfo = paymentController.customerInfo.value;

      if (customerInfo == null) {
        print('⚠️ CustomerInfo is null after initialization');
        return false;
      }

      // Check multiple sources for purchase history
      final hasProducts = customerInfo.allPurchasedProductIdentifiers.isNotEmpty;
      final hasTransactions = customerInfo.nonSubscriptionTransactions.isNotEmpty;
      final hasEntitlements = customerInfo.entitlements.all.isNotEmpty;

      final hasPurchaseHistory = hasProducts || hasTransactions || hasEntitlements;

      print('📊 RevenueCat Purchase History Check:');
      print('   Purchased Products: ${customerInfo.allPurchasedProductIdentifiers}');
      print('   Transactions: ${customerInfo.nonSubscriptionTransactions.length}');
      print('   Entitlements: ${customerInfo.entitlements.all.keys.toList()}');
      print('   Has History: $hasPurchaseHistory');

      return hasPurchaseHistory;
    } catch (e) {
      print('❌ Error checking subscription history: $e');
      return false;
    }
  }

  /// ✅ IMPROVED: Check subscription status with network error handling
  Future<bool> _checkSubscriptionStatus() async {
    try {
      if (!Get.isRegistered<PaymentController>()) {
        Get.put(PaymentController());
      }

      if (!Get.isRegistered<UserIsSubcribedController>()) {
        Get.put(UserIsSubcribedController());
      }

      final subController = Get.find<UserIsSubcribedController>();
      await subController.checkAndUpdateSubscriptionStatus();

      final hasActive = subController.isActive.value && !subController.isCanceled.value;

      print('📊 RevenueCat Status:');
      print('   isActive: ${subController.isActive.value}');
      print('   isCanceled: ${subController.isCanceled.value}');
      print('   hasActiveSubscription: $hasActive');

      return hasActive;

    } catch (e) {
      print('❌ Error checking subscription status: $e');

      // ✅ Check if it's a network error
      if (_isNetworkError(e)) {
        print('⚠️ Network error detected - showing retry option');
        return await _showNetworkErrorDialog();
      }

      return false;
    }
  }

  /// ✅ NEW: Check if error is network related
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('failed host lookup');
  }

  /// ✅ NEW: Show network error dialog with retry option
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
          'Unable to verify your subscription. Please check your internet connection and try again.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Continue without checking'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog first
              // Show loading indicator
              Get.dialog(
                Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              // Retry the check
              await Future.delayed(Duration(milliseconds: 500));
              final success = await _checkSubscriptionStatus();

              Get.back(); // Close loading
              Get.back(result: success); // Return result
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
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

  static Future<void> markSubscriptionScreenShown() async {
    try {
      await TokenStorage.saveSubscriptionCheckDone(true);

      // ✅ Verify the flag was saved
      final verified = await TokenStorage.verifySubscriptionFlagSaved(true);
      if (verified) {
        print('✅ Subscription screen marked as shown (verified)');
      } else {
        print('⚠️ Subscription flag saved but verification failed');
      }
    } catch (e) {
      print('❌ Error marking subscription screen: $e');
    }
  }
}