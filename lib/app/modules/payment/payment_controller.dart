// lib/app/modules/payment/payment_controller.dart
// 🏆 PRODUCTION READY - Industry Standard (Cleaned & Simplified)
// ✅ Anonymous → Automatic Apple/Google Email Link

import 'package:HRlynx/app/api_servies/repository/payment_repository.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/congratulaion_screen/congratulation_view.dart';
import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../api_servies/biometric_service.dart';

class PaymentController extends GetxController {
  final PaymentRepository _repository = PaymentRepository();
  final UserController userController = Get.put(UserController());
  final BiometricService biometricService = BiometricService();

  // Required userId (for backend sync only)
  final int? userId;

  PaymentController({this.userId});

  // Observable variables
  var selectedPlan = 'explorer_yearly'.obs;
  var isLoading = false.obs;
  var plans = <SubscriptionPlan>[].obs;
  var hasPlans = false.obs;
  var paymentInProgress = false.obs;

  var isRevenueCatAvailable = false.obs;
  var isRevenueCatUserLoggedIn = false.obs;
  var revenueCatPackages = <Package>[].obs;
  var customerInfo = Rxn<CustomerInfo>();
  bool hasUsedTrial = false;

  // ✅ Store actual RevenueCat user ID (anonymous → email after purchase)
  String? revenueCatActualUserId;

