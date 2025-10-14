import 'dart:io';
import 'package:HRlynx/app/api_servies/api_Constant.dart';
import 'package:HRlynx/app/api_servies/neteork_api_services.dart';
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
      return "appl_DVYOGtnCsySsMcoKkRTVYpJlQZw";
    } else {
      return "goog_fHaUFeIYngJgHloZDbONohOyWSM";
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
        periodType = activeEntitlement.periodType.name; // 'normal', 'trial', 'intro'
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
      };

      print('📤 Sending data to backend:');
      print(body);

      final response = await NetworkApiServices.postApi(
        url,
        body,
        withAuth: true,
        tokenType: 'login',
      );

      if (response != null && response['success'] == true) {
        print('✅ User linked to backend successfully');
        print('@@@@@  revunueCat data send to backend successfully');
      } else {
        throw Exception('Failed to link user to backend');
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

      if (response != null && response['success'] == true) {
        final List<dynamic> plansData = response['data']['plans'] ?? response['data'];

        final plans = plansData.map((plan) => SubscriptionPlan.fromJson(plan)).toList();
        print('✅ Plans fetched: ${plans.length} plans');

        for (var plan in plans) {
          print('📋 Plan: ${plan.planType} - Product ID: ${plan.revenuecatProductId}');
        }

        return plans;
      } else {
        print('❌ Failed to fetch plans: Invalid response');
        throw Exception('Failed to load subscription plans');
      }
    } catch (e) {
      print('❌ Error fetching plans: $e');
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



  // ============================================
  // Helpers
  // ============================================

  Package? findPackage(List<Package> packages, String productId, String selectedPlanType) {
    // Method 1: Direct product ID match
    Package? package = packages.firstWhereOrNull(
          (p) => p.storeProduct.identifier == productId,
    );

    if (package != null) return package;

    // Method 2: By package type
    if (productId.contains('monthly') || selectedPlanType == 'monthly') {
      package = packages.firstWhereOrNull(
            (p) => p.packageType == PackageType.monthly,
      );
    } else if (productId.contains('yearly') || selectedPlanType == 'yearly') {
      package = packages.firstWhereOrNull(
            (p) => p.packageType == PackageType.annual,
      );
    }

    if (package != null) return package;

    // Method 3: By identifier match
    package = packages.firstWhereOrNull(
          (p) => p.identifier == productId,
    );

    return package;
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