import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart';
import 'package:hr/app/api_servies/neteork_api_services.dart';
import 'package:hr/app/modules/congratulaion_screen/congratulation_view.dart';
import 'package:hr/app/modules/log_in/user_controller.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // RevenueCat import
import 'dart:async';
import 'package:flutter/foundation.dart';

class SubscriptionPlan {
  final int id;
  final String name;
  final String planType;
  final String price;
  final String interval;
  final String? revenuecatProductId; // Changed from googlePlayProductId
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.price,
    required this.interval,
    this.revenuecatProductId, // Changed
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

  // Observable variables (same as before)
  var selectedPlan = 'yearly'.obs;
  var isLoading = false.obs;
  var plans = <SubscriptionPlan>[].obs;
  var hasPlans = false.obs;
  var paymentInProgress = false.obs;

  // RevenueCat variables
  var isRevenueCatAvailable = false.obs;
  var revenueCatPackages = <Package>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
    _initializeRevenueCat();
  }

  // Initialize RevenueCat
  Future<void> _initializeRevenueCat() async {
    try {
      // Configure RevenueCat with your public key

      String getRevenueCatKey() {
        if (Platform.isIOS) {
          return "appl_DVYOGtnCsySsMcoKkRTVYpJlQZw"; // iOS key
        } else {
          return "goog_fHaUFeIYngJgHloZDbONohOyWSM"; // Android key
        }
      }

      PurchasesConfiguration configuration = PurchasesConfiguration(
        getRevenueCatKey(),
      );
      await Purchases.configure(configuration);

      isRevenueCatAvailable.value = true;
      print('✅ RevenueCat initialized successfully');

      // Login user if you have user ID
      await _loginRevenueCatUser();
    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      isRevenueCatAvailable.value = false;
    }
  }

  // Login user to RevenueCat
  Future<void> _loginRevenueCatUser() async {
    try {
      // Replace with your actual user ID logic
      String userId =
          "user_${userController.userID}"; // Or get from your auth system

      LogInResult result = await Purchases.logIn(userId);

      // Link user to your backend
      await _linkUserToBackend(result.customerInfo.originalAppUserId);

      print(
        '✅ User logged in to RevenueCat: ${result.customerInfo.originalAppUserId}',
      );
    } catch (e) {
      print('❌ Error logging in user: $e');
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

  // Load RevenueCat packages
  Future<void> _loadRevenueCatPackages() async {
    if (!isRevenueCatAvailable.value) return;

    try {
      Offerings offerings = await Purchases.getOfferings();

      if (offerings.current != null) {
        revenueCatPackages.assignAll(offerings.current!.availablePackages);
        print('✅ Loaded ${revenueCatPackages.length} RevenueCat packages');
      }
    } catch (e) {
      print('❌ Error loading RevenueCat packages: $e');
    }
  }

  // Fetch available plans from API (same structure, different endpoint)
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      print('🔄 Fetching subscription plans...');

      String url =
          "${ApiConstants.baseUrl}/api/subscription/revenuecat/plans/";
      final response = await NetworkApiServices.getApi(
        url,
        withAuth: true,
        tokenType: 'login',
      );

      if (response != null && response['success'] == true) {
        // Handle nested data structure
        final List<dynamic> plansData =
            response['data']['plans'] ?? response['data'];

        plans.assignAll(
          plansData.map((plan) => SubscriptionPlan.fromJson(plan)).toList(),
        );
        hasPlans.value = plans.isNotEmpty;

        // Set default selection (same logic)
        if (plans.any((plan) => plan.planType == 'explorer_yearly')) {
          selectedPlan.value = 'yearly';
        } else if (plans.isNotEmpty) {
          selectedPlan.value = plans.first.planType.contains('monthly')
              ? 'monthly'
              : 'yearly';
        }

        print('✅ Plans fetched successfully: ${plans.length} plans');

        // Load RevenueCat packages after plans are loaded
        if (isRevenueCatAvailable.value) {
          await _loadRevenueCatPackages();
        }
      } else {
        print('❌ Failed to fetch plans: Invalid response');
        Get.snackbar('Error', 'Failed to load subscription plans');
      }
    } catch (e) {
      print('❌ Error fetching plans: $e');
      Get.snackbar(
        'Error',
        'Failed to load subscription plans: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get currently selected plan data (same logic)
  SubscriptionPlan? get selectedPlanData {
    if (selectedPlan.value == 'yearly') {
      return plans.firstWhereOrNull(
        (plan) => plan.planType == 'explorer_yearly',
      );
    } else {
      return plans.firstWhereOrNull(
        (plan) => plan.planType == 'explorer_monthly',
      );
    }
  }

  // Start free trial process (same method name, different implementation)
  Future<void> startFreeTrial() async {
    if (isLoading.value || selectedPlanData == null) {
      print('⚠️ Cannot start trial: Loading or no plan selected');
      return;
    }

    await _startRevenueCatPurchase();
  }

  // Start RevenueCat purchase
  Future<void> _startRevenueCatPurchase() async {
    try {
      isLoading.value = true;
      paymentInProgress.value = true;
      print(
        '🚀 Starting RevenueCat purchase for plan: ${selectedPlanData!.planType}',
      );

      // Find the corresponding RevenueCat package
      final productId = selectedPlanData!.revenuecatProductId;
      if (productId == null) {
        throw Exception('RevenueCat product ID not found for this plan');
      }

      final package = revenueCatPackages.firstWhereOrNull(
        (p) => p.storeProduct.identifier == productId,
      );
      if (package == null) {
        throw Exception('RevenueCat package not loaded: $productId');
      }

      // Start the purchase flow
      PurchaseResult result = await Purchases.purchasePackage(package);

      // Handle successful purchase
      await _handleRevenueCatPurchaseSuccess(result.customerInfo);

      print('✅ RevenueCat purchase completed');
    } catch (e) {
      print('❌ Error in RevenueCat purchase: $e');
      _handlePurchaseError(e.toString());
    }
  }

  // Handle RevenueCat purchase success
  Future<void> _handleRevenueCatPurchaseSuccess(
    CustomerInfo customerInfo,
  ) async {
    try {
      // Check if user has active entitlements
      if (customerInfo.entitlements.active.isNotEmpty) {
        // Sync with your backend
        final response = await checkSubscriptionStatus();

        if (response != null && response['success'] == true) {
          Get.snackbar(
            'Success!',
            'Subscription activated successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
          Get.off(() => CongratulationView());
        } else {
          throw Exception('Failed to sync subscription status');
        }
      } else {
        throw Exception('No active entitlements found');
      }
    } catch (e) {
      print('❌ Error handling purchase success: $e');
      Get.snackbar(
        'Error',
        'Failed to activate subscription',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      paymentInProgress.value = false;
      isLoading.value = false;
    }
  }

  // Handle purchase error (similar to before)
  void _handlePurchaseError(String errorMessage) {
    paymentInProgress.value = false;
    isLoading.value = false;

    // Handle different error types
    if (errorMessage.contains('user cancelled') ||
        errorMessage.contains('cancelled')) {
      errorMessage = 'Purchase was cancelled';
    } else if (errorMessage.contains('payment')) {
      errorMessage = 'Payment failed';
    }

    Get.snackbar(
      'Purchase Failed',
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Check subscription status (same endpoint structure)
  Future<Map<String, dynamic>?> checkSubscriptionStatus() async {
    try {
      String url =
          "${ApiConstants.baseUrl}/api/subscription/revenuecat/status/"; // Changed from google-play/status
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

  @override
  void onClose() {
    super.onClose();
  }
}
