// lib/app/modules/home/user_isSubcriptionController.dart

import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/api_servies/repository/payment_repository.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
import '../../model/home/is_subcribed_model.dart';

class UserIsSubcribedController extends GetxController {
  final authRepo = AuthRepository();
  final paymentRepo = PaymentRepository();

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
  Future<void> checkAndUpdateSubscriptionStatus() async {
    try {
      isLoading.value = true;
      print('🔄 Checking subscription status...');

      // Step 1: Sync with RevenueCat (source of truth)
      await _syncWithRevenueCat();

      // Step 2: Sync with backend (optional cross-verification)
      await _syncWithBackend();

      // Step 3: Fetch personas based on subscription
      await fetchIsSubcriptionData();

      // ✅ Step 4: Ensure selected persona is loaded
      await _ensureSelectedPersonaLoaded();

      print('✅ Subscription status updated successfully');
      print('📊 Final State:');
      print('   isActive: ${isActive.value}');
      print('   isCanceled: ${isCanceled.value}');
      print('   isSubscribed: ${isSubscribed.value}');
      print('   hasPremiumAccess: ${hasPremiumAccess.value}');

    } catch (e) {
      print('❌ Error in checkAndUpdateSubscriptionStatus: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ NEW: Ensure selected persona is loaded
  Future<void> _ensureSelectedPersonaLoaded() async {
    try {
      final storedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (storedPersonaId != null && selectedPersona.value == null) {
        print('🔍 Loading selected persona from storage: $storedPersonaId');

        // Try to find persona in local data first
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
      // User is subscribed if active AND not canceled
      isSubscribed.value = isActive.value && !isCanceled.value;

      // Show reactivate option if canceled but still active (grace period)
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
  /// Sync with Backend (ONE API)
  /// ============================================
  Future<void> _syncWithBackend() async {
    try {
      print('🔄 Syncing with backend...');

      final response = await paymentRepo.checkSubscriptionStatus();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // Get all info from single API
        final hasSubscription = data['has_subscription'] ?? false;
        final status = data['status'] ?? 'free'; // active, free, canceled
        final activeEntitlements = List<String>.from(data['active_entitlements'] ?? []);

        print('📋 Backend status:');
        print('   has_subscription: $hasSubscription');
        print('   status: $status');
        print('   active_entitlements: $activeEntitlements');

        // Cross-verify with RevenueCat
        if (hasSubscription != isActive.value) {
          print('⚠️ Mismatch: RevenueCat=${isActive.value}, Backend=$hasSubscription');
          print('   Using RevenueCat as source of truth');
        }
      }
    } catch (e) {
      print('⚠️ Backend sync failed (non-critical): $e');
      // Don't fail the flow - RevenueCat is source of truth
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

        // Parse personas (adjust based on your actual API structure)
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
  /// Check Persona Access (Core Logic)
  /// ============================================
  Future<bool> isPersonaAccessible(int personaId) async {
    print('🔍 Checking access for persona ID: $personaId');
    print('   State: isActive=${isActive.value}, isCanceled=${isCanceled.value}');

    // CASE 1: Full Access (Active subscription + Not canceled)
    if (isActive.value && !isCanceled.value) {
      print('🟢 FULL ACCESS: User has active subscription');
      return true;
    }

    // CASE 2 & 3: Limited Access
    print('🟡 LIMITED ACCESS: Checking selected persona only');

    // Check from local storage first (onboarding selection)
    final selectedPersonaId = await TokenStorage.getSelectedPersonaId();
    if (selectedPersonaId != null) {
      bool hasAccess = selectedPersonaId == personaId;
      print('   Selected from storage: $selectedPersonaId');
      print('   Access result: $hasAccess');
      return hasAccess;
    }

    // Fallback: Check from API response
    final apiSelectedPersonaId = selectedPersona.value?.id;
    if (apiSelectedPersonaId != null) {
      bool hasAccess = apiSelectedPersonaId == personaId;
      print('   Selected from API: $apiSelectedPersonaId');
      print('   Access result: $hasAccess');
      return hasAccess;
    }

    print('🔴 NO SELECTED PERSONA: Denying access');
    return false;
  }

  /// ============================================
  /// Get List of Accessible Personas
  /// ============================================
  Future<List<Personas>> getAccessiblePersonas() async {
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

    // Fallback to API selected persona
    if (selectedPersona.value != null) {
      return [selectedPersona.value!];
    }

    print('⚠️ No selected persona found, returning empty list');
    return [];
  }

  /// ============================================
  /// Switch Persona (if allowed)
  /// ============================================
  Future<bool> switchPersona(Personas persona) async {
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

      // Refresh subscription status after restore
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

  /// ============================================
  /// Helper Getters
  /// ============================================

  /// Get subscription display message for UI
  String get subscriptionDisplayMessage {
    if (isActive.value && !isCanceled.value) {
      return 'Active Subscription - Full Access to All Personas';
    } else if (isActive.value && isCanceled.value) {
      return 'Subscription Canceled - Limited Access Until Expiry';
    } else {
      return 'Free Tier - Access to Selected Persona Only';
    }
  }

  /// Get subscription status icon
  IconData get subscriptionIcon {
    if (isActive.value && !isCanceled.value) {
      return Icons.check_circle;
    } else if (isActive.value && isCanceled.value) {
      return Icons.schedule;
    } else {
      return Icons.lock_outline;
    }
  }

  /// Get subscription status color
  Color get subscriptionColor {
    if (isActive.value && !isCanceled.value) {
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

  /// ✅ FIXED: Check if can reactivate subscription (alias for canShowReactivate)
  bool get canReactivateSubscription {
    return showReactivateButton.value;
  }

  /// Check if has premium features
  bool get hasPremium {
    return hasPremiumAccess.value;
  }
}