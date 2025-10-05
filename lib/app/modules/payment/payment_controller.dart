import 'dart:io';
import 'package:HRlynx/app/api_servies/api_Constant.dart';
import 'package:HRlynx/app/api_servies/neteork_api_services.dart';
import 'package:HRlynx/app/modules/congratulaion_screen/congratulation_view.dart';
import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:async';

class SubscriptionPlan {
  final int id;
  final String name;
  final String planType;
  final String price;
  final String interval;
  final String? revenuecatProductId;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.price,
    required this.interval,
    this.revenuecatProductId,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // Platform specific product ID selection
    String? productId;
    if (Platform.isAndroid) {
      productId = json['revenuecat_product_id_android'];
    } else if (Platform.isIOS) {
      productId = json['revenuecat_product_id_ios'];
    }

    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      planType: json['plan_type'],
      price: json['price'],
      interval: json['interval'],
      revenuecatProductId: productId,
      isActive: json['is_active'] ?? true,
    );
  }
}

class PaymentController extends GetxController {
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

  // Initialize RevenueCat - FIXED VERSION
  Future<void> _initializeRevenueCat() async {
    try {
      print('🚀 Initializing RevenueCat...');

      // Set log level for debugging
      await Purchases.setLogLevel(LogLevel.debug);

      // Get platform-specific API key
      String apiKey = _getRevenueCatKey();
      print('🔑 Using API key: ${apiKey.substring(0, 10)}...');

      // Configure RevenueCat
      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      isRevenueCatAvailable.value = true;
      print('✅ RevenueCat initialized successfully');

      // Login user and get customer info
      await _loginRevenueCatUser();
      await _getCustomerInfo();

    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      isRevenueCatAvailable.value = false;
      rethrow;
    }
  }

  // Get platform-specific RevenueCat key
  String _getRevenueCatKey() {
    if (Platform.isIOS) {
      return "appl_DVYOGtnCsySsMcoKkRTVYpJlQZw"; // Your iOS key
    } else {
      return "goog_fHaUFeIYngJgHloZDbONohOyWSM"; // Your Android key
    }
  }

  // Login user to RevenueCat
  Future<void> _loginRevenueCatUser() async {
    try {
      String userId = "user_${userController.userID}";
      print("👤 Logging in user: $userId");

      LogInResult result = await Purchases.logIn(userId);
      customerInfo.value = result.customerInfo;

      // Link user to backend
      await _linkUserToBackend(result.customerInfo.originalAppUserId);
      print('✅ User logged in successfully: ${result.customerInfo.originalAppUserId}');
    } catch (e) {
      print('❌ Error logging in user: $e');
    }
  }
// PaymentController এ add করুন
  Future<void> getCustomerInfo() async {
    await _getCustomerInfo();
  }
  // Get customer info
  Future<void> _getCustomerInfo() async {
    try {
      CustomerInfo info = await Purchases.getCustomerInfo();
      customerInfo.value = info;
      print('📋 Customer info updated. Active entitlements: ${info.entitlements.active.keys.toList()}');
    } catch (e) {
      print('❌ Error getting customer info: $e');
    }
  }

  // Link user to backend
  Future<void> _linkUserToBackend(String revenueCatUserId) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/revenuecat/link-user/";
      final body = {"revenuecat_user_id": revenueCatUserId};

      final response = await NetworkApiServices.postApi(
        url,
        body,
        withAuth: true,
        tokenType: 'login',
      );

