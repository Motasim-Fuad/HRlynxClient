// lib/app/subscription_manager.dart - OPTIMIZED WITH LOADING

import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/main_screen/main_screen_view.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';
import 'package:HRlynx/app/common_widgets/loading_overlay.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  static SubscriptionManager get instance => _instance;
  static String get ADMIN_EMAIL => dotenv.env['ADMIN_ACCESS_EMAIL'] ?? '';
  static String get CLIENT_EMAIL => dotenv.env['CLINT_ACCESS_EMAIL'] ?? '';

  /// ✅ OPTIMIZED: Shows loading during entire process
  Future<void> handlePostLoginNavigation() async {
    try {
      LoadingOverlay.show(message: 'Setting up your account...');

      print('\n🔐 POST-LOGIN NAVIGATION\n');

      // Step 1: Get User ID
      final userId = await _getUserIdSafely();
      if (userId == null) {
        LoadingOverlay.hide();
        _navigateToSubscriptionScreen();
        return;
      }

      // Step 2: Check Admin or Client
      if (await _isAdminOrClientUser()) {
        LoadingOverlay.updateMessage('Loading dashboard...');
        await Future.delayed(Duration(milliseconds: 300));
        LoadingOverlay.hide();
        _navigateToMainScreen();
        return;
      }

      // Step 3: Setup Payment Controller
      LoadingOverlay.updateMessage('Initializing subscription...');
      final controllerReady = await _ensurePaymentControllerReady(userId);
      if (!controllerReady) {
        LoadingOverlay.hide();
        _navigateToSubscriptionScreen();
        return;
      }

      // Step 4: Restore Purchases
      LoadingOverlay.updateMessage('Checking your subscription...');
      await _restorePurchasesAndSync();

      // Step 5: Check Subscription
      final hasActiveSubscription = await _checkRevenueCatSubscription();

      if (hasActiveSubscription) {
        LoadingOverlay.updateMessage('Loading your workspace...');
        await TokenStorage.saveSubscriptionCheckDone(true);
        await Future.delayed(Duration(milliseconds: 300));
        LoadingOverlay.hide();
        _navigateToMainScreen();
        return;
      }

      // Step 6: Navigate to Subscription
      await _isFirstTimeUser();
      LoadingOverlay.hide();
      _navigateToSubscriptionScreen();

      print('✅ POST-LOGIN COMPLETE\n');

    } catch (e, stackTrace) {
      print('❌ POST-LOGIN ERROR: $e\n$stackTrace');
      LoadingOverlay.hide();
      _navigateToSubscriptionScreen();
    }
  }

  Future<int?> _getUserIdSafely() async {
    try {
      final userId = await TokenStorage.getUserId().timeout(
        Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (userId == null || userId <= 0) return null;
      return userId;

    } catch (e) {
      print('❌ User ID error: $e');
      return null;
    }
  }

  Future<bool> _isAdminOrClientUser() async {
    try {
      if (ADMIN_EMAIL.isEmpty && CLIENT_EMAIL.isEmpty) return false;

      final userEmail = await TokenStorage.getUserEmail().timeout(
        Duration(seconds: 2),
        onTimeout: () => null,
      );

      if (userEmail == null) return false;

      final emailLower = userEmail.toLowerCase();

      // Check both ADMIN_EMAIL and CLIENT_EMAIL
      return emailLower == ADMIN_EMAIL.toLowerCase() ||
          emailLower == CLIENT_EMAIL.toLowerCase();

    } catch (e) {
      return false;
    }
  }

  Future<bool> _ensurePaymentControllerReady(int userId) async {
    try {
      // Clean up existing
      if (Get.isRegistered<PaymentController>()) {
        Get.delete<PaymentController>(force: true);
        await Future.delayed(Duration(milliseconds: 50));
      }

      // Create new
      Get.put(PaymentController(userId: userId));
      final controller = Get.find<PaymentController>();

      // Wait for RevenueCat
      int attempts = 0;
      while (!controller.isRevenueCatAvailable.value && attempts < 40) {
        await Future.delayed(Duration(milliseconds: 100));
        attempts++;
      }

      return controller.isRevenueCatAvailable.value &&
          controller.isRevenueCatUserLoggedIn.value;

    } catch (e) {
      print('❌ Controller error: $e');
      return false;
    }
  }

  Future<void> _restorePurchasesAndSync() async {
    try {
      final controller = Get.find<PaymentController>();

      await controller.restorePurchases().timeout(
        Duration(seconds: 10),
        onTimeout: () {},
      );

      await Future.delayed(Duration(milliseconds: 800));

      await controller.getCustomerInfo().timeout(
        Duration(seconds: 8),
        onTimeout: () {},
      );

    } catch (e) {
      print('⚠️ Restore error: $e');
    }
  }

  Future<bool> _isFirstTimeUser() async {
    try {
      final checkDone = await TokenStorage.getSubscriptionCheckDone().timeout(
        Duration(seconds: 2),
        onTimeout: () => null,
      );

      if (checkDone == true) return false;

      try {
        final controller = Get.find<PaymentController>();
        final customerInfo = controller.customerInfo.value;

        if (customerInfo != null) {
          final hasHistory =
              customerInfo.allPurchasedProductIdentifiers.isNotEmpty ||
                  customerInfo.nonSubscriptionTransactions.isNotEmpty ||
                  customerInfo.entitlements.all.isNotEmpty;

          if (hasHistory) {
            await TokenStorage.saveSubscriptionCheckDone(true);
            return false;
          }
        }
      } catch (e) {}

      return true;
    } catch (e) {
      return true;
    }
  }

  Future<bool> _checkRevenueCatSubscription() async {
    try {
      final controller = Get.find<PaymentController>();

      try {
        await controller.getCustomerInfo().timeout(
          Duration(seconds: 8),
          onTimeout: () {},
        );
      } catch (e) {}

      final customerInfo = controller.customerInfo.value;
      if (customerInfo == null) return false;

      return customerInfo.entitlements.active.isNotEmpty;

    } catch (e) {
      return false;
    }
  }

  void _navigateToSubscriptionScreen() {
    Future.delayed(Duration(milliseconds: 100), () {
      Get.offAll(() => SubscriptionScreen());
    });
  }

  void _navigateToMainScreen() {
    Future.delayed(Duration(milliseconds: 100), () {
      Get.offAll(() => MainScreen());
    });
  }

  static Future<void> markSubscriptionScreenShown() async {
    try {
      await TokenStorage.saveSubscriptionCheckDone(true);
      final verified = await TokenStorage.verifySubscriptionFlagSaved(true);
      if (verified) {
        print('✅ Subscription marked');
      }
    } catch (e) {
      print('❌ Mark error: $e');
    }
  }
}