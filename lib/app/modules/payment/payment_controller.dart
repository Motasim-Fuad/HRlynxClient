
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

  // ✅ ERROR HANDLING STATES
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var errorType = ''.obs; // 'network', 'server', 'generic'

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
  // ✅ ERROR HANDLING HELPERS
  // ═══════════════════════════════════════════════════════════
  void _handleError(dynamic error, {String context = 'Operation'}) {
    final errorStr = error.toString().toLowerCase();

    print('❌ Error in $context: $error');

    hasError.value = true;

    if (errorStr.contains('network_error') ||
        errorStr.contains('socket') ||
        errorStr.contains('failed host lookup')) {
      errorType.value = 'network';
      errorMessage.value = 'No internet connection';
      print('📶 Network error detected');
    } else if (errorStr.contains('server_error') ||
        errorStr.contains('503') ||
        errorStr.contains('500') ||
        errorStr.contains('cloudflare')) {
      errorType.value = 'server';
      errorMessage.value = 'Server is temporarily down';
      print('🌐 Server error detected');
    } else if (errorStr.contains('timeout')) {
      errorType.value = 'network';
      errorMessage.value = 'Connection timeout';
      print('⏱️ Timeout error detected');
    } else if (errorStr.contains('session') || errorStr.contains('401')) {
      errorType.value = 'auth';
      errorMessage.value = 'Session expired';
      print('🔐 Session error detected');
    } else {
      errorType.value = 'generic';
      errorMessage.value = 'Something went wrong';
      print('⚠️ Generic error detected');
    }

    print('📝 Final error: type=${errorType.value}, message=${errorMessage.value}');
  }

  void clearError() {
    hasError.value = false;
    errorMessage.value = '';
    errorType.value = '';
    print('✅ Error cleared');
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 STEP 1: Initialize RevenueCat (WITH ERROR HANDLING)
  // ═══════════════════════════════════════════════════════════
  Future<void> _initializeRevenueCat() async {
    try {
      clearError();

      await _repository.initializeRevenueCat();
      isRevenueCatAvailable.value = true;
      print('✅ RevenueCat SDK initialized');

      CustomerInfo info = await _repository.getCustomerInfo();
      revenueCatActualUserId = info.originalAppUserId;
      customerInfo.value = info;
      isRevenueCatUserLoggedIn.value = true;

      print('✅ User ID: $revenueCatActualUserId');

      if (revenueCatActualUserId?.startsWith('\$RCAnonymousID:') == true) {
        print('📝 Anonymous user - will link to Apple/Google email on purchase');
      } else if (revenueCatActualUserId?.contains('@') == true) {
        print('✅ Already linked to store account: $revenueCatActualUserId');
      }

      print('\n✅ ========================================');
      print('✅ REVENUECAT READY');
      print('✅ Has Subscription: ${hasActiveSubscription}');
      print('✅ ========================================\n');

    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      _handleError(e, context: 'RevenueCat initialization');
      isRevenueCatAvailable.value = false;
      isRevenueCatUserLoggedIn.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📦 STEP 2: Load Plans & Packages (WITH ERROR HANDLING)
  // ═══════════════════════════════════════════════════════════
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      clearError();

      print('📡 Fetching subscription plans...');

      // Load plans from backend
      List<SubscriptionPlan> fetchedPlans = await _repository.fetchPlans();
      plans.assignAll(fetchedPlans);
      hasPlans.value = plans.isNotEmpty;

      print('\n✅ ===== PLANS LOADED =====');
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
      _handleError(e, context: 'Loading subscription plans');
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
      _handleError(e, context: 'Loading packages');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 💳 STEP 3: Purchase (WITH ERROR HANDLING)
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
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    await _startRevenueCatPurchase();
  }

  Future<void> _startRevenueCatPurchase() async {
    try {
      isLoading.value = true;
      paymentInProgress.value = true;
      clearError();

      final planData = selectedPlanData!;
      print('\n💳 ===== STARTING PURCHASE =====');
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

      CustomerInfo info = await _repository.purchasePackage(package);
      await _handlePurchaseSuccess(info);

    } on PlatformException catch (e) {
      print('❌ Purchase PlatformException: $e');

      String errorMessage = 'Purchase failed';

      if (e.details != null && e.details is Map) {
        final details = e.details as Map;

        if (details['userCancelled'] == true) {
          errorMessage = 'Purchase was cancelled';
        } else if (details['message'] != null) {
          errorMessage = details['message'].toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      _handlePurchaseError(errorMessage);

    } catch (e) {
      print('❌ Purchase error: $e');
      _handleError(e, context: 'Purchase');
      _handlePurchaseError('Purchase failed. Please try again.');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ Handle Purchase Success
  // ═══════════════════════════════════════════════════════════
  Future<void> _handlePurchaseSuccess(CustomerInfo customerInfo) async {
    try {
      print('🎉 Purchase completed!');

      if (customerInfo.originalAppUserId != revenueCatActualUserId) {
        print('\n✅ ========================================');
        print('✅ USER LINKED TO STORE ACCOUNT!');
        print('✅ ========================================');
        print('Old ID: $revenueCatActualUserId');
        print('New ID: ${customerInfo.originalAppUserId}');

        if (customerInfo.originalAppUserId.contains('@')) {
          print('✅ Now using Apple/Google account email!');
        }

        print('========================================\n');
        revenueCatActualUserId = customerInfo.originalAppUserId;
      }

      this.customerInfo.value = customerInfo;
      print('✅ Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      if (customerInfo.entitlements.active.isEmpty) {
        throw Exception('No active entitlements found after purchase');
      }

      _linkToBackendAsync(customerInfo);

      await TokenStorage.saveSubscriptionCheckDone(true);

      try {
        final subController = Get.find<UserIsSubcribedController>();
        await subController.checkAndUpdateSubscriptionStatus();
      } catch (e) {
        print('⚠️ Could not refresh subscription controller: $e');
      }

      await _askToEnableBiometricAfterSubscription();

      Get.snackbar(
        'Success!',
        'Subscription activated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: Icon(Icons.check_circle, color: Colors.white),
        duration: Duration(seconds: 3),
      );

      Get.offAll(() => CongratulationView());

    } catch (e) {
      print('❌ Error handling purchase success: $e');
      _handleError(e, context: 'Activating subscription');

      Get.snackbar(
        'Error',
        'Purchase completed but failed to activate. Please contact support.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: Icon(Icons.warning, color: Colors.white),
      );
    } finally {
      paymentInProgress.value = false;
      isLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔄 STEP 4: Restore Purchases (WITH ERROR HANDLING)
  // ═══════════════════════════════════════════════════════════
  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;
      clearError();

      final isCalledFromLogin = Get.currentRoute.contains('login') ||
          Get.currentRoute.contains('splash');

      print('🔄 RESTORING PURCHASES');

      CustomerInfo info = await _repository.restorePurchases();

      if (info.originalAppUserId != revenueCatActualUserId) {
        print('✅ User ID updated: $revenueCatActualUserId → ${info.originalAppUserId}');

        if (info.originalAppUserId.contains('@')) {
          print('✅ Found store account email: ${info.originalAppUserId}');
        }

        revenueCatActualUserId = info.originalAppUserId;
      }

      customerInfo.value = info;

      final hasActiveEntitlements = info.entitlements.active.isNotEmpty;

      if (hasActiveEntitlements) {
        print('✅ Active subscription found!');
        print('✅ Active entitlements: ${info.entitlements.active.keys.toList()}');

        await _linkToBackendAsync(info);
        await TokenStorage.saveSubscriptionCheckDone(true);

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

      print('✅ RESTORE COMPLETE');

    } catch (e) {
      print('❌ Error restoring purchases: $e');
      _handleError(e, context: 'Restoring purchases');

      if (e.toString().contains('409') || e.toString().contains('INTEGRITY_ERROR')) {
        print('⚠️ RevenueCat ID conflict detected');

        try {
          await Purchases.logOut();
          print('✅ RevenueCat logged out');
        } catch (logoutError) {
          print('❌ Could not logout from RevenueCat: $logoutError');
        }
      }

      if (!Get.currentRoute.contains('login')) {
        Get.snackbar(
          'Error',
          'Failed to restore purchases',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: Icon(Icons.error_outline, color: Colors.white),
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

      if (info.originalAppUserId != revenueCatActualUserId) {
        print('✅ User ID linked: $revenueCatActualUserId → ${info.originalAppUserId}');
        revenueCatActualUserId = info.originalAppUserId;
      }

      customerInfo.value = info;
      print('✅ Customer info updated');
    } catch (e) {
      print('❌ Error getting customer info: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🛠️ Helper Methods
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
      print('✅ Has used trial: $hasUsedTrial');
    } catch (e) {
      print('❌ Error checking trial status: $e');
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

    if (errorMessage.toLowerCase().contains('cancelled')) {
      Get.snackbar(
        'Cancelled',
        errorMessage,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: Icon(Icons.cancel, color: Colors.white),
        duration: Duration(seconds: 2),
      );
      return;
    }

    Get.snackbar(
      'Purchase Failed',
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: Icon(Icons.error_outline, color: Colors.white),
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