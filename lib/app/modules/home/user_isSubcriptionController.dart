// lib/app/modules/home/user_isSubcriptionController.dart

import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/api_servies/repository/payment_repository.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
import '../../model/home/is_subcribed_model.dart';

class UserIsSubcribedController extends GetxController {
  final authRepo = AuthRepository();
  final paymentRepo = PaymentRepository();

  // 🔑 ADMIN EMAIL CONSTANT
  // static const String ADMIN_EMAIL = 'dart@gmail.com;
  static final String ADMIN_EMAIL = dotenv.env['ADMIN_ACCESS_EMAIL'] ?? '';


  // Optional PaymentController - won't break if not found
  PaymentController? get paymentController {
    try {
      return Get.find<PaymentController>();
    } catch (e) {
      print('⚠️ PaymentController not found: $e');
      return null;
    }
  }

  // Observable variables
  final subcriptionData = <Personas>[].obs;
  final isSubscribed = false.obs;
  final canSwitch = false.obs;
  final isLoading = false.obs;
  final selectedPersona = Rxn<Personas>();

  // RevenueCat subscription state
  final isCanceled = false.obs;
  final hasPremiumAccess = false.obs;
  final subscriptionStatus = ''.obs;
  final isActive = false.obs;
  final showReactivateButton = false.obs;

  // RevenueCat customer info
  final customerInfo = Rxn<CustomerInfo>();

  // 🆕 ADMIN FLAG
  final isAdminUser = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen to PaymentController changes if available
    final controller = paymentController;
    if (controller != null) {
      ever(controller.customerInfo, (_) {
        print('🔔 PaymentController customerInfo changed, syncing...');
        _syncWithRevenueCat();
      });
    }

