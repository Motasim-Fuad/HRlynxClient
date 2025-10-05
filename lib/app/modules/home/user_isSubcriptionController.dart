import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
import '../../model/home/is_subcribed_model.dart';

class UserIsSubcribedController extends GetxController {
  final authRepo = AuthRepository();

  // FIXED: Make PaymentController optional to avoid dependency issues
  PaymentController? get paymentController {
    try {
      return Get.find<PaymentController>();
    } catch (e) {
      print('⚠️ PaymentController not found: $e');
      return null;
    }
  }

  // Observables
  final subcriptionData = <Personas>[].obs;
  final isSubscribed = false.obs;
  final canSwitch = false.obs;
  final isLoading = false.obs;
  final selectedPersona = Rxn<Personas>();

  // RevenueCat specific observables
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

    // FIXED: Check if PaymentController exists before setting up listener
    final controller = paymentController;
    if (controller != null) {
      ever(controller.customerInfo, (_) => _syncWithRevenueCat());
    }

    // Initial check
    checkAndUpdateSubscriptionStatus();
  }

  /// MAIN METHOD: Check and update subscription status
  Future<void> checkAndUpdateSubscriptionStatus() async {
    try {
      isLoading.value = true;
      print('🔄 Checking subscription status...');

      // Step 1: Get RevenueCat customer info
      await _syncWithRevenueCat();

      // Step 2: Sync with backend
      await _syncWithBackend();

      // Step 3: Fetch personas based on subscription
      await fetchIsSubcriptionData();

      print('✅ Subscription status updated');
    } catch (e) {
      print('❌ Error in checkAndUpdateSubscriptionStatus: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sync subscription state with RevenueCat
  Future<void> _syncWithRevenueCat() async {
    try {
      print('📱 Syncing with RevenueCat...');

      // FIXED: Try to get customer info from PaymentController first
      if (paymentController != null && paymentController!.customerInfo.value != null) {
        customerInfo.value = paymentController!.customerInfo.value;
      } else {
        // FIXED: If PaymentController not available, fetch directly from RevenueCat
        try {
          CustomerInfo info = await Purchases.getCustomerInfo();
          customerInfo.value = info;
          print('📋 Fetched customer info directly from RevenueCat');
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

      // Update subscription state based on RevenueCat
      isActive.value = hasActiveEntitlement;
      hasPremiumAccess.value = hasActiveEntitlement;

      // Check if subscription is set to cancel at period end
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

      // Calculate final isSubscribed state
      isSubscribed.value = isActive.value && !isCanceled.value;

      // Show reactivate button if canceled but still active
      showReactivateButton.value = isCanceled.value && isActive.value;

      print('✅ RevenueCat sync completed:');
      print('   isActive: ${isActive.value}');
      print('   isCanceled: ${isCanceled.value}');
      print('   isSubscribed: ${isSubscribed.value}');
      print('   hasPremiumAccess: ${hasPremiumAccess.value}');
      print('   showReactivateButton: ${showReactivateButton.value}');

    } catch (e) {
      print('❌ Error syncing with RevenueCat: $e');
      _resetSubscriptionState();
    }
  }

  /// Sync with backend (optional - for your backend to track subscription)
  Future<void> _syncWithBackend() async {
    try {
      print('🔄 Syncing subscription status with backend...');

      final response = await authRepo.checkSubscriptionStatus();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // Backend might have additional info, use it to cross-verify
        final backendIsActive = data['is_active'] ?? false;
        final backendIsCanceled = data['is_canceled'] ?? false;

        print('📋 Backend status:');
        print('   is_active: $backendIsActive');
        print('   is_canceled: $backendIsCanceled');

        // You can choose to use backend data or RevenueCat data as source of truth
        // For now, RevenueCat is the primary source
      }
    } catch (e) {
      print('⚠️ Error syncing with backend (non-critical): $e');
      // Don't fail if backend sync fails, RevenueCat is source of truth
    }
  }

  /// Fetch personas data
  Future<void> fetchIsSubcriptionData() async {
    try {
      print('🔄 Fetching subscription data...');

      final response = await authRepo.fetchUserIsSubcribed();
      final model = UserIsSubcribedModel.fromJson(response);

      if (model.data != null) {
        subcriptionData.assignAll(model.data?.personas ?? []);
        canSwitch.value = model.data?.canSwitch ?? false;
        selectedPersona.value = model.data?.userSelectedPersona;

        print('🔔 Subscription data updated:');
        print('   personas count: ${subcriptionData.length}');
        print('   canSwitch: ${canSwitch.value}');
        print('   selectedPersona: ${selectedPersona.value?.title}');
      }
    } catch (e) {
      print('❌ Error fetching subscription data: $e');
    }
  }

  /// Reset subscription state to default
  void _resetSubscriptionState() {
    isSubscribed.value = false;
    isActive.value = false;
    isCanceled.value = false;
    hasPremiumAccess.value = false;
    showReactivateButton.value = false;
  }

  /// Cancel subscription via RevenueCat
  Future<bool> cancelSubscription() async {
    try {
      print('🔄 Cancelling subscription...');

      // Note: RevenueCat doesn't directly cancel subscriptions
      // Users must cancel through App Store/Play Store
      // But we can update the local state and backend

      // Update local state immediately
      isCanceled.value = true;
      isSubscribed.value = false;
      showReactivateButton.value = true;
      hasPremiumAccess.value = false;

      // Notify backend about cancellation intent
      final response = await authRepo.cancelSubscription();

      if (response != null && response['success'] == true) {
        print('✅ Subscription cancellation recorded in backend');

        // Force refresh from RevenueCat
        Future.delayed(Duration(seconds: 1), () {
          checkAndUpdateSubscriptionStatus();
        });

        return true;
      } else {
        print('⚠️ Backend cancellation failed, but local state updated');
        return true; // Still return true as local update succeeded
      }
    } catch (e) {
      print('❌ Error cancelling subscription: $e');
      return false;
    }
  }

  /// Reactivate subscription via RevenueCat
  Future<bool> reactivateSubscription() async {
    try {
      print('🔄 Reactivating subscription...');

      // For RevenueCat, reactivation might require re-purchasing
      // Or updating the subscription status in the store
      // Check RevenueCat documentation for your specific flow

      // For now, we'll update the backend and refresh from RevenueCat
      final response = await authRepo.reactivateSubscription();

      if (response != null && response['success'] == true) {
        print('✅ Subscription reactivation recorded in backend');

        // Update local state immediately
        isCanceled.value = false;
        isActive.value = true;
        isSubscribed.value = true;
        showReactivateButton.value = false;
        hasPremiumAccess.value = true;

        // Force refresh from RevenueCat to sync
        Future.delayed(Duration(seconds: 1), () {
          checkAndUpdateSubscriptionStatus();
        });

        return true;
      } else {
        print('❌ Backend reactivation failed');
        return false;
      }
    } catch (e) {
      print('❌ Error reactivating subscription: $e');
      return false;
    }
  }

  /// Check if specific persona is accessible
  Future<bool> isPersonaAccessible(int personaId) async {
    print('🔍 Checking accessibility for persona ID: $personaId');
    print('   Current state - isActive: ${isActive.value}, isCanceled: ${isCanceled.value}');

    // Case 1: Full subscription access
    // User has active subscription and hasn't canceled
    if (isActive.value && !isCanceled.value) {
      print('🟢 Full access: All personas accessible');
      return true;
    }

    // Case 2 & 3: Limited access
    // User has canceled or no active subscription
    print('🟡 Limited access: Only selected persona accessible');

    // Get selected persona from onboarding
    final selectedPersonaId = await TokenStorage.getSelectedPersonaId();
    print('   Selected persona ID: $selectedPersonaId');

    if (selectedPersonaId != null) {
      bool hasAccess = selectedPersonaId == personaId;
      print('   Has access: $hasAccess');
      return hasAccess;
    }

    // Fallback to API selected persona
    final apiSelectedPersonaId = selectedPersona.value?.id;
    if (apiSelectedPersonaId != null) {
      bool hasAccess = apiSelectedPersonaId == personaId;
      print('   Has access (API): $hasAccess');
      return hasAccess;
    }

    print('🔴 No selected persona found - denying access');
    return false;
  }

  /// Get accessible personas
  Future<List<Personas>> getAccessiblePersonas() async {
    if (isActive.value && !isCanceled.value) {
      print('📋 Returning all personas (full access)');
      return subcriptionData.toList();
    } else {
      print('📋 Returning only selected persona (limited access)');

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

      return [];
    }
  }

  /// Switch persona (if allowed)
  Future<void> switchPersona(Personas persona) async {
    if (canSwitch.isTrue) {
      selectedPersona.value = persona;
      await TokenStorage.saveSelectedPersonaId(persona.id ?? 0);
      print('✅ Switched to persona: ${persona.title} (ID: ${persona.id})');
    } else {
      print('❌ Cannot switch persona - switching not allowed');
    }
  }

  /// Get subscription display message
  String get subscriptionDisplayMessage {
    if (isActive.value && !isCanceled.value) {
      return 'Active subscription - Full access';
    } else if (isActive.value && isCanceled.value) {
      return 'Subscription canceled - Limited access until expiry';
    } else {
      return 'Free tier - Limited access';
    }
  }

  /// Check if can cancel
  bool get canCancelSubscription {
    return isActive.value && !isCanceled.value;
  }

  /// Check if can reactivate
  bool get canReactivateSubscription {
    return showReactivateButton.value;
  }

  /// Restore purchases (wrapper for direct RevenueCat method)
  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;
      print('🔄 Restoring purchases...');

      // FIXED: Call RevenueCat directly instead of through PaymentController
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
}