      if (response != null && response['success'] == true) {
        print('✅ User linked to backend successfully');
      }
    } catch (e) {
      print('❌ Error linking user to backend: $e');
    }
  }

  // Load RevenueCat packages - IMPROVED VERSION
  Future<void> _loadRevenueCatPackages() async {
    if (!isRevenueCatAvailable.value) {
      print('⚠️ RevenueCat not available, skipping package loading');
      return;
    }

    try {
      print('📦 Loading RevenueCat packages...');
      Offerings offerings = await Purchases.getOfferings();

      print('🎯 Available offerings: ${offerings.all.keys.toList()}');

      // Try to get premium offering first
      Offering? targetOffering = offerings.getOffering("premium");

      // Fallback to current offering if premium not found
      if (targetOffering == null) {
        targetOffering = offerings.current;
        print('⚠️ Premium offering not found, using current offering');
      }

      if (targetOffering != null) {
        revenueCatPackages.assignAll(targetOffering.availablePackages);
        print('✅ Loaded ${revenueCatPackages.length} packages');

        // Debug: Print available packages
        for (var package in revenueCatPackages) {
          print('📦 Package: ${package.identifier}');
          print('   - Type: ${package.packageType}');
          print('   - Product ID: ${package.storeProduct.identifier}');
          print('   - Price: ${package.storeProduct.priceString}');
        }
      } else {
        print('❌ No offerings found');
      }
    } catch (e) {
      print('❌ Error loading RevenueCat packages: $e');
    }
  }

  // Fetch plans from API
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      print('🔄 Fetching subscription plans...');

      String url = "${ApiConstants.baseUrl}/api/subscription/revenuecat/plans/";
      final response = await NetworkApiServices.getApi(
        url,
        withAuth: true,
        tokenType: 'login',
      );

      if (response != null && response['success'] == true) {
        final List<dynamic> plansData = response['data']['plans'] ?? response['data'];

        plans.assignAll(
          plansData.map((plan) => SubscriptionPlan.fromJson(plan)).toList(),
        );
        hasPlans.value = plans.isNotEmpty;

        // Set default selection
        if (plans.any((plan) => plan.planType == 'explorer_yearly')) {
          selectedPlan.value = 'yearly';
        } else if (plans.isNotEmpty) {
          selectedPlan.value = plans.first.planType.contains('monthly') ? 'monthly' : 'yearly';
        }

        print('✅ Plans fetched: ${plans.length} plans');

        // Print plans for debugging
        for (var plan in plans) {
          print('📋 Plan: ${plan.planType} - Product ID: ${plan.revenuecatProductId}');
        }

        // Load RevenueCat packages after plans are loaded
        await _loadRevenueCatPackages();
      } else {
        print('❌ Failed to fetch plans: Invalid response');
        Get.snackbar('Error', 'Failed to load subscription plans');
      }
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

  // Start RevenueCat purchase - FIXED VERSION
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

      // Find package by multiple methods
      Package? package = _findPackage(planData.revenuecatProductId!);

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
      print('💰 Price: ${package.storeProduct.priceString}');

      // Start purchase
      PurchaseResult result = await Purchases.purchasePackage(package);

      // Handle success
      await _handlePurchaseSuccess(result.customerInfo);

    } catch (e) {
      print('❌ Purchase error: $e');
      _handlePurchaseError(e.toString());
    }
  }

  // Find package helper method
  Package? _findPackage(String productId) {
    // Method 1: Direct product ID match
    Package? package = revenueCatPackages.firstWhereOrNull(
          (p) => p.storeProduct.identifier == productId,
    );

    if (package != null) return package;

    // Method 2: By package type based on product ID
    if (productId.contains('monthly') || selectedPlan.value == 'monthly') {
      package = revenueCatPackages.firstWhereOrNull(
            (p) => p.packageType == PackageType.monthly,
      );
    } else if (productId.contains('yearly') || selectedPlan.value == 'yearly') {
      package = revenueCatPackages.firstWhereOrNull(
            (p) => p.packageType == PackageType.annual,
      );
    }

    if (package != null) return package;

    // Method 3: By identifier match
    package = revenueCatPackages.firstWhereOrNull(
          (p) => p.identifier == productId,
    );

    return package;
  }


  // Handle successful purchase
  Future<void> _handlePurchaseSuccess(CustomerInfo customerInfo) async {
    try {
      this.customerInfo.value = customerInfo;

      print('🎉 Purchase successful!');
      print('🎫 Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      if (customerInfo.entitlements.active.isNotEmpty) {
        final response = await checkSubscriptionStatus();

        if (response != null && response['success'] == true) {
          // ✅ Refresh UserIsSubcribedController
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
  // Handle successful purchase
  // Future<void> _handlePurchaseSuccess(CustomerInfo customerInfo) async {
  //   try {
  //     this.customerInfo.value = customerInfo;
  //
  //     print('🎉 Purchase successful!');
  //     print('🎫 Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');
  //
  //     // Check if user has active entitlements
  //     if (customerInfo.entitlements.active.isNotEmpty) {
  //       // Sync with backend
  //       final response = await checkSubscriptionStatus();
  //
  //       if (response != null && response['success'] == true) {
  //         Get.snackbar(
  //           'Success!',
  //           'Subscription activated successfully!',
  //           backgroundColor: Colors.green,
  //           colorText: Colors.white,
  //           duration: Duration(seconds: 3),
  //         );
  //
  //         // Navigate to success screen
  //         Get.off(() => CongratulationView());
  //       } else {
  //         throw Exception('Failed to sync with backend');
  //       }
  //     } else {
  //       throw Exception('No active entitlements found after purchase');
  //     }
  //   } catch (e) {
  //     print('❌ Error handling purchase success: $e');
  //     Get.snackbar(
  //       'Error',
  //       'Purchase completed but failed to activate. Please contact support.',
  //       backgroundColor: Colors.orange,
  //       colorText: Colors.white,
  //     );
  //   } finally {
  //     paymentInProgress.value = false;
  //     isLoading.value = false;
  //   }
  // }

  // Handle purchase error
  void _handlePurchaseError(String errorMessage) {
    paymentInProgress.value = false;
    isLoading.value = false;

    String userFriendlyMessage = errorMessage;

    // Handle common error types
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

  // Check subscription status
  Future<Map<String, dynamic>?> checkSubscriptionStatus() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/revenuecat/status/";
      final response = await NetworkApiServices.getApi(
        url,
        withAuth: true,
        tokenType: 'login',
      );
      return response;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return null;
    }
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
      print('🔄 Restoring purchases...');

      CustomerInfo customerInfo = await Purchases.restorePurchases();
      this.customerInfo.value = customerInfo;

      if (customerInfo.entitlements.active.isNotEmpty) {
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
    try {
      print('🧪 Testing RevenueCat connection...');

      // Test offerings
      Offerings offerings = await Purchases.getOfferings();
      print('📋 Available offerings: ${offerings.all.keys.toList()}');

      if (offerings.current != null) {
        print('✅ Current offering: ${offerings.current!.identifier}');
        print('📦 Packages: ${offerings.current!.availablePackages.length}');
      }

      // Test customer info
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      print('👤 Customer ID: ${customerInfo.originalAppUserId}');
      print('🎫 Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      print('✅ RevenueCat connection test completed');
    } catch (e) {
      print('❌ RevenueCat connection test failed: $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}