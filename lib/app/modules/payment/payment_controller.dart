import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hr/app/api_servies/api_Constant.dart';
import 'package:hr/app/api_servies/neteork_api_services.dart';
import 'package:hr/app/modules/congratulaion_screen/congratulation_view.dart';

class SubscriptionPlan {
  final int id;
  final String name;
  final String planType;
  final String price;
  final String interval;
  final String stripePriceId;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.price,
    required this.interval,
    required this.stripePriceId,
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

  // Stripe payment variables
  String? _clientSecret;
  String? _setupIntentId;
  String? _paymentMethodId;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
    _initializeStripe();
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

    try {
      isLoading.value = true;
      paymentInProgress.value = true;
      print('🚀 Starting free trial process for plan: ${selectedPlanData!.planType}');

      // Step 1: Check current subscription status
      print('📋 Step 1: Checking subscription status...');
      final statusResponse = await _checkSubscriptionStatus();
      if (statusResponse?['data']?['is_active'] == true ||
          statusResponse?['data']?['is_trial_active'] == true ) {
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
      print('❌ Error in startFreeTrial: $e');

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

  // Check existing plans API call
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

  // Check subscription status API call
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

  // Create setup intent API call
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

  // Present Stripe payment sheet - FIXED VERSION
  Future<void> _presentPaymentSheet() async {
    if (_clientSecret == null) {
      throw Exception('Client secret not found');
    }

    try {
      // google pay -------

      var gpay = const PaymentSheetGooglePay(
        merchantCountryCode: "US", // or your actual country
        currencyCode: "USD",
        testEnv: true, // Set true for development testing

      );


      // Initialize payment sheet
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

      // Present payment sheet and get the result
      await Stripe.instance.presentPaymentSheet();

      // After successful payment sheet presentation, retrieve the setup intent to get payment method ID
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

  // Add payment method API call
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

  // Create subscription API call
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
    resetPaymentState();
    super.onClose();
  }
}