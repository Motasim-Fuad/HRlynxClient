import 'dart:io';
import 'package:HRlynx/app/api_servies/api_Constant.dart';
import 'package:HRlynx/app/api_servies/neteork_api_services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
    try {
      String? productId;
      if (Platform.isAndroid) {
        productId = json['revenuecat_product_id_android'];
      } else if (Platform.isIOS) {
        productId = json['revenuecat_product_id_ios'];
      }

      // Add null safety checks and provide defaults
      return SubscriptionPlan(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Unknown Plan',
        planType: json['plan_type'] ?? 'unknown',
        price: json['price']?.toString() ?? '0', // Convert to string if not already
        interval: json['interval'] ?? 'month',
        revenuecatProductId: productId,
        isActive: json['is_active'] ?? true,
      );
    } catch (e) {
      print('❌ Error parsing SubscriptionPlan: $e');
      print('📋 Raw JSON: $json');
      rethrow;
    }
  }
}
class PaymentRepository {
  // ============================================
  // RevenueCat Configuration
  // ============================================

  Future<void> initializeRevenueCat() async {
    try {
      print('🚀 Initializing RevenueCat...');

      await Purchases.setLogLevel(LogLevel.debug);

      String apiKey = _getRevenueCatKey();
      print('🔑 Using API key: ${apiKey.substring(0, 10)}...');

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      print('✅ RevenueCat initialized successfully');
    } catch (e) {
      print('❌ Error initializing RevenueCat: $e');
      rethrow;
    }
  }

  String _getRevenueCatKey() {
    if (Platform.isIOS) {
      return dotenv.env['IOS_REVENUECAT_KEY'] ?? '';
    } else {
      return dotenv.env['ANDROID_REVENUECAT_KEY'] ?? '';
    }
  }

  // ============================================
  // RevenueCat User Management
  // ============================================

  Future<LogInResult> loginUser(String userId) async {
    try {
      print("👤 Logging in user: $userId");
      LogInResult result = await Purchases.logIn(userId);
      print('✅ User logged in successfully: ${result.customerInfo.originalAppUserId}');
      return result;
    } catch (e) {
      print('❌ Error logging in user: $e');
      rethrow;
    }
  }



// linkUserToBackend method in PaymentRepository

  Future<void> linkUserToBackend(CustomerInfo customerInfo) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/revenuecat/link-user/";

      // Extract entitlement data
      String? entitlementId;
      String? productId;
      String? expirationDate;
      bool willRenew = false;
      String? periodType;
      String? originalTransactionId;

      if (customerInfo.entitlements.active.isNotEmpty) {
        final activeEntitlement = customerInfo.entitlements.active.values.first;
        entitlementId = activeEntitlement.identifier;
        productId = activeEntitlement.productIdentifier;
        expirationDate = activeEntitlement.expirationDate?.toString();
        willRenew = activeEntitlement.willRenew;
        periodType = activeEntitlement.periodType.name;
        originalTransactionId = activeEntitlement.originalPurchaseDate != null
            ? activeEntitlement.productIdentifier
            : null;
      }

      final body = {
        "revenuecat_user_id": customerInfo.originalAppUserId,
        "has_active_subscription": customerInfo.entitlements.active.isNotEmpty,
        "status": customerInfo.entitlements.active.isNotEmpty ? "subscribed" : "free",
        "active_entitlements": customerInfo.entitlements.active.keys.toList(),
        "entitlement_id": entitlementId,
        "product_id": productId,
        "expiration_date": expirationDate,
        "will_renew": willRenew,
        "period_type": periodType,
        "active_subscriptions": customerInfo.activeSubscriptions.toList(),
        "first_seen": customerInfo.firstSeen.toString(),
        "original_app_version": customerInfo.originalApplicationVersion,
        "original_transaction_id": originalTransactionId,
        "force_update": true, // ✅ NEW: Tell backend to update if exists
      };

      print('📤 Sending data to backend:');
      print(body);

      // ✅ Try POST first (create new)
      try {
        final response = await NetworkApiServices.postApi(
          url,
          body,
          withAuth: true,
          tokenType: 'login',
        );

        if (response != null && response['success'] == true) {
          print('✅ User linked to backend successfully (POST)');
          print('@@@@@  revenueCat data sent to backend successfully');
          return;
        }
      } catch (postError) {
        print('⚠️ POST failed (might already exist): $postError');

        // ✅ If 409 conflict, try PUT to update
        if (postError.toString().contains('409')) {
          print('🔄 Trying PUT to update existing record...');

          try {
            final updateResponse = await NetworkApiServices.putApi(
              url,
              body,
              withAuth: true,
              tokenType: 'login',
            );

            if (updateResponse != null && updateResponse['success'] == true) {
              print('✅ User subscription UPDATED successfully (PUT)');
              print('@@@@@  revenueCat data updated in backend successfully');
              return;
            }
          } catch (putError) {
            print('❌ PUT also failed: $putError');
            throw Exception('Failed to update subscription: $putError');
          }
        }

        throw postError;
      }

    } catch (e) {
      print('❌ Error linking user to backend: $e');
      rethrow;
    }
  }

  // ============================================
  // Subscription Plans & Packages
  // ============================================

  Future<List<SubscriptionPlan>> fetchPlans() async {
    try {
      print('🔄 Fetching subscription plans...');

      String url = "${ApiConstants.baseUrl}/api/subscription/revenuecat/plans/";
      final response = await NetworkApiServices.getApi(
        url,
        withAuth: true,
        tokenType: 'login',
      );

      print('📥 API Response: $response'); // Debug: Print full response

      if (response != null && response['success'] == true) {
        // Handle different response structures
        final plansData = response['data']['plans'] ?? response['data'];

        if (plansData == null) {
          print('❌ No plans data found in response');
          throw Exception('No plans data in response');
        }

        print('📋 Raw plans data: $plansData'); // Debug: Print raw plans data

        // Ensure it's a List
        final List<dynamic> plansList = plansData is List ? plansData : [plansData];

        final plans = <SubscriptionPlan>[];

        for (var i = 0; i < plansList.length; i++) {
          try {
            final plan = SubscriptionPlan.fromJson(plansList[i]);
            plans.add(plan);
            print('✅ Plan ${i + 1}: ${plan.planType} - Product ID: ${plan.revenuecatProductId}');
          } catch (e) {
            print('❌ Error parsing plan at index $i: $e');
            print('📋 Problem plan data: ${plansList[i]}');
            // Continue to next plan instead of failing completely
          }
        }

        if (plans.isEmpty) {
          throw Exception('No valid plans could be parsed');
        }

        print('✅ Successfully fetched ${plans.length} plans');
        return plans;
      } else {
        print('❌ Failed to fetch plans: Invalid response');
        print('Response success: ${response?['success']}');
        throw Exception('Failed to load subscription plans');
      }
    } catch (e) {
      print('❌ Error fetching plans: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Package>> loadRevenueCatPackages() async {
    try {
      print('📦 Loading RevenueCat packages...');
      Offerings offerings = await Purchases.getOfferings();

      print('🎯 Available offerings: ${offerings.all.keys.toList()}');

      Offering? targetOffering = offerings.getOffering("premium");

      if (targetOffering == null) {
        targetOffering = offerings.current;
        print('⚠️ Premium offering not found, using current offering');
      }

      if (targetOffering != null) {
        final packages = targetOffering.availablePackages;
        print('✅ Loaded ${packages.length} packages');

        for (var package in packages) {
          print('📦 Package: ${package.identifier}');
          print('   - Type: ${package.packageType}');
          print('   - Product ID: ${package.storeProduct.identifier}');
          print('   - Price: ${package.storeProduct.priceString}');
        }

        return packages;
      } else {
        print('❌ No offerings found');
        return [];
      }
    } catch (e) {
      print('❌ Error loading RevenueCat packages: $e');
      rethrow;
    }
  }

  // ============================================
  // Purchase & Restore
  // ============================================

  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      print('🚀 Starting purchase for package: ${package.identifier}');
      print('💰 Price: ${package.storeProduct.priceString}');

      PurchaseResult result = await Purchases.purchasePackage(package);
      print('🎉 Purchase successful!');

      return result.customerInfo;
    } catch (e) {
      print('❌ Purchase error: $e');
      rethrow;
    }
  }

  Future<CustomerInfo> getCustomerInfo() async {
    try {
      CustomerInfo info = await Purchases.getCustomerInfo();
      print('📋 Customer info updated. Active entitlements: ${info.entitlements.active.keys.toList()}');
      return info;
    } catch (e) {
      print('❌ Error getting customer info: $e');
      rethrow;
    }
  }

  Future<CustomerInfo> restorePurchases() async {
    try {
      print('🔄 Restoring purchases...');
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      print('✅ Purchases restored');
      return customerInfo;
    } catch (e) {
      print('❌ Error restoring purchases: $e');
      rethrow;
    }
  }

  // ============================================
  // 🎯 SINGLE API - SUBSCRIPTION STATUS
  // ============================================

  /// ✅ ONE API TO RULE THEM ALL
  Future<Map<String, dynamic>?> checkSubscriptionStatus() async {
    try {
      print('🔍 Checking subscription status from backend...');

      String url = "${ApiConstants.baseUrl}/api/subscription/revenuecat/status/";
      final response = await NetworkApiServices.getApi(
        url,
        withAuth: true,
        tokenType: 'login',
      );

      if (response != null && response['success'] == true) {
        print('✅ Subscription status retrieved');
        print('@@@@@@@@   we receive revenueCat data from  backend successfully ....');
        print('backend Status: ${response['data']['status']}');
        print('backend Has Subscription: ${response['data']['has_subscription']}');
        print('backend Active Entitlements: ${response['data']['active_entitlements']}');
      }

      return response;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      return null;
    }
  }




  Package? findPackage(
      List<Package> packages,
      String productId,
      String selectedPlanType // This will be 'explorer_yearly' or 'explorer_monthly'
      ) {
    print('\n🔍 ===== FINDING PACKAGE =====');
    print('Looking for Product ID: $productId');
    print('Plan Type: $selectedPlanType');
    print('Available packages: ${packages.length}');

    // ✅ Method 1: Direct product ID match (BEST)
    Package? package = packages.firstWhereOrNull(
          (p) => p.storeProduct.identifier == productId,
    );

    if (package != null) {
      print('✅ FOUND by Product ID match!');
      print('   Package: ${package.identifier}');
      print('   Product: ${package.storeProduct.identifier}');
      return package;
    }

    print('⚠️ No direct match, trying package type...');

    // ✅ Method 2: By package type
    if (selectedPlanType.contains('yearly') || productId.contains('yearly')) {
      package = packages.firstWhereOrNull(
            (p) => p.packageType == PackageType.annual,
      );
      if (package != null) {
        print('✅ FOUND by PackageType.annual!');
        return package;
      }
    }

    if (selectedPlanType.contains('monthly') || productId.contains('monthly')) {
      package = packages.firstWhereOrNull(
            (p) => p.packageType == PackageType.monthly,
      );
      if (package != null) {
        print('✅ FOUND by PackageType.monthly!');
        return package;
      }
    }

    print('⚠️ No package type match, trying identifier...');

    // ✅ Method 3: By identifier match
    package = packages.firstWhereOrNull(
          (p) => p.identifier == productId,
    );

    if (package != null) {
      print('✅ FOUND by identifier match!');
      return package;
    }

    // ✅ Method 4: Flexible matching
    package = packages.firstWhereOrNull(
          (p) => p.storeProduct.identifier.toLowerCase().contains(productId.toLowerCase()) ||
          p.identifier.toLowerCase().contains(productId.toLowerCase()),
    );

    if (package != null) {
      print('✅ FOUND by flexible match!');
      return package;
    }

    print('❌ NO MATCH FOUND!');
    print('==============================\n');
    return null;
  }



  Future<void> testRevenueCatConnection() async {
    try {
      print('🧪 Testing RevenueCat connection...');

      Offerings offerings = await Purchases.getOfferings();
      print('📋 Available offerings: ${offerings.all.keys.toList()}');

      if (offerings.current != null) {
        print('✅ Current offering: ${offerings.current!.identifier}');
        print('📦 Packages: ${offerings.current!.availablePackages.length}');
      }

      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      print('👤 Customer ID: ${customerInfo.originalAppUserId}');
      print('🎫 Active entitlements: ${customerInfo.entitlements.active.keys.toList()}');

      print('✅ RevenueCat connection test completed');
    } catch (e) {
      print('❌ RevenueCat connection test failed: $e');
      rethrow;
    }
  }
}

// Extension for firstWhereOrNull
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}