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

  // Observable variables
  var selectedPlan = 'yearly'.obs;
  var isLoading = false.obs;
  var plans = <SubscriptionPlan>[].obs;
  var hasPlans = false.obs;
  var paymentInProgress = false.obs;

  // RevenueCat variables
  var isRevenueCatAvailable = false.obs;
  var revenueCatPackages = <Package>[].obs;
  var customerInfo = Rxn<CustomerInfo>();

  @override
  void onInit() {
    super.onInit();
    _initializeRevenueCat().then((_) {
      fetchPlans();
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
      String userId = "user_${userController.userID}";
      print("passing userId to revenueCat :$userId");
      LogInResult result = await _repository.loginUser(userId);
      customerInfo.value = result.customerInfo;

      await _repository.linkUserToBackend(result.customerInfo.originalAppUserId);

    } catch (e) {
      print('❌ Error logging in user: $e');
    }
  }

  // Get customer info
  Future<void> getCustomerInfo() async {
    try {
      CustomerInfo info = await _repository.getCustomerInfo();
      customerInfo.value = info;
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

      // Set default selection
      if (plans.any((plan) => plan.planType == 'explorer_yearly')) {
        selectedPlan.value = 'yearly';
      } else if (plans.isNotEmpty) {
        selectedPlan.value = plans.first.planType.contains('monthly') ? 'monthly' : 'yearly';
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

  // Get currently selected plan
  SubscriptionPlan? get selectedPlanData {
    if (selectedPlan.value == 'yearly') {
      return plans.firstWhereOrNull((plan) => plan.planType == 'explorer_yearly');
    } else {
      return plans.firstWhereOrNull((plan) => plan.planType == 'explorer_monthly');
    }
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
      print('🚀 Starting purchase for plan: ${planData.planType}');
      print('🆔 Looking for product ID: ${planData.revenuecatProductId}');

      if (planData.revenuecatProductId == null) {
        throw Exception('RevenueCat product ID not found for plan: ${planData.planType}');
      }

      // Find package
      Package? package = _repository.findPackage(
        revenueCatPackages,
        planData.revenuecatProductId!,
        selectedPlan.value,
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

      if (customerInfo.entitlements.active.isNotEmpty) {
        final response = await _repository.checkSubscriptionStatus();

        if (response != null && response['success'] == true) {
          await TokenStorage.saveSubscriptionCheckDone(true);

          // Refresh subscription controller
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
          throw Exception('Failed to sync with backend');
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

  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;

      CustomerInfo info = await _repository.restorePurchases();
      customerInfo.value = info;

      if (info.entitlements.active.isNotEmpty) {
        Get.snackbar(
          'Success',
          'Purchases restored successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'No Purchases',
          'No active purchases found to restore.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Error restoring purchases: $e');
      Get.snackbar(
        'Error',
        'Failed to restore purchases',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
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