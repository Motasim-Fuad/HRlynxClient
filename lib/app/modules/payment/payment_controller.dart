import 'package:HRlynx/app/api_servies/repository/payment_repository.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/congratulaion_screen/congratulation_view.dart';
import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaymentController extends GetxController {
  final PaymentRepository _repository = PaymentRepository();
  final UserController userController = Get.put(UserController());
  // ✅ Add userId field
  final int? userId;

  // ✅ Add constructor
  PaymentController({this.userId});
  // Observable variables
  var selectedPlan = 'explorer_yearly'.obs;
  var isLoading = false.obs;
  var plans = <SubscriptionPlan>[].obs;
  var hasPlans = false.obs;
  var paymentInProgress = false.obs;

  // RevenueCat variables
  var isRevenueCatAvailable = false.obs;
  var revenueCatPackages = <Package>[].obs;
  var customerInfo = Rxn<CustomerInfo>();
  bool hasUsedTrial = false;

  @override
  void onInit() {
    super.onInit();
    _initializeRevenueCat().then((_) {
      fetchPlans();
      checkTrialStatus();
    });
  }

  // Initialize RevenueCat
  Future<void> _initializeRevenueCat() async {
    try {
      await _repository.initializeRevenueCat();
      isRevenueCatAvailable.value = true;

      await _loginRevenueCatUser();
      await getCustomerInfo();
    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      isRevenueCatAvailable.value = false;
      rethrow;
    }
  }

  // Login user to RevenueCat
  Future<void> _loginRevenueCatUser() async {
    try {
      // ✅ Use passed userId, fallback to storage
      int? effectiveUserId = userId;

      if (effectiveUserId == null) {
        effectiveUserId = await TokenStorage.getUserId();
      }

      if (effectiveUserId == null) {
        print('⚠️ No user ID available');
        return;
      }

      String revenueCatUserId = "revenuecatuser$effectiveUserId";
      print("✅ Logging in to RevenueCat: $revenueCatUserId");

      LogInResult result = await _repository.loginUser(revenueCatUserId);
      customerInfo.value = result.customerInfo;

      await _repository.linkUserToBackend(result.customerInfo);

    } catch (e) {
      print('❌ Error logging in user: $e');
    }
  }
  // Get customer info
  Future<void> getCustomerInfo() async {
    try {
      CustomerInfo info = await _repository.getCustomerInfo();
      customerInfo.value = info;
      print(info);
    } catch (e) {
      print('❌ Error getting customer info: $e');
    }
  }

  // Load RevenueCat packages
  Future<void> _loadRevenueCatPackages() async {
    if (!isRevenueCatAvailable.value) {
      print('⚠️ RevenueCat not available, skipping package loading');
      return;
    }

    try {
      List<Package> packages = await _repository.loadRevenueCatPackages();
      revenueCatPackages.assignAll(packages);
    } catch (e) {
      print('❌ Error loading RevenueCat packages: $e');
    }
  }

  // Fetch plans from API
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;

      List<SubscriptionPlan> fetchedPlans = await _repository.fetchPlans();
      plans.assignAll(fetchedPlans);
      hasPlans.value = plans.isNotEmpty;

      // ✅ Debug logs
      print('\n📋 ===== PLANS LOADED =====');
      for (var plan in plans) {
        print('Plan Type: ${plan.planType}');
        print('Name: ${plan.name}');
        print('Price: \$${plan.price}');
        print('RevenueCat Product ID: ${plan.revenuecatProductId}');
        print('---');
      }
      print('==========================\n');


      if (plans.any((plan) => plan.planType == 'explorer_yearly')) {
        selectedPlan.value = 'explorer_yearly';
        print('✅ Default selected: explorer_yearly');
      } else if (plans.any((plan) => plan.planType == 'explorer_monthly')) {
        selectedPlan.value = 'explorer_monthly';
        print('✅ Default selected: explorer_monthly');
      }

      // Load RevenueCat packages after plans are loaded
      await _loadRevenueCatPackages();
    } catch (e) {
      print('❌ Error fetching plans: $e');
      Get.snackbar('Error', 'Failed to load subscription plans: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }


  SubscriptionPlan? get selectedPlanData {
    final plan = plans.firstWhereOrNull((p) => p.planType == selectedPlan.value);

    if (plan != null) {
      print('✅ Selected Plan:');
      print('   Type: ${plan.planType}');
      print('   Name: ${plan.name}');
      print('   Price: \$${plan.price}');
      print('   Product ID: ${plan.revenuecatProductId}');
    } else {
      print('❌ No plan found for: ${selectedPlan.value}');
    }

    return plan;
  }

  // Start purchase process
  Future<void> startFreeTrial() async {
    if (isLoading.value || selectedPlanData == null) {
      print('⚠️ Cannot start purchase: Loading or no plan selected');
      return;
    }

    await _startRevenueCatPurchase();
  }

  // Start RevenueCat purchase
  Future<void> _startRevenueCatPurchase() async {
    try {
      isLoading.value = true;
      paymentInProgress.value = true;

      final planData = selectedPlanData!;
      print('\n🚀 ===== STARTING PURCHASE =====');
      print('Plan Type: ${planData.planType}');
      print('Plan Name: ${planData.name}');
      print('Price: \$${planData.price}');
      print('Product ID: ${planData.revenuecatProductId}');
      print('=================================\n');

      if (planData.revenuecatProductId == null) {
        throw Exception('RevenueCat product ID not found for plan: ${planData.planType}');
      }

      print('\n📦 ===== AVAILABLE PACKAGES =====');
      for (var p in revenueCatPackages) {
        print('Package ID: ${p.identifier}');
        print('Product ID: ${p.storeProduct.identifier}');
        print('Type: ${p.packageType}');
        print('Price: ${p.storeProduct.priceString}');
        print('---');
      }
      print('==================================\n');

      // Find package
      Package? package = _repository.findPackage(
        revenueCatPackages,
        planData.revenuecatProductId!,
        //selectedPlan.value,
        planData.planType,

      );

      if (package == null) {
        print('❌ Available packages:');
        for (var p in revenueCatPackages) {
          print('  - Product: ${p.storeProduct.identifier}');
          print('  - Package: ${p.identifier}');
          print('  - Type: ${p.packageType}');
        }
        throw Exception('Package not found for product: ${planData.revenuecatProductId}');
      }

      print('✅ Found package: ${package.identifier}');

      // Start purchase
      CustomerInfo info = await _repository.purchasePackage(package);
      await _handlePurchaseSuccess(info);
    } catch (e) {
      print('❌ Purchase error: $e');
      _handlePurchaseError(e.toString());
    }
  }

// Handle successful purchase
  Future<void> _handlePurchaseSuccess(CustomerInfo customerInfo) async {
    try {
      this.customerInfo.value = customerInfo;

      print('🎉 Purchase successful!');
      print('🎫 Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      await printFullRevenueCatData(customerInfo);

      if (customerInfo.entitlements.active.isNotEmpty) {
        // ✅ Sync updated data with backend
        await _repository.linkUserToBackend(customerInfo);

        // ✅ Verify subscription status from backend
        print('\n🔍 Verifying subscription status...');
        final statusResponse = await _repository.checkSubscriptionStatus();

        if (statusResponse != null && statusResponse['success'] == true) {
          print('✅ Subscription verified on backend');
          print('📊 Backend Status: ${statusResponse['data']}');

          await TokenStorage.saveSubscriptionCheckDone(true);

          try {
            final subController = Get.find<UserIsSubcribedController>();
            await subController.checkAndUpdateSubscriptionStatus();
            print('✅ UserIsSubcribedController refreshed successfully');
          } catch (e) {
            print('⚠️ Could not refresh subscription controller: $e');
          }

          Get.snackbar(
            'Success!',
            'Subscription activated successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );

          Get.offAll(() => CongratulationView());
        } else {
          throw Exception('Failed to verify subscription on backend');
        }
      } else {
        throw Exception('No active entitlements found after purchase');
      }
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

// ✅ Print full RevenueCat data
  Future<void> printFullRevenueCatData(CustomerInfo info) async {
    print('\n========================================');
    print('📋 FULL REVENUECAT CUSTOMER INFO');
    print('========================================');

    print('👤 User ID: ${info.originalAppUserId}');
    print('📅 First Seen: ${info.firstSeen}');
    print('📱 Original App Version: ${info.originalApplicationVersion}');

    print('\n🎫 ACTIVE ENTITLEMENTS:');
    if (info.entitlements.active.isNotEmpty) {
      info.entitlements.active.forEach((key, value) {
        print('  ✅ $key:');
        print('     Product: ${value.productIdentifier}');
        print('     Expires: ${value.expirationDate}');
        print('     Is Active: ${value.isActive}');
        print('     Will Renew: ${value.willRenew}');
        print('     Period Type: ${value.periodType}');
        print('     Purchase Date: ${value.originalPurchaseDate}');
      });
    } else {
      print('  ❌ No active entitlements');
    }

    print('\n📦 ALL ENTITLEMENTS:');
    info.entitlements.all.forEach((key, value) {
      print('  - $key: ${value.isActive ? "✅ Active" : "❌ Inactive"}');
    });

    print('\n💳 ACTIVE SUBSCRIPTIONS:');
    if (info.activeSubscriptions.isNotEmpty) {
      print('  ${info.activeSubscriptions}');
    } else {
      print('  ❌ No active subscriptions');
    }

    print('\n📅 EXPIRATION DATES:');
    if (info.allExpirationDates.isNotEmpty) {
      info.allExpirationDates.forEach((key, value) {
        print('  - $key: $value');
      });
    } else {
      print('  ❌ No expiration dates');
    }

    print('\n📅 PURCHASE DATES:');
    if (info.allPurchaseDates.isNotEmpty) {
      info.allPurchaseDates.forEach((key, value) {
        print('  - $key: $value');
      });
    } else {
      print('  ❌ No purchase dates');
    }

    print('\n📋 PURCHASED PRODUCTS:');
    if (info.allPurchasedProductIdentifiers.isNotEmpty) {
      print('  ${info.allPurchasedProductIdentifiers}');
    } else {
      print('  ❌ No purchased products');
    }

    print('\n🔄 LATEST EXPIRATION: ${info.latestExpirationDate ?? "N/A"}');

    print('\n📊 NON-SUBSCRIPTION TRANSACTIONS:');
    if (info.nonSubscriptionTransactions.isNotEmpty) {
      print('  ${info.nonSubscriptionTransactions.length} transactions');
    } else {
      print('  ❌ No non-subscription transactions');
    }

    print('========================================\n');
  }
  // Handle purchase error
  void _handlePurchaseError(String errorMessage) {
    paymentInProgress.value = false;
    isLoading.value = false;

    String userFriendlyMessage = errorMessage;

    if (errorMessage.toLowerCase().contains('user cancelled') ||
        errorMessage.toLowerCase().contains('cancelled')) {
      userFriendlyMessage = 'Purchase was cancelled';
    } else if (errorMessage.toLowerCase().contains('payment')) {
      userFriendlyMessage = 'Payment failed. Please try again.';
    } else if (errorMessage.toLowerCase().contains('network')) {
      userFriendlyMessage = 'Network error. Please check your connection.';
    } else if (errorMessage.toLowerCase().contains('not found')) {
      userFriendlyMessage = 'Product not available. Please try again later.';
    }

    Get.snackbar(
      'Purchase Failed',
      userFriendlyMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 5),
    );
  }

  // Check if user has active subscription
  bool get hasActiveSubscription {
    if (customerInfo.value == null) return false;
    return customerInfo.value!.entitlements.active.isNotEmpty;
  }

  // Get active entitlement names
  List<String> get activeEntitlements {
    if (customerInfo.value == null) return [];
    return customerInfo.value!.entitlements.active.keys.toList();
  }

  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;

      // ✅ Don't show snackbar during login flow
      final isCalledFromLogin = Get.currentRoute.contains('login') ||
          Get.currentRoute.contains('splash');

      CustomerInfo info = await _repository.restorePurchases();
      customerInfo.value = info;

      if (!isCalledFromLogin) {  // ✅ Only show snackbar if manual restore
        if (info.entitlements.active.isNotEmpty) {
          print("Success : Purchases restored successfully!");
        } else {
          print("No Purchases : No active purchases found to restore.");
        }
      }
    } catch (e) {
      print('❌ Error restoring purchases: $e');
      if (!Get.currentRoute.contains('login')) {
        print("Error :Failed to restore purchases");
      }
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> checkTrialStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      if (customerInfo.nonSubscriptionTransactions.isNotEmpty ||
          customerInfo.entitlements.active.isNotEmpty) {
        hasUsedTrial = true;
      } else {
        hasUsedTrial = false;
      }

      print('Has used trial: $hasUsedTrial');
    } catch (e) {
      print('Error checking trial status: $e');
    }
  }


  // Test RevenueCat connection
  Future<void> testRevenueCatConnection() async {
    await _repository.testRevenueCatConnection();
  }

  @override
  void onClose() {
    super.onClose();
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