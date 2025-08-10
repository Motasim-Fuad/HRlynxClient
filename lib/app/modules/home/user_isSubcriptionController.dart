import 'package:get/get.dart';
import 'package:hr/app/api_servies/repository/auth_repo.dart';
import 'package:hr/app/api_servies/token.dart';
import '../../model/home/is_subcribed_model.dart';

class UserIsSubcribedController extends GetxController {
  final authRepo = AuthRepository();

  // Observables
  final subcriptionData = <Personas>[].obs;
  final isSubscribed = false.obs;
  final canSwitch = false.obs;
  final isLoading = false.obs;
  final selectedPersona = Rxn<Personas>();

  // New observables for subscription status tracking
  final isCanceled = false.obs;
  final hasPremiumAccess = false.obs;
  final subscriptionStatus = ''.obs;
  final isActive = false.obs;
  final showReactivateButton = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Check subscription status on initialization
    checkAndUpdateSubscriptionStatus();
  }

  // Combined method to check subscription status and update UI accordingly
  Future<void> checkAndUpdateSubscriptionStatus() async {
    try {
      isLoading.value = true;

      // First check the subscription status
      await checkSubscriptionStatus();

      // Then fetch the available personas based on subscription status
      await fetchIsSubcriptionData();

    } catch (e) {
      print("❌ Error in checkAndUpdateSubscriptionStatus: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Check subscription status from the API
  Future<void> checkSubscriptionStatus() async {
    try {
      print("🔄 Checking subscription status...");

      final response = await authRepo.checkSubscriptionStatus();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // Update subscription status observables
        isActive.value = data['is_active'] ?? false;
        isCanceled.value = data['is_canceled'] ?? false;
        hasPremiumAccess.value = data['has_premium_access'] ?? false;
        subscriptionStatus.value = data['subscription_state'] ?? '';
        showReactivateButton.value = data['show_reactivate_button'] ?? false;

        // FIXED: Update isSubscribed based on the correct logic:
        // isSubscribed = true when user has full access to all personas
        // This happens when subscription is active AND not canceled
        isSubscribed.value = isActive.value && !isCanceled.value;

        print("📊 Subscription Status Update:");
        print("   is_active: ${isActive.value}");
        print("   is_canceled: ${isCanceled.value}");
        print("   has_premium_access: ${hasPremiumAccess.value}");
        print("   subscription_state: ${subscriptionStatus.value}");
        print("   show_reactivate_button: ${showReactivateButton.value}");
        print("   isSubscribed (calculated): ${isSubscribed.value}");

      } else {
        print("❌ Failed to get subscription status");
        // If API fails, assume not subscribed
        _resetSubscriptionState();
      }

    } catch (e) {
      print("❌ Error checking subscription status: $e");
      // On error, assume not subscribed
      _resetSubscriptionState();
    }
  }

  // Reset subscription state to default values
  void _resetSubscriptionState() {
    isSubscribed.value = false;
    isActive.value = false;
    isCanceled.value = false;
    hasPremiumAccess.value = false;
    showReactivateButton.value = false;
  }

  // Fetch subscription data from the personas endpoint
  Future<void> fetchIsSubcriptionData() async {
    try {
      print("🔄 Fetching subscription data...");

      final response = await authRepo.fetchUserIsSubcribed();
      final model = UserIsSubcribedModel.fromJson(response);

      if (model.data != null) {
        subcriptionData.assignAll(model.data?.personas ?? []);
        canSwitch.value = model.data?.canSwitch ?? false;
        selectedPersona.value = model.data?.userSelectedPersona;

        print("🔔 Subscription data updated:");
        print("   personas count: ${subcriptionData.length}");
        print("   canSwitch: ${canSwitch.value}");
        print("   selectedPersona: ${selectedPersona.value?.title}");
      }
    } catch (e) {
      print("❌ Error fetching subscription data: $e");
    }
  }

  // IMPROVED: Cancel subscription method with immediate UI update
  Future<void> cancelSubscription() async {
    try {
      print("🔄 Cancelling subscription...");

      final response = await authRepo.cancelSubscription();

      if (response != null && response['success'] == true) {
        print("✅ Subscription cancelled successfully");

        // FIXED: Update local state immediately after successful cancellation
        // This ensures UI updates instantly without waiting for API refresh
        isCanceled.value = true;
        isSubscribed.value = false; // User now has limited access
        showReactivateButton.value = true;
        hasPremiumAccess.value = false; // No premium access after cancellation

        // Keep isActive as true since subscription might still be in grace period
        // The API will provide the correct value in the next refresh

        print("🔄 Immediate UI state updated after cancellation:");
        print("   isSubscribed: ${isSubscribed.value}");
        print("   isCanceled: ${isCanceled.value}");
        print("   showReactivateButton: ${showReactivateButton.value}");

        // Force UI update
        update();

        // Re-check subscription status to sync with server (but don't wait for it)
        // This happens in background and will update any remaining fields
        Future.delayed(Duration(milliseconds: 500), () {
          checkAndUpdateSubscriptionStatus();
        });

      } else {
        throw Exception('API returned unsuccessful response');
      }
    } catch (e) {
      print("❌ Error cancelling subscription: $e");
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // IMPROVED: Reactivate subscription method with immediate UI update
  Future<bool> reactivateSubscription() async {
    try {
      print("🔄 Reactivating subscription...");

      final response = await authRepo.reactivateSubscription();

      if (response != null && response['success'] == true) {
        print("✅ Subscription reactivated successfully");

        // FIXED: Update local state immediately after successful reactivation
        // This ensures UI updates instantly without waiting for API refresh
        isCanceled.value = false;
        isActive.value = true;
        isSubscribed.value = true; // User now has full access
        showReactivateButton.value = false;
        hasPremiumAccess.value = true;

        print("🔄 Immediate UI state updated after reactivation:");
        print("   isSubscribed: ${isSubscribed.value}");
        print("   isCanceled: ${isCanceled.value}");
        print("   isActive: ${isActive.value}");
        print("   hasPremiumAccess: ${hasPremiumAccess.value}");
        print("   showReactivateButton: ${showReactivateButton.value}");

        // Force UI update
        update();

        // Re-check subscription status to sync with server (but don't wait for it)
        // This happens in background to ensure all data is perfectly synced
        Future.delayed(Duration(milliseconds: 500), () {
          checkAndUpdateSubscriptionStatus();
        });

        return true;
      } else {
        print("❌ Failed to reactivate subscription - API response unsuccessful");
        return false;
      }
    } catch (e) {
      print("❌ Error reactivating subscription: $e");
      return false; // Return false instead of rethrow for better error handling
    }
  }

  // Check if user can cancel subscription
  bool get canCancelSubscription {
    // User can cancel if subscription is active and not already canceled
    return isActive.value && !isCanceled.value;
  }

  // Check if user can reactivate subscription
  bool get canReactivateSubscription {
    return showReactivateButton.value;
  }

  // FIXED: Check if a specific persona is accessible - THIS IS THE KEY METHOD
  Future<bool> isPersonaAccessible(int personaId) async {
    print("🔍 Checking accessibility for persona ID: $personaId");
    print("   Current state - isActive: ${isActive.value}, isCanceled: ${isCanceled.value}");

    // Case 1: Full subscription access (is_active = true AND is_canceled = false)
    // User has full subscription access - all personas available
    if (isActive.value && !isCanceled.value) {
      print("🟢 Full access: is_active=true, is_canceled=false - All personas accessible");
      return true;
    }

    // Case 2 & 3: Limited access (is_canceled = true OR is_active = false)
    // User has canceled subscription or no subscription - only selected persona accessible
    print("🟡 Limited access: Only selected persona accessible");

    // First, try to get the selected persona ID from TokenStorage (onboarding selection)
    final selectedPersonaId = await TokenStorage.getSelectedPersonaId();
    print("   TokenStorage selected persona ID: $selectedPersonaId");

    if (selectedPersonaId != null) {
      bool hasAccess = selectedPersonaId == personaId;
      print("   Using TokenStorage: personaId=$personaId, selectedId=$selectedPersonaId, hasAccess=$hasAccess");
      return hasAccess;
    }

    // Fallback to API selected persona if no onboarding selection found
    final apiSelectedPersonaId = selectedPersona.value?.id;
    print("   API selected persona ID: $apiSelectedPersonaId");

    if (apiSelectedPersonaId != null) {
      bool hasAccess = apiSelectedPersonaId == personaId;
      print("   Using API selection: personaId=$personaId, selectedId=$apiSelectedPersonaId, hasAccess=$hasAccess");
      return hasAccess;
    }

    // If no selection found anywhere, deny access
    print("🔴 No selected persona found - denying access");
    return false;
  }

  // Get accessible personas based on subscription status
  Future<List<Personas>> getAccessiblePersonas() async {
    // If user has full subscription access
    if (isActive.value && !isCanceled.value) {
      print("📋 Returning all personas (full access)");
      return subcriptionData.toList();
    }
    // If user has limited access (canceled subscription or no subscription)
    else {
      print("📋 Returning only selected persona (limited access)");

      // Get the selected persona ID from TokenStorage (onboarding selection)
      final selectedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (selectedPersonaId != null) {
        // Find the persona by ID from the list
        final selectedPersonaFromList = subcriptionData.firstWhereOrNull(
                (persona) => persona.id == selectedPersonaId
        );

        if (selectedPersonaFromList != null) {
          print("   Found selected persona in list: ${selectedPersonaFromList.title}");
          return [selectedPersonaFromList];
        }
      }

      // Fallback to API selected persona
      if (selectedPersona.value != null) {
        print("   Using API selected persona: ${selectedPersona.value!.title}");
        return [selectedPersona.value!];
      }

      print("   No accessible personas found");
      return [];
    }
  }

  // Switch selected persona (if allowed)
  Future<void> switchPersona(Personas persona) async {
    if (canSwitch.isTrue) {
      selectedPersona.value = persona;
      // Save to TokenStorage as well
      await TokenStorage.saveSelectedPersonaId(persona.id ?? 0);
      print("✅ Switched to persona: ${persona.title} (ID: ${persona.id})");
      // Optional: API call to update selection can be placed here.
    } else {
      print("❌ Cannot switch persona - switching not allowed");
    }
  }

  // Get subscription display message
  String get subscriptionDisplayMessage {
    if (isActive.value && !isCanceled.value) {
      return "Active subscription - Full access";
    } else if (isActive.value && isCanceled.value) {
      return "Trial canceled - Limited access until expiry";
    } else {
      return "Free tier - Limited access";
    }
  }

  // Get subscription action message
  String get subscriptionActionMessage {
    if (canReactivateSubscription) {
      return "Reactivate subscription for full access";
    } else if (!isActive.value) {
      return "Subscribe for full access to all personas";
    }
    return "";
  }
}