  @override
  void onInit() {
    super.onInit();
    _initializeRevenueCat().then((_) {
      fetchPlans();
      checkTrialStatus();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 STEP 1: Initialize RevenueCat (Simplified)
  // ═══════════════════════════════════════════════════════════
  Future<void> _initializeRevenueCat() async {
    try {
      print('\n🚀 ========================================');
      print('🚀 INITIALIZING REVENUECAT');
      print('🚀 ========================================\n');

      // Initialize SDK
      await _repository.initializeRevenueCat();
      isRevenueCatAvailable.value = true;
      print('✅ RevenueCat SDK initialized');

      // Get customer info (will be anonymous initially)
      CustomerInfo info = await _repository.getCustomerInfo();
      revenueCatActualUserId = info.originalAppUserId;
      customerInfo.value = info;
      isRevenueCatUserLoggedIn.value = true;

      print('👤 User ID: $revenueCatActualUserId');

      if (revenueCatActualUserId?.startsWith('\$RCAnonymousID:') == true) {
        print('ℹ️ Anonymous user - will link to Apple/Google email on purchase');
      } else if (revenueCatActualUserId?.contains('@') == true) {
        print('✅ Already linked to store account: $revenueCatActualUserId');
      }

      print('\n✅ ========================================');
      print('✅ REVENUECAT READY');
      print('✅ Has Subscription: ${hasActiveSubscription}');
      print('✅ ========================================\n');

    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      isRevenueCatAvailable.value = false;
      isRevenueCatUserLoggedIn.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📦 STEP 2: Load Plans & Packages
  // ═══════════════════════════════════════════════════════════
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;

      // Load plans from backend
      List<SubscriptionPlan> fetchedPlans = await _repository.fetchPlans();
      plans.assignAll(fetchedPlans);
      hasPlans.value = plans.isNotEmpty;

      print('\n📋 ===== PLANS LOADED =====');
      for (var plan in plans) {
        print('Plan: ${plan.planType}');
        print('  Name: ${plan.name}');
        print('  Price: \$${plan.price}');
        print('  Product ID: ${plan.revenuecatProductId}');
      }
      print('==========================\n');

      // Set default selected plan
      if (plans.any((plan) => plan.planType == 'explorer_yearly')) {
        selectedPlan.value = 'explorer_yearly';
      } else if (plans.any((plan) => plan.planType == 'explorer_monthly')) {
        selectedPlan.value = 'explorer_monthly';
      }

      // Load RevenueCat packages
      await _loadRevenueCatPackages();

    } catch (e) {
      print('❌ Error fetching plans: $e');
      Get.snackbar('Error', 'Failed to load subscription plans: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRevenueCatPackages() async {
    if (!isRevenueCatAvailable.value) {
      print('⚠️ RevenueCat not ready, skipping package loading');
      return;
    }

    try {
      List<Package> packages = await _repository.loadRevenueCatPackages();
      revenueCatPackages.assignAll(packages);
      print('✅ Loaded ${packages.length} RevenueCat packages');
    } catch (e) {
      print('❌ Error loading RevenueCat packages: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 💳 STEP 3: Purchase
  // ═══════════════════════════════════════════════════════════
  SubscriptionPlan? get selectedPlanData {
    final plan = plans.firstWhereOrNull((p) => p.planType == selectedPlan.value);
    if (plan != null) {
      print('✅ Selected Plan: ${plan.name} (\$${plan.price})');
    }
    return plan;
  }

  Future<void> startFreeTrial() async {
    if (isLoading.value || selectedPlanData == null) {
      print('⚠️ Cannot start purchase: Loading or no plan selected');
      return;
    }

    if (!isRevenueCatAvailable.value || !isRevenueCatUserLoggedIn.value) {
      Get.snackbar(
        'Error',
        'Payment system not ready. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await _startRevenueCatPurchase();
  }


  Future<void> _startRevenueCatPurchase() async {
    try {
      isLoading.value = true;
      paymentInProgress.value = true;

      final planData = selectedPlanData!;
      print('\n🚀 ===== STARTING PURCHASE =====');
      print('Plan: ${planData.planType}');
      print('Price: \$${planData.price}');
      print('Product ID: ${planData.revenuecatProductId}');
      print('Current User ID: $revenueCatActualUserId');
      print('=================================\n');

      if (planData.revenuecatProductId == null) {
        throw Exception('RevenueCat product ID not found');
      }

      Package? package = _repository.findPackage(
        revenueCatPackages,
        planData.revenuecatProductId!,
        planData.planType,
      );

      if (package == null) {
        throw Exception('Package not found for: ${planData.revenuecatProductId}');
      }

      print('✅ Found package: ${package.identifier}');

      // ✅ Make purchase - RevenueCat will automatically link to Apple/Google email
      CustomerInfo info = await _repository.purchasePackage(package);
      await _handlePurchaseSuccess(info);

    } on PlatformException catch (e) {
      // ✅ Handle PlatformException properly
      print('❌ Purchase error: $e');

      // Extract clean error message from PlatformException
      String errorMessage = 'Purchase failed';

      if (e.details != null && e.details is Map) {
        final details = e.details as Map;

        // Check if user cancelled
        if (details['userCancelled'] == true) {
          errorMessage = 'Purchase was cancelled';
        }
        // Otherwise use the readable message
        else if (details['message'] != null) {
          errorMessage = details['message'].toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      _handlePurchaseError(errorMessage);

    } catch (e) {
      // Handle other exceptions
      print('❌ Purchase error: $e');
      _handlePurchaseError('Purchase failed. Please try again.');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ Handle Purchase Success
  // ═══════════════════════════════════════════════════════════
  Future<void> _handlePurchaseSuccess(CustomerInfo customerInfo) async {
    try {
      print('🎉 Purchase completed!');

      // ✅ Check if user ID changed (anonymous → Apple/Google email)
      if (customerInfo.originalAppUserId != revenueCatActualUserId) {
        print('\n🎊 ========================================');
        print('🎊 USER LINKED TO STORE ACCOUNT!');
        print('🎊 ========================================');
        print('📧 Old ID: $revenueCatActualUserId');
        print('📧 New ID: ${customerInfo.originalAppUserId}');

        if (customerInfo.originalAppUserId.contains('@')) {
          print('✅ Now using Apple/Google account email!');
        }

        print('🎊 ========================================\n');
        revenueCatActualUserId = customerInfo.originalAppUserId;
      }

      this.customerInfo.value = customerInfo;
      print('🎫 Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      if (customerInfo.entitlements.active.isEmpty) {
        throw Exception('No active entitlements found after purchase');
      }

      // ✅ Sync with backend (async, non-blocking)
      _linkToBackendAsync(customerInfo);

      // Save locally
      await TokenStorage.saveSubscriptionCheckDone(true);

      // Update subscription controller
      try {
        final subController = Get.find<UserIsSubcribedController>();
        await subController.checkAndUpdateSubscriptionStatus();
      } catch (e) {
        print('⚠️ Could not refresh subscription controller: $e');
      }

      // Ask for biometric
      await _askToEnableBiometricAfterSubscription();

      Get.snackbar(
        'Success!',
        'Subscription activated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      Get.offAll(() => CongratulationView());

    } catch (e) {
      print('❌ Error handling purchase success: $e');
      Get.snackbar(
        'Error',
        'Purchase completed but failed to activate. Please contact support.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      paymentInProgress.value = false;
      isLoading.value = false;
    }
  }

// ═══════════════════════════════════════════════════════════
// 🔄 STEP 4: Restore Purchases (FIXED - With Backend Sync)
// ═══════════════════════════════════════════════════════════
  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;

      final isCalledFromLogin = Get.currentRoute.contains('login') ||
          Get.currentRoute.contains('splash');

      print('🔄 RESTORING PURCHASES');


      // ✅ Restore - will sync with Apple/Google account
      CustomerInfo info = await _repository.restorePurchases();

      // Update user ID if changed
      if (info.originalAppUserId != revenueCatActualUserId) {
        print('ℹ️ User ID updated: $revenueCatActualUserId → ${info.originalAppUserId}');

        if (info.originalAppUserId.contains('@')) {
          print('✅ Found store account email: ${info.originalAppUserId}');
        }

        revenueCatActualUserId = info.originalAppUserId;
      }

      customerInfo.value = info;

      // ✅ NEW: Check if user has active subscription
      final hasActiveEntitlements = info.entitlements.active.isNotEmpty;

      if (hasActiveEntitlements) {
        print('✅ Active subscription found!');
        print('🎫 Active entitlements: ${info.entitlements.active.keys.toList()}');

        // ✅ CRITICAL FIX: Sync with backend (just like purchase success)
        await _linkToBackendAsync(info);

        // ✅ Update local subscription flag
        await TokenStorage.saveSubscriptionCheckDone(true);

        // ✅ Update subscription controller
        try {
          final subController = Get.find<UserIsSubcribedController>();
          await subController.checkAndUpdateSubscriptionStatus();
          print('✅ Subscription controller updated');
        } catch (e) {
          print('⚠️ Could not refresh subscription controller: $e');
        }

        print('✅ Backend sync complete');
      } else {
        print('⚠️ No active subscription found');
      }

      // Show feedback (not on login/splash)
      // if (!isCalledFromLogin) {
      //   if (hasActiveEntitlements) {
      //     Get.snackbar(
      //       'Success',
      //       'Purchases restored successfully!',
      //       backgroundColor: Colors.green,
      //       colorText: Colors.white,
      //       duration: Duration(seconds: 2),
      //     );
      //   } else {
      //     Get.snackbar(
      //       'No Purchases',
      //       'No active purchases found to restore.',
      //       backgroundColor: Colors.orange,
      //       colorText: Colors.white,
      //       duration: Duration(seconds: 2),
      //     );
      //   }
      // }

      print('🔄 RESTORE COMPLETE');

    } catch (e) {
      print('❌ Error restoring purchases: $e');

      // ✅ Special handling for 409 conflict
      if (e.toString().contains('409') || e.toString().contains('INTEGRITY_ERROR')) {
        print('⚠️ RevenueCat ID conflict detected');
        print('💡 This means another user is using this subscription');
        print('💡 Please logout from RevenueCat and try again');

        // Try to logout from RevenueCat
        try {
          await Purchases.logOut();
          print('✅ RevenueCat logged out, please login again');
        } catch (logoutError) {
          print('⚠️ Could not logout from RevenueCat: $logoutError');
        }
      }

      if (!Get.currentRoute.contains('login')) {
        Get.snackbar(
          'Error',
          'Failed to restore purchases',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔗 Backend Sync (Async, Non-blocking)
  // ═══════════════════════════════════════════════════════════
  Future<void> _linkToBackendAsync(CustomerInfo info) async {
    try {
      print('🔗 Linking to backend (async)...');
      await _repository.linkUserToBackend(info);
      print('✅ Backend link complete');
    } catch (e) {
      print('⚠️ Backend link failed (non-critical): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔍 Check Customer Info
  // ═══════════════════════════════════════════════════════════
  Future<void> getCustomerInfo() async {
    try {
      CustomerInfo info = await _repository.getCustomerInfo();

      // Update user ID if changed
      if (info.originalAppUserId != revenueCatActualUserId) {
        print('🎉 User ID linked: $revenueCatActualUserId → ${info.originalAppUserId}');
        revenueCatActualUserId = info.originalAppUserId;
      }

      customerInfo.value = info;
      print('✅ Customer info updated');
    } catch (e) {
      print('❌ Error getting customer info: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🎯 Helper Methods
  // ═══════════════════════════════════════════════════════════
  bool get hasActiveSubscription {
    if (customerInfo.value == null) return false;
    return customerInfo.value!.entitlements.active.isNotEmpty;
  }

  List<String> get activeEntitlements {
    if (customerInfo.value == null) return [];
    return customerInfo.value!.entitlements.active.keys.toList();
  }

  Future<void> checkTrialStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      hasUsedTrial = info.nonSubscriptionTransactions.isNotEmpty ||
          info.entitlements.active.isNotEmpty;
      print('Has used trial: $hasUsedTrial');
    } catch (e) {
      print('Error checking trial status: $e');
    }
  }

  Map<String, dynamic> getVerificationStatus() {
    return {
      'isRevenueCatAvailable': isRevenueCatAvailable.value,
      'isLoggedIn': isRevenueCatUserLoggedIn.value,
      'userId': revenueCatActualUserId,
      'isStoreEmail': revenueCatActualUserId?.contains('@') ?? false,
      'isAnonymous': revenueCatActualUserId?.startsWith('\$RCAnonymousID:') ?? false,
      'hasActiveSubscription': hasActiveSubscription,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // 🔐 Biometric Prompt
  // ═══════════════════════════════════════════════════════════
  Future<void> _askToEnableBiometricAfterSubscription() async {
    try {
      final isAvailable = await biometricService.isBiometricAvailable();
      if (!isAvailable) return;

      final isEnabled = await biometricService.isBiometricEnabled();
      if (isEnabled) return;

      final email = await TokenStorage.getUserEmail();
      if (email == null) return;

      final biometrics = await biometricService.getAvailableBiometrics();
      final biometricName = biometricService.getBiometricTypeName(biometrics);

      await Future.delayed(Duration(milliseconds: 500));

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blue, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text('Enable $biometricName?', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          content: Text(
            'Would you like to enable $biometricName for faster login next time?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Enable', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (result == true) {
        final authenticated = await biometricService.authenticate(
          reason: 'Verify your identity to enable $biometricName',
        );

        if (authenticated) {
          final success = await biometricService.enableBiometricLogin(email);
          if (success) {
            Get.snackbar(
              "Success",
              "$biometricName enabled successfully",
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error in biometric prompt: $e');
    }
  }

  void _handlePurchaseError(String errorMessage) {
    paymentInProgress.value = false;
    isLoading.value = false;

    // Don't show snackbar if user cancelled
    if (errorMessage.toLowerCase().contains('cancelled')) {
      Get.snackbar(
        'Cancelled',
        errorMessage,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      return;
    }

    // For other errors
    Get.snackbar(
      'Purchase Failed',
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }
}

// Extension helper
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}