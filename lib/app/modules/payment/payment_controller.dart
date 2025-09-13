import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart';
import 'package:hr/app/api_servies/neteork_api_services.dart';
import 'package:hr/app/modules/congratulaion_screen/congratulation_view.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class SubscriptionPlan {
  final int id;
  final String name;
  final String planType;
  final String price;
  final String interval;
  final String? googlePlayProductId;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.price,
    required this.interval,
    this.googlePlayProductId,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      planType: json['plan_type'],
      price: json['price'],
      interval: json['interval'],
      googlePlayProductId: json['google_play_product_id'],
      isActive: json['is_active'],
    );
  }
}

class PaymentController extends GetxController {
  // Observable variables
  var selectedPlan = 'yearly'.obs;
  var isLoading = false.obs;
  var plans = <SubscriptionPlan>[].obs;
  var hasPlans = false.obs;
  var paymentInProgress = false.obs;
  var useGooglePlay = true.obs; // Default to Google Play for Android

  // Google Play In-App Purchase variables
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  var isGooglePlayAvailable = false.obs;
  var googlePlayProducts = <ProductDetails>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
    _initializeGooglePlay();
  }

  // Initialize Google Play In-App Purchase
  Future<void> _initializeGooglePlay() async {
    try {
      // Check if Google Play is available
      final bool available = await _inAppPurchase.isAvailable();
      isGooglePlayAvailable.value = available;

      if (available) {
        // Listen for purchase updates
        final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _onPurchaseUpdated,
          onDone: () => _subscription.cancel(),
          onError: (error) => print('❌ Purchase stream error: $error'),
        );

        print('✅ Google Play In-App Purchase initialized successfully');
        _loadGooglePlayProducts();
      } else {
        print('⚠️ Google Play In-App Purchase not available');
      }
    } catch (e) {
      print('❌ Error initializing Google Play: $e');
    }
  }

  // Load Google Play products
  Future<void> _loadGooglePlayProducts() async {
    if (!isGooglePlayAvailable.value) return;

    try {
      // Get product IDs from your plans
      final Set<String> productIds = plans
          .where((plan) => plan.googlePlayProductId != null)
          .map((plan) => plan.googlePlayProductId!)
          .toSet();

      if (productIds.isEmpty) {
        print('⚠️ No Google Play product IDs found');
        return;
      }

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Products not found: ${response.notFoundIDs}');
      }

      googlePlayProducts.assignAll(response.productDetails);
      print('✅ Loaded ${googlePlayProducts.length} Google Play products');
    } catch (e) {
      print('❌ Error loading Google Play products: $e');
    }
  }

  // Handle Google Play purchase updates
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        print('🔄 Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        print('❌ Purchase error: ${purchaseDetails.error}');
        _handlePurchaseError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchase
        print('✅ Purchase successful: ${purchaseDetails.productID}');
        _handleGooglePlayPurchaseSuccess(purchaseDetails);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Handle Google Play purchase success
  Future<void> _handleGooglePlayPurchaseSuccess(PurchaseDetails purchaseDetails) async {
    try {
      // Send purchase details to your backend for verification
      final response = await _verifyGooglePlayPurchase(purchaseDetails);

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
        throw Exception('Failed to verify purchase');
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

  // Handle Google Play purchase error
  void _handlePurchaseError(IAPError error) {
    paymentInProgress.value = false;
    isLoading.value = false;

    String errorMessage = 'Purchase failed';

    switch (error.code) {
      case 'user_cancelled':
        errorMessage = 'Purchase was cancelled';
        break;
      case 'payment_invalid':
        errorMessage = 'Payment method is invalid';
        break;
      case 'payment_not_allowed':
        errorMessage = 'Payment is not allowed';
        break;
      default:
        errorMessage = 'Purchase failed: ${error.message}';
    }

    Get.snackbar(
      'Purchase Failed',
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Verify Google Play purchase on backend
  Future<Map<String, dynamic>?> _verifyGooglePlayPurchase(PurchaseDetails purchaseDetails) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/google-play/verify-purchase/";
      final body = {
        "product_id": purchaseDetails.productID,
        "purchase_token": purchaseDetails.purchaseID,
        "package_name": "com.lynxova.hrlnyx", // Your package name
      };

      final response = await NetworkApiServices.postApi(url, body, withAuth: true, tokenType: 'login');
      return response;
    } catch (e) {
      print('❌ Error verifying Google Play purchase: $e');
      return null;
    }
  }

  // Fetch available plans from API
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      print('🔄 Fetching subscription plans...');

      String url = "${ApiConstants.baseUrl}/api/subscription/google-play/plans/";
      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');

      if (response != null && response['success'] == true) {
        final List<dynamic> plansData = response['data'];

        plans.assignAll(plansData.map((plan) => SubscriptionPlan.fromJson(plan)).toList());
        hasPlans.value = plans.isNotEmpty;

        // Set default selection
        if (plans.any((plan) => plan.planType == 'explorer_yearly')) {
          selectedPlan.value = 'yearly';
        } else if (plans.isNotEmpty) {
          selectedPlan.value = plans.first.planType.contains('monthly') ? 'monthly' : 'yearly';
        }

        print('✅ Plans fetched successfully: ${plans.length} plans');

        // Load Google Play products after plans are loaded
        if (isGooglePlayAvailable.value) {
          await _loadGooglePlayProducts();
        }
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

  // Get currently selected plan data
  SubscriptionPlan? get selectedPlanData {
    if (selectedPlan.value == 'yearly') {
      return plans.firstWhereOrNull((plan) => plan.planType == 'explorer_yearly');
    } else {
      return plans.firstWhereOrNull((plan) => plan.planType == 'explorer_monthly');
    }
  }

  // Start free trial process
  Future<void> startFreeTrial() async {
    if (isLoading.value || selectedPlanData == null) {
      print('⚠️ Cannot start trial: Loading or no plan selected');
      return;
    }

    await _startGooglePlayPurchase();
  }

  // Start Google Play purchase
  Future<void> _startGooglePlayPurchase() async {
    try {
      isLoading.value = true;
      paymentInProgress.value = true;
      print('🚀 Starting Google Play purchase for plan: ${selectedPlanData!.planType}');

      // Find the corresponding Google Play product
      final productId = selectedPlanData!.googlePlayProductId;
      if (productId == null) {
        throw Exception('Google Play product ID not found for this plan');
      }

      final product = googlePlayProducts.firstWhereOrNull((p) => p.id == productId);
      if (product == null) {
        throw Exception('Google Play product not loaded: $productId');
      }

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

      // Start the purchase flow
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        throw Exception('Failed to initiate Google Play purchase');
      }

      print('✅ Google Play purchase flow initiated');
    } catch (e) {
      print('❌ Error in Google Play purchase: $e');
      paymentInProgress.value = false;
      isLoading.value = false;

      Get.snackbar(
        'Error',
        'Failed to start Google Play purchase: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Check subscription status
  Future<Map<String, dynamic>?> checkSubscriptionStatus() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/google-play/status/";
      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
      return response;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return null;
    }
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }
}