    // Initial check
    checkAndUpdateSubscriptionStatus();
  }

  /// ============================================
  /// MAIN METHOD: Check and Update Subscription
  /// ============================================
  ///
  Future<void> checkAndUpdateSubscriptionStatus() async {
    try {
      isLoading.value = true;
      print('🔄 Checking subscription (RevenueCat only)...');

      // ✅ Step 1: Check admin .
      await _checkAdminStatus();
      if (isAdminUser.value) {
        _grantAdminAccess();
        await fetchIsSubcriptionData();
        await _ensureSelectedPersonaLoaded();
        return;
      }

      // ✅ Step 2: Sync with RevenueCat ONLY
      await _syncWithRevenueCatOnly();

      // ✅ Step 3: Fetch personas
      await fetchIsSubcriptionData();

      // ✅ Step 4: Load selected persona
      await _ensureSelectedPersonaLoaded();

      print('✅ Status updated (RevenueCat only)');
      print('📊 isActive: ${isActive.value}');
      print('📊 isCanceled: ${isCanceled.value}');
      print('📊 hasPremium: ${hasPremiumAccess.value}');

    } catch (e) {
      print('❌ Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> _syncWithRevenueCatOnly() async {
    try {
      print('📱 Syncing with RevenueCat...');

      // Get from PaymentController first
      if (paymentController != null && paymentController!.customerInfo.value != null) {
        customerInfo.value = paymentController!.customerInfo.value;
        print('✅ Got info from PaymentController');
      } else {
        // Fallback: Direct fetch
        try {
          CustomerInfo info = await Purchases.getCustomerInfo();
          customerInfo.value = info;
          print('✅ Fetched from RevenueCat');
        } catch (e) {
          print('❌ RevenueCat fetch failed: $e');
          _resetSubscriptionState();
          return;
        }
      }

      if (customerInfo.value == null) {
        _resetSubscriptionState();
        return;
      }

      // ✅ Check active entitlements
      final activeEntitlements = customerInfo.value!.entitlements.active;
      final hasActive = activeEntitlements.isNotEmpty;

      isActive.value = hasActive;
      hasPremiumAccess.value = hasActive;

      // ✅ Check if canceled
      final allEntitlements = customerInfo.value!.entitlements.all;
      if (allEntitlements.isNotEmpty) {
        final firstEntitlement = allEntitlements.values.first;
        isCanceled.value = firstEntitlement.willRenew == false;
      } else {
        isCanceled.value = false;
      }

      // ✅ Calculate subscription state
      isSubscribed.value = isActive.value && !isCanceled.value;
      showReactivateButton.value = isCanceled.value && isActive.value;

      // ✅ Set status
      if (isActive.value && !isCanceled.value) {
        subscriptionStatus.value = 'active';
      } else if (isActive.value && isCanceled.value) {
        subscriptionStatus.value = 'canceled_but_active';
      } else {
        subscriptionStatus.value = 'inactive';
      }

      print('✅ RevenueCat sync complete');

    } catch (e) {
      print('❌ Sync error: $e');
      _resetSubscriptionState();
    }
  }
  // Future<void> checkAndUpdateSubscriptionStatus() async {
  //   try {
  //     isLoading.value = true;
  //     print('🔄 Checking subscription status...');
  //
  //     // 🆕 Step 0: Check if user is admin
  //     await _checkAdminStatus();
  //
  //     if (isAdminUser.value) {
  //       print('👑 ADMIN USER DETECTED - Granting full access');
  //       _grantAdminAccess();
  //       await fetchIsSubcriptionData();
  //       await _ensureSelectedPersonaLoaded();
  //       print('✅ Admin access granted successfully');
  //       return;
  //     }
  //
  //     // Step 1: Sync with RevenueCat (source of truth)
  //     await _syncWithRevenueCat();
  //
  //     // Step 2: Sync with backend (optional cross-verification)
  //     await _syncWithBackend();
  //
  //     // Step 3: Fetch personas based on subscription
  //     await fetchIsSubcriptionData();
  //
  //     // Step 4: Ensure selected persona is loaded
  //     await _ensureSelectedPersonaLoaded();
  //
  //     print('✅ Subscription status updated successfully');
  //     print('📊 Final State:');
  //     print('   isAdmin: ${isAdminUser.value}');
  //     print('   isActive: ${isActive.value}');
  //     print('   isCanceled: ${isCanceled.value}');
  //     print('   isSubscribed: ${isSubscribed.value}');
  //     print('   hasPremiumAccess: ${hasPremiumAccess.value}');
  //
  //   } catch (e) {
  //     print('❌ Error in checkAndUpdateSubscriptionStatus: $e');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  /// ============================================
  /// 🆕 CHECK ADMIN STATUS
  /// ============================================
  Future<void> _checkAdminStatus() async {
    try {
      final userEmail = await TokenStorage.getUserEmail();

      if (userEmail != null && userEmail.toLowerCase() == ADMIN_EMAIL.toLowerCase()) {
        isAdminUser.value = true;
        print('👑 Admin user identified: $userEmail');
      } else {
        isAdminUser.value = false;
        print('👤 Regular user: ${userEmail ?? "unknown"}');
      }
    } catch (e) {
      print('❌ Error checking admin status: $e');
      isAdminUser.value = false;
    }
  }

  /// ============================================
  /// 🆕 GRANT ADMIN ACCESS
  /// ============================================
  void _grantAdminAccess() {
    isActive.value = true;
    isSubscribed.value = true;
    hasPremiumAccess.value = true;
    isCanceled.value = false;
    showReactivateButton.value = false;
    subscriptionStatus.value = 'admin_access';
    canSwitch.value = true; // Admin can switch personas

    print('👑 Admin privileges granted:');
    print('   - Full access to all personas');
    print('   - Can switch personas freely');
    print('   - No subscription restrictions');
  }

  /// ============================================
  /// Ensure Selected Persona is Loaded
  /// ============================================
  Future<void> _ensureSelectedPersonaLoaded() async {
    try {
      final storedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (storedPersonaId != null && selectedPersona.value == null) {
        print('🔍 Loading selected persona from storage: $storedPersonaId');

        final persona = subcriptionData.firstWhereOrNull(
                (p) => p.id == storedPersonaId
        );

        if (persona != null) {
          selectedPersona.value = persona;
          print('✅ Restored selected persona: ${persona.title}');
        } else {
          print('⚠️ Persona $storedPersonaId not found in local data');
        }
      }
    } catch (e) {
      print('❌ Error ensuring selected persona loaded: $e');
    }
  }

  /// ============================================
  /// Sync with RevenueCat (Source of Truth)
  /// ============================================
  Future<void> _syncWithRevenueCat() async {
    try {
      print('📱 Syncing with RevenueCat...');

      // Try to get customer info from PaymentController first
      if (paymentController != null && paymentController!.customerInfo.value != null) {
        customerInfo.value = paymentController!.customerInfo.value;
        print('✅ Got customer info from PaymentController');
      } else {
        // Fallback: Fetch directly from RevenueCat
        try {
          CustomerInfo info = await Purchases.getCustomerInfo();
          customerInfo.value = info;
          print('✅ Fetched customer info directly from RevenueCat');
        } catch (e) {
          print('❌ Failed to fetch customer info from RevenueCat: $e');
          _resetSubscriptionState();
          return;
        }
      }

      if (customerInfo.value == null) {
        print('⚠️ No RevenueCat customer info available');
        _resetSubscriptionState();
        return;
      }

      // Check active entitlements
      final activeEntitlements = customerInfo.value!.entitlements.active;
      final hasActiveEntitlement = activeEntitlements.isNotEmpty;

      print('🎫 Active entitlements: ${activeEntitlements.keys.toList()}');

      // Update subscription state
      isActive.value = hasActiveEntitlement;
      hasPremiumAccess.value = hasActiveEntitlement;

      // Check if subscription is canceled (will not renew)
      final allEntitlements = customerInfo.value!.entitlements.all;
      if (allEntitlements.isNotEmpty) {
        final firstEntitlement = allEntitlements.values.first;
        isCanceled.value = firstEntitlement.willRenew == false;

        print('📊 Entitlement details:');
        print('   willRenew: ${firstEntitlement.willRenew}');
        print('   isActive: ${firstEntitlement.isActive}');
        print('   expirationDate: ${firstEntitlement.expirationDate}');
      } else {
        isCanceled.value = false;
      }

      // Final isSubscribed calculation
      isSubscribed.value = isActive.value && !isCanceled.value;

      // Show reactivate option if canceled but still active
      showReactivateButton.value = isCanceled.value && isActive.value;

      // Set subscription status message
      if (isActive.value && !isCanceled.value) {
        subscriptionStatus.value = 'active';
      } else if (isActive.value && isCanceled.value) {
        subscriptionStatus.value = 'canceled_but_active';
      } else {
        subscriptionStatus.value = 'inactive';
      }

      print('✅ RevenueCat sync completed');

    } catch (e) {
      print('❌ Error syncing with RevenueCat: $e');
      _resetSubscriptionState();
    }
  }

  /// ============================================
  /// Sync with Backend
  /// ============================================
  Future<void> _syncWithBackend() async {
    try {
      print('🔄 Syncing with backend...');

      final response = await paymentRepo.checkSubscriptionStatus();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        final hasSubscription = data['has_subscription'] ?? false;
        final status = data['status'] ?? 'free';
        final activeEntitlements = List<String>.from(data['active_entitlements'] ?? []);

        print('📋 Backend status:');
        print('   has_subscription: $hasSubscription');
        print('   status: $status');
        print('   active_entitlements: $activeEntitlements');

        if (hasSubscription != isActive.value) {
          print('⚠️ Mismatch: RevenueCat=${isActive.value}, Backend=$hasSubscription');
          print('   Using RevenueCat as source of truth');
        }
      }
    } catch (e) {
      print('⚠️ Backend sync failed (non-critical): $e');
    }
  }

  /// ============================================
  /// Fetch Personas Data
  /// ============================================
  Future<void> fetchIsSubcriptionData() async {
    try {
      print('🔄 Fetching personas data...');

      final response = await authRepo.getAllAiPersona();

      if (response != null && response['data'] != null) {
        final List<dynamic> personasData = response['data'] ?? [];
        print('✅ Personas data fetched');
        print('   personas count: ${personasData.length}');
      }
    } catch (e) {
      print('❌ Error fetching personas data: $e');
    }
  }

  /// ============================================
  /// Reset Subscription State
  /// ============================================
  void _resetSubscriptionState() {
    print('🔄 Resetting subscription state to defaults');
    isSubscribed.value = false;
    isActive.value = false;
    isCanceled.value = false;
    hasPremiumAccess.value = false;
    showReactivateButton.value = false;
    subscriptionStatus.value = 'inactive';
  }

  /// ============================================
  /// 🆕 CHECK PERSONA ACCESS (WITH ADMIN LOGIC)
  /// ============================================
  // Future<bool> isPersonaAccessible(int personaId) async {
  //   print('🔍 Checking access for persona ID: $personaId');
  //
  //   // 👑 PRIORITY 1: Admin has full access to everything
  //   if (isAdminUser.value) {
  //     print('👑 ADMIN ACCESS: Full access granted');
  //     return true;
  //   }
  //
  //   print('   State: isActive=${isActive.value}, isCanceled=${isCanceled.value}');
  //
  //   // CASE 1: Full Access (Active subscription + Not canceled)
  //   if (isActive.value && !isCanceled.value) {
  //     print('🟢 FULL ACCESS: User has active subscription');
  //     return true;
  //   }
  //
  //   // CASE 2 & 3: Limited Access (Free or Canceled)
  //   print('🟡 LIMITED ACCESS: Checking selected persona only');
  //
  //   // Check from local storage first (onboarding selection)
  //   final selectedPersonaId = await TokenStorage.getSelectedPersonaId();
  //   if (selectedPersonaId != null) {
  //     bool hasAccess = selectedPersonaId == personaId;
  //     print('   Selected from storage: $selectedPersonaId');
  //     print('   Access result: $hasAccess');
  //     return hasAccess;
  //   }
  //
  //   // Fallback: Check from API response
  //   final apiSelectedPersonaId = selectedPersona.value?.id;
  //   if (apiSelectedPersonaId != null) {
  //     bool hasAccess = apiSelectedPersonaId == personaId;
  //     print('   Selected from API: $apiSelectedPersonaId');
  //     print('   Access result: $hasAccess');
  //     return hasAccess;
  //   }
  //
  //   print('🔴 NO SELECTED PERSONA: Denying access');
  //   return false;
  // }


  Future<bool> isPersonaAccessible(int personaId) async {
    print('🔍 Checking access for persona ID: $personaId');

    // ✅ PRIORITY 1: Admin full access
    if (isAdminUser.value) {
      print('👑 ADMIN ACCESS: Full access');
      return true;
    }

    // ✅ PRIORITY 2: Check active entitlements (RevenueCat)
    // If active → Full access (even if canceled, until expiry)
    if (isActive.value) {
      print('🟢 PREMIUM ACCESS: Active subscription');

      if (isCanceled.value) {
        print('⚠️ Subscription canceled but still active until expiry');
      }

      return true; // ✅ Full access to all personas
    }

    // ✅ PRIORITY 3: Free tier - Only selected persona
    print('🟡 FREE TIER: Checking selected persona only');

    final selectedPersonaId = await TokenStorage.getSelectedPersonaId();
    if (selectedPersonaId != null) {
      bool hasAccess = selectedPersonaId == personaId;
      print('   Selected: $selectedPersonaId, Requested: $personaId');
      print('   Access: $hasAccess');
      return hasAccess;
    }

    final apiSelectedPersonaId = selectedPersona.value?.id;
    if (apiSelectedPersonaId != null) {
      bool hasAccess = apiSelectedPersonaId == personaId;
      print('   API Selected: $apiSelectedPersonaId');
      print('   Access: $hasAccess');
      return hasAccess;
    }

    print('🔴 NO SELECTED PERSONA: Denying access');
    return false;
  }

  /// Get subscription display message for UI
  String get subscriptionDisplayMessage {
    if (isAdminUser.value) {
      return '👑 Admin Access - Full Access to All Features';
    } else if (isActive.value && !isCanceled.value) {
      return 'Active Subscription - Full Access to All Personas';
    } else if (isActive.value && isCanceled.value) {
      // ✅ IMPORTANT: User still has access until expiry
      final expiryDate = customerInfo.value?.entitlements.active.values.first.expirationDate;
      if (expiryDate != null) {
        return 'Subscription Canceled - Full Access Until ${_formatDate(expiryDate as DateTime)}';
      }
      return 'Subscription Canceled - Full Access Until Expiry';
    } else {
      return 'Free Tier - Access to Selected Persona Only';
    }
  }

  /// Get subscription status for UI
  String get subscriptionStatusForUI {
    if (isAdminUser.value) {
      return 'admin';
    } else if (isActive.value && !isCanceled.value) {
      return 'active';
    } else if (isActive.value && isCanceled.value) {
      return 'canceled_but_active'; // ✅ Still has access
    } else {
      return 'free';
    }
  }

  /// Check if user has premium features
  bool get hasPremiumFeatures {
    return isActive.value || isAdminUser.value;
  }

  /// Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// ============================================
  /// 🆕 GET ACCESSIBLE PERSONAS (WITH ADMIN LOGIC)
  /// ============================================
  Future<List<Personas>> getAccessiblePersonas() async {
    // 👑 Admin gets all personas
    if (isAdminUser.value) {
      print('📋 Returning ALL personas (admin access)');
      return subcriptionData.toList();
    }

    // Full access: All personas
    if (isActive.value && !isCanceled.value) {
      print('📋 Returning ALL personas (full access)');
      return subcriptionData.toList();
    }

    // Limited access: Only selected persona
    print('📋 Returning SELECTED persona only (limited access)');

    final selectedPersonaId = await TokenStorage.getSelectedPersonaId();

    if (selectedPersonaId != null) {
      final selectedPersonaFromList = subcriptionData.firstWhereOrNull(
              (persona) => persona.id == selectedPersonaId
      );

      if (selectedPersonaFromList != null) {
        return [selectedPersonaFromList];
      }
    }

    if (selectedPersona.value != null) {
      return [selectedPersona.value!];
    }

    print('⚠️ No selected persona found, returning empty list');
    return [];
  }

  /// ============================================
  /// Switch Persona
  /// ============================================
  Future<bool> switchPersona(Personas persona) async {
    // 👑 Admin can always switch
    if (isAdminUser.value) {
      print('👑 Admin switching persona: ${persona.title}');
      selectedPersona.value = persona;
      await TokenStorage.saveSelectedPersonaId(persona.id ?? 0);

      Get.snackbar(
        'Success',
        'Switched to ${persona.title}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    }

    // Regular users need permission
    if (!canSwitch.value) {
      print('❌ Cannot switch persona - not allowed');
      Get.snackbar(
        'Not Allowed',
        'Persona switching is not available',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      selectedPersona.value = persona;
      await TokenStorage.saveSelectedPersonaId(persona.id ?? 0);

      print('✅ Switched to persona: ${persona.title} (ID: ${persona.id})');

      Get.snackbar(
        'Success',
        'Switched to ${persona.title}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Error switching persona: $e');
      return false;
    }
  }

  /// ============================================
  /// Restore Purchases
  /// ============================================
  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;
      print('🔄 Restoring purchases...');

      CustomerInfo restoredInfo = await Purchases.restorePurchases();
      customerInfo.value = restoredInfo;

      await checkAndUpdateSubscriptionStatus();

      if (restoredInfo.entitlements.active.isNotEmpty) {
        Get.snackbar(
          'Success',
          'Purchases restored successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'No Purchases',
          'No active purchases found to restore.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
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

  /// Get subscription status icon
  IconData get subscriptionIcon {
    if (isAdminUser.value) {
      return Icons.admin_panel_settings;
    } else if (isActive.value && !isCanceled.value) {
      return Icons.check_circle;
    } else if (isActive.value && isCanceled.value) {
      return Icons.schedule;
    } else {
      return Icons.lock_outline;
    }
  }

  /// Get subscription status color
  Color get subscriptionColor {
    if (isAdminUser.value) {
      return Colors.purple;
    } else if (isActive.value && !isCanceled.value) {
      return Colors.green;
    } else if (isActive.value && isCanceled.value) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  /// Check if can show reactivate option
  bool get canShowReactivate {
    return showReactivateButton.value;
  }

  /// Check if can reactivate subscription
  bool get canReactivateSubscription {
    return showReactivateButton.value;
  }

  /// Check if has premium features
  bool get hasPremium {
    return hasPremiumAccess.value || isAdminUser.value;
  }
}