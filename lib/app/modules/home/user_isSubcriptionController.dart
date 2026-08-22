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

  static final String ADMIN_EMAIL = dotenv.env['ADMIN_ACCESS_EMAIL'] ?? '';
  static final String CLIENT_EMAIL = dotenv.env['CLINT_ACCESS_EMAIL'] ?? '';

  int? _cachedSelectedPersonaId;

  final subcriptionData = <Personas>[].obs;
  final isSubscribed = false.obs;
  final canSwitch = false.obs;
  final isLoading = false.obs;
  final selectedPersona = Rxn<Personas>();

  final isCanceled = false.obs;
  final hasPremiumAccess = false.obs;
  final subscriptionStatus = ''.obs;
  final isActive = false.obs;
  final showReactivateButton = false.obs;

  final customerInfo = Rxn<CustomerInfo>();

  final isAdminUser = false.obs;

  PaymentController? get paymentController {
    try {
      return Get.put(PaymentController());
    } catch (e) {
      print('PaymentController not found: $e');
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();

    final controller = paymentController;
    if (controller != null) {
      ever(controller.customerInfo, (_) {
        print('PaymentController customerInfo changed, syncing...');
        _syncWithRevenueCat();
      });
    }

    checkAndUpdateSubscriptionStatus();
  }

  Future<void> checkAndUpdateSubscriptionStatus() async {
    try {
      isLoading.value = true;
      print('Checking subscription (RevenueCat only)...');

      await _checkAdminStatus();
      if (isAdminUser.value) {
        _grantAdminAccess();
        await fetchIsSubcriptionData();
        await _ensureSelectedPersonaLoaded();
        return;
      }

      await _syncWithRevenueCatOnly();

      await fetchIsSubcriptionData();

      await _loadSelectedPersonaWithCache();

      print('Status updated (RevenueCat only)');
      print('isActive: ${isActive.value}');
      print('isCanceled: ${isCanceled.value}');
      print('hasPremium: ${hasPremiumAccess.value}');
      print('cachedSelectedPersonaId: $_cachedSelectedPersonaId');

    } catch (e) {
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSelectedPersonaWithCache() async {
    try {
      if (!isActive.value) {
        print('Fetching selected persona from API (free tier)...');

        final response = await authRepo.getSelectedPersonaOnApi();
        _cachedSelectedPersonaId = response['data']['persona_id'];

        print('Cached selected persona ID: $_cachedSelectedPersonaId');
      } else {
        print('Active subscription - no need to fetch selected persona');
        _cachedSelectedPersonaId = null;
      }

      await _ensureSelectedPersonaLoaded();

    } catch (e) {
      print('Error loading selected persona: $e');
      _cachedSelectedPersonaId = null;
    }
  }

  Future<void> _syncWithRevenueCatOnly() async {
    try {
      print('Syncing with RevenueCat...');

      if (paymentController != null && paymentController!.customerInfo.value != null) {
        customerInfo.value = paymentController!.customerInfo.value;
        print('Got info from PaymentController');
      } else {
        try {
          CustomerInfo info = await Purchases.getCustomerInfo();
          customerInfo.value = info;
          print('Fetched from RevenueCat');
        } catch (e) {
          print('RevenueCat fetch failed: $e');
          _resetSubscriptionState();
          return;
        }
      }

      if (customerInfo.value == null) {
        _resetSubscriptionState();
        return;
      }

      final activeEntitlements = customerInfo.value!.entitlements.active;
      final hasActive = activeEntitlements.isNotEmpty;

      isActive.value = hasActive;
      hasPremiumAccess.value = hasActive;

      final allEntitlements = customerInfo.value!.entitlements.all;
      if (allEntitlements.isNotEmpty) {
        final firstEntitlement = allEntitlements.values.first;
        isCanceled.value = firstEntitlement.willRenew == false;
      } else {
        isCanceled.value = false;
      }

      isSubscribed.value = isActive.value && !isCanceled.value;
      showReactivateButton.value = isCanceled.value && isActive.value;

      if (isActive.value && !isCanceled.value) {
        subscriptionStatus.value = 'active';
      } else if (isActive.value && isCanceled.value) {
        subscriptionStatus.value = 'canceled_but_active';
      } else {
        subscriptionStatus.value = 'inactive';
      }

      print('RevenueCat sync complete');

    } catch (e) {
      print('Sync error: $e');
      _resetSubscriptionState();
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userEmail = await TokenStorage.getUserEmail();

      if (userEmail != null) {
        final emailLower = userEmail.toLowerCase();

        if (emailLower == ADMIN_EMAIL.toLowerCase() ||
            emailLower == CLIENT_EMAIL.toLowerCase()) {
          isAdminUser.value = true;
          print('Privileged user identified: $userEmail');
        } else {
          isAdminUser.value = false;
          print('Regular user: $userEmail');
        }
      } else {
        isAdminUser.value = false;
        print('Regular user: unknown');
      }
    } catch (e) {
      print('Error checking admin status: $e');
      isAdminUser.value = false;
    }
  }

  void _grantAdminAccess() {
    isActive.value = true;
    isSubscribed.value = true;
    hasPremiumAccess.value = true;
    isCanceled.value = false;
    showReactivateButton.value = false;
    subscriptionStatus.value = 'admin_access';
    canSwitch.value = true;

    print('Admin privileges granted');
  }

  Future<void> _ensureSelectedPersonaLoaded() async {
    try {
      final storedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (storedPersonaId != null && selectedPersona.value == null) {
        print('Loading selected persona from storage: $storedPersonaId');

        final persona = subcriptionData.firstWhereOrNull(
                (p) => p.id == storedPersonaId
        );

        if (persona != null) {
          selectedPersona.value = persona;
          print('Restored selected persona: ${persona.title}');
        } else {
          print('Persona $storedPersonaId not found in local data');
        }
      }
    } catch (e) {
      print('Error ensuring selected persona loaded: $e');
    }
  }

  Future<void> _syncWithRevenueCat() async {
    try {
      print('Syncing with RevenueCat...');

      if (paymentController != null && paymentController!.customerInfo.value != null) {
        customerInfo.value = paymentController!.customerInfo.value;
        print('Got customer info from PaymentController');
      } else {
        try {
          CustomerInfo info = await Purchases.getCustomerInfo();
          customerInfo.value = info;
          print('Fetched customer info directly from RevenueCat');
        } catch (e) {
          print('Failed to fetch customer info from RevenueCat: $e');
          _resetSubscriptionState();
          return;
        }
      }

      if (customerInfo.value == null) {
        print('No RevenueCat customer info available');
        _resetSubscriptionState();
        return;
      }

      final activeEntitlements = customerInfo.value!.entitlements.active;
      final hasActiveEntitlement = activeEntitlements.isNotEmpty;

      print('Active entitlements: ${activeEntitlements.keys.toList()}');

      isActive.value = hasActiveEntitlement;
      hasPremiumAccess.value = hasActiveEntitlement;

      final allEntitlements = customerInfo.value!.entitlements.all;
      if (allEntitlements.isNotEmpty) {
        final firstEntitlement = allEntitlements.values.first;
        isCanceled.value = firstEntitlement.willRenew == false;

        print('Entitlement details:');
        print('willRenew: ${firstEntitlement.willRenew}');
        print('isActive: ${firstEntitlement.isActive}');
        print('expirationDate: ${firstEntitlement.expirationDate}');
      } else {
        isCanceled.value = false;
      }

      isSubscribed.value = isActive.value && !isCanceled.value;
      showReactivateButton.value = isCanceled.value && isActive.value;

      if (isActive.value && !isCanceled.value) {
        subscriptionStatus.value = 'active';
      } else if (isActive.value && isCanceled.value) {
        subscriptionStatus.value = 'canceled_but_active';
      } else {
        subscriptionStatus.value = 'inactive';
      }

      print('RevenueCat sync completed');

    } catch (e) {
      print('Error syncing with RevenueCat: $e');
      _resetSubscriptionState();
    }
  }

  Future<void> fetchIsSubcriptionData() async {
    try {
      print('Fetching personas data...');

      final response = await authRepo.getAllAiPersona();

      if (response != null && response['data'] != null) {
        final List<dynamic> personasData = response['data'] ?? [];
        print('Personas data fetched');
        print('personas count: ${personasData.length}');
      }
    } catch (e) {
      print('Error fetching personas data: $e');
    }
  }

  void _resetSubscriptionState() {
    print('Resetting subscription state to defaults');
    isSubscribed.value = false;
    isActive.value = false;
    isCanceled.value = false;
    hasPremiumAccess.value = false;
    showReactivateButton.value = false;
    subscriptionStatus.value = 'inactive';
    _cachedSelectedPersonaId = null;
  }

  Future<bool> isPersonaAccessible(int personaId) async {
    print('Checking access for persona ID: $personaId');

    if (isAdminUser.value) {
      print('ADMIN ACCESS: Full access');
      return true;
    }

    if (isActive.value) {
      print('PREMIUM ACCESS: Active subscription');
      if (isCanceled.value) {
        print('Subscription canceled but still active until expiry');
      }
      return true;
    }

    print('FREE TIER: Checking selected persona (from cache)');

    if (_cachedSelectedPersonaId != null) {
      bool hasAccess = _cachedSelectedPersonaId == personaId;
      print('Cached Selected: $_cachedSelectedPersonaId, Requested: $personaId');
      print('Access: $hasAccess');
      return hasAccess;
    }

    final storedPersonaId = await TokenStorage.getSelectedPersonaId();
    if (storedPersonaId != null) {
      bool hasAccess = storedPersonaId == personaId;
      print('Storage Selected: $storedPersonaId');
      print('Access: $hasAccess');
      return hasAccess;
    }

    final apiSelectedPersonaId = selectedPersona.value?.id;
    if (apiSelectedPersonaId != null) {
      bool hasAccess = apiSelectedPersonaId == personaId;
      print('API Selected: $apiSelectedPersonaId');
      print('Access: $hasAccess');
      return hasAccess;
    }

    print('NO SELECTED PERSONA: Denying access');
    return false;
  }

  String get subscriptionDisplayMessage {
    if (isAdminUser.value) {
      return '👑 Admin Access - Full Access to All Features';
    } else if (isActive.value && !isCanceled.value) {
      return 'Active Subscription - Full Access to All Personas';
    } else if (isActive.value && isCanceled.value) {
      final expiryDate = customerInfo.value?.entitlements.active.values.first.expirationDate;
      if (expiryDate != null) {
        return 'Subscription Canceled - Full Access Until ${_formatDate(expiryDate as DateTime)}';
      }
      return 'Subscription Canceled - Full Access Until Expiry';
    } else {
      return 'Free Tier - Access to Selected Persona Only';
    }
  }

  String get subscriptionStatusForUI {
    if (isAdminUser.value) {
      return 'admin';
    } else if (isActive.value && !isCanceled.value) {
      return 'active';
    } else if (isActive.value && isCanceled.value) {
      return 'canceled_but_active';
    } else {
      return 'free';
    }
  }

  bool get hasPremiumFeatures {
    return isActive.value || isAdminUser.value;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<List<Personas>> getAccessiblePersonas() async {
    if (isAdminUser.value) {
      print('Returning ALL personas (admin access)');
      return subcriptionData.toList();
    }

    if (isActive.value && !isCanceled.value) {
      print('Returning ALL personas (full access)');
      return subcriptionData.toList();
    }

    print('Returning SELECTED persona only (limited access)');

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

    print('No selected persona found, returning empty list');
    return [];
  }

  Future<bool> switchPersona(Personas persona) async {
    if (isAdminUser.value) {
      print('Admin switching persona: ${persona.title}');
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

    if (!canSwitch.value) {
      print('Cannot switch persona - not allowed');
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

      print('Switched to persona: ${persona.title} (ID: ${persona.id})');

      Get.snackbar(
        'Success',
        'Switched to ${persona.title}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('Error switching persona: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      isLoading.value = true;
      print('Restoring purchases...');

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
      print('Error restoring purchases: $e');
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

  bool get canShowReactivate {
    return showReactivateButton.value;
  }

  bool get canReactivateSubscription {
    return showReactivateButton.value;
  }

  bool get hasPremium {
    return hasPremiumAccess.value || isAdminUser.value;
  }
}
