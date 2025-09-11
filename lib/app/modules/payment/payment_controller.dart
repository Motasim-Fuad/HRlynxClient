import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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
  final String stripePriceId;
  final String? googlePlayProductId; // Add this for Google Play
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.price,
    required this.interval,
    required this.stripePriceId,
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
      stripePriceId: json['stripe_price_id'],
      googlePlayProductId: json['google_play_product_id'], // Add this
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
  var useGooglePlay = false.obs; // Toggle between Stripe and Google Play

  // Stripe payment variables
  String? _clientSecret;
  String? _setupIntentId;
  String? _paymentMethodId;

  // Google Play In-App Purchase variables
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  var isGooglePlayAvailable = false.obs;
  var googlePlayProducts = <ProductDetails>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
    _initializeStripe();
    _initializeGooglePlay();
  }

  // Initialize Stripe
  void _initializeStripe() {
    try {
      Stripe.instance.applySettings();
      print('✅ Stripe initialized successfully');
    } catch (e) {
      print('❌ Error initializing Stripe: $e');
    }
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
      String url = "${ApiConstants.baseUrl}/api/subscription/google-play/verify/";
      final body = {
        "product_id": purchaseDetails.productID,
        "purchase_token": purchaseDetails.purchaseID,
        "package_name": "com.lynxova.hrlnyx", // Your package name
        "purchase_details": {
          "orderId": purchaseDetails.purchaseID,
          "productId": purchaseDetails.productID,
          "purchaseTime": DateTime.now().millisecondsSinceEpoch,
          "purchaseState": purchaseDetails.status.index,
        }
      };

      final response = await NetworkApiServices.postApi(url, body, withAuth: true, tokenType: 'login');
      return response;
    } catch (e) {
      print('❌ Error verifying Google Play purchase: $e');
      return null;
    }
  }

  // Toggle payment method
  void togglePaymentMethod() {
    useGooglePlay.value = !useGooglePlay.value;
    print('💳 Payment method switched to: ${useGooglePlay.value ? "Google Play" : "Stripe"}');
  }

  // Select plan
  void selectPlan(String plan) {
    selectedPlan.value = plan;
    print('📋 Plan selected: $plan');
  }

  // Fetch available plans from API
  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      print('🔄 Fetching subscription plans...');

      final response = await _checkExistingPlans();

      if (response != null && response['success'] == true) {
        final data = response['data'];
        final List<dynamic> plansData = data['plans'];

        plans.assignAll(plansData.map((plan) => SubscriptionPlan.fromJson(plan)).toList());
        hasPlans.value = data['has_plans'];

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

  // Start free trial process - Updated to support both payment methods
  Future<void> startFreeTrial() async {
    if (isLoading.value || selectedPlanData == null) {
      print('⚠️ Cannot start trial: Loading or no plan selected');
      return;
    }

    if (useGooglePlay.value && isGooglePlayAvailable.value) {
      await _startGooglePlayPurchase();
    } else {
      await _startStripePurchase();
    }
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

  // Start Stripe purchase (your existing code)
  Future<void> _startStripePurchase() async {
    try {
      isLoading.value = true;
      paymentInProgress.value = true;
      print('🚀 Starting Stripe purchase for plan: ${selectedPlanData!.planType}');

      // Step 1: Check current subscription status
      print('📋 Step 1: Checking subscription status...');
      final statusResponse = await _checkSubscriptionStatus();
      if (statusResponse?['data']?['is_active'] == true ||
          statusResponse?['data']?['is_trial_active'] == true) {
        print('✅ User already has active subscription/trial');
        Get.off(() => CongratulationView());
        return;
      }

      // Step 2: Create setup intent
      print('💳 Step 2: Creating setup intent...');
      final setupIntentData = await _createSetupIntent();
      if (setupIntentData == null) {
        throw Exception('Failed to create setup intent');
      }
      print('✅ Setup intent created successfully');

      // Step 3: Present Stripe payment sheet
      print('🎨 Step 3: Presenting payment sheet...');
      await _presentPaymentSheet();
      print('✅ Payment method collected successfully');

      // Step 4: Add payment method to backend
      print('💾 Step 4: Adding payment method...');
      final addMethodResponse = await _addPaymentMethod();
      if (addMethodResponse == null || addMethodResponse['success'] != true) {
        throw Exception('Failed to add payment method');
      }
      print('✅ Payment method added successfully');

      // Step 5: Create subscription
      print('📝 Step 5: Creating subscription...');
      final subscriptionResponse = await _createSubscription();
      if (subscriptionResponse == null || subscriptionResponse['success'] != true) {
        throw Exception('Failed to create subscription');
      }
      print('✅ Subscription created successfully');

      // Success feedback
      Get.snackbar(
        'Success!',
        'Free trial started successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      // Navigate to congratulation screen
      Get.off(() => CongratulationView());

    } catch (e) {
      print('❌ Error in Stripe purchase: $e');

      String errorMessage = 'There was a problem with the payment process';

      if (e.toString().contains('cancelled') || e.toString().contains('canceled')) {
        errorMessage = 'Payment was cancelled';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Internet connection problem';
      }

      Get.snackbar(
        'Problem',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      paymentInProgress.value = false;
    }
  }

  // Your existing Stripe methods (unchanged)
  Future<Map<String, dynamic>?> _checkExistingPlans() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/setup/check-plans/";
      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
      return response;
    } catch (e) {
      print('❌ Error checking existing plans: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _checkSubscriptionStatus() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/status/";
      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
      return response;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _createSetupIntent() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/payment/setup-intent/";
      final response = await NetworkApiServices.postApi(url, {}, withAuth: true, tokenType: 'login');

      if (response != null && response['success'] == true) {
        _clientSecret = response['data']['client_secret'];
        _setupIntentId = response['data']['setup_intent_id'];
        print('✅ Setup intent created: $_setupIntentId');
        return response;
      }
      return null;
    } catch (e) {
      print('❌ Error creating setup intent: $e');
      return null;
    }
  }

  Future<void> _presentPaymentSheet() async {
    if (_clientSecret == null) {
      throw Exception('Client secret not found');
    }

    try {
      var gpay = const PaymentSheetGooglePay(
        merchantCountryCode: "US",
        currencyCode: "USD",
        testEnv: true,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          googlePay: gpay,
          setupIntentClientSecret: _clientSecret!,
          merchantDisplayName: 'Explorer Pro',
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.teal.shade700,
              background: Color(0xFF1a1a1a),
              componentBackground: Color(0xFF2a2a2a),
              componentBorder: Color(0xFF3a3a3a),
              componentDivider: Color(0xFF3a3a3a),
              primaryText: Colors.white,
              secondaryText: Colors.grey[300]!,
              componentText: Colors.white,
              icon: Colors.white,
              placeholderText: Colors.grey[400]!,
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
              borderWidth: 1,
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Colors.teal.shade700,
                  text: Colors.white,
                  border: Colors.teal.shade700,
                ),
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: Colors.teal.shade700,
                  text: Colors.white,
                  border: Colors.teal.shade700,
                ),
              ),
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final setupIntent = await Stripe.instance.retrieveSetupIntent(_clientSecret!);
      _paymentMethodId = setupIntent.paymentMethodId;

      if (_paymentMethodId == null) {
        throw Exception('Payment method ID not found after payment sheet');
      }

      print('✅ Payment method ID retrieved: $_paymentMethodId');

    } catch (e) {
      print('❌ Payment sheet error: $e');
      if (e is StripeException) {
        print('❌ Stripe Exception: ${e.error.localizedMessage}');
        if (e.error.code == FailureCode.Canceled) {
          throw Exception('Payment cancelled by user');
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _addPaymentMethod() async {
    if (_paymentMethodId == null) {
      throw Exception('Payment method ID not found');
    }

    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/payment/add-method/";
      final body = {
        "payment_method_id": _paymentMethodId,
      };

      print('📤 Adding payment method: $_paymentMethodId');
      final response = await NetworkApiServices.postApi(url, body, withAuth: true, tokenType: 'login');

      if (response != null && response['success'] == true) {
        print('✅ Payment method added successfully');
      }

      return response;
    } catch (e) {
      print('❌ Error adding payment method: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _createSubscription() async {
    if (_paymentMethodId == null || selectedPlanData == null) {
      throw Exception('Payment method or plan not found');
    }

    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/create/";
      final body = {
        "plan_type": selectedPlanData!.planType,
        "payment_method_id": _paymentMethodId,
      };

      print('📤 Creating subscription with plan: ${selectedPlanData!.planType}');
      final response = await NetworkApiServices.postApi(url, body, withAuth: true, tokenType: 'login');

      if (response != null && response['success'] == true) {
        print('✅ Subscription created successfully');
      }

      return response;
    } catch (e) {
      print('❌ Error creating subscription: $e');
      return null;
    }
  }

  // Reset payment state
  void resetPaymentState() {
    _clientSecret = null;
    _setupIntentId = null;
    _paymentMethodId = null;
    paymentInProgress.value = false;
    isLoading.value = false;
  }

  @override
  void onClose() {
    _subscription.cancel();
    resetPaymentState();
    super.onClose();
  }
}