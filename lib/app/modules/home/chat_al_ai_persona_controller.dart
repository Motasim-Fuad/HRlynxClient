import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api_servies/token.dart';
import '../../api_servies/webSocketServices.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../model/home/chat_al_ai_persona.dart';
import '../chat/caht_view.dart';
import '../chat/chat_controller.dart';
import '../home/user_isSubcriptionController.dart';

class ChatAllAiPersona extends GetxController {
  var personaList = <Data>[].obs;
  final isLoading = true.obs;

  // ✅ NEW: Error handling
  final hasError = false.obs;
  final errorMessage = ''.obs;

  final authRepo = AuthRepository();

  /// Cache: personaId -> sessionId
  final Map<int, String> sessionMap = {};

  @override
  void onInit() {
    fetchAllAiPersona();
    super.onInit();
  }

  Future<void> startChatSession(Data persona) async {
    try {
      final personaId = persona.id!;
      final tag = 'chat_$personaId';
      print('👉 Starting chat for persona: $personaId');

      // Check if persona is accessible before starting chat
      final subController = Get.find<UserIsSubcribedController>();
     // await subController.checkAndUpdateSubscriptionStatus(); // ← এটা add করো
      // ✅ শুধু access check করুন, full reload নয়
      final isAccessible = await subController.isPersonaAccessible(personaId);

      if (!isAccessible) {
        print('❌ Persona $personaId is not accessible');

        String title = 'Access Restricted';
        String message = 'This persona is not available with your current subscription';

        if (subController.canReactivateSubscription) {
          title = 'Reactivate Required';
          message = 'Reactivate your subscription to access this persona';
        } else if (!subController.isActive.value) {
          title = 'Subscription Required';
          message = 'Subscribe to access this persona';
        }

        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        return;
      }

      final token = await TokenStorage.getLoginAccessToken();
      if (token == null) throw Exception('Token is null');

      // Get existing sessionId if stored
      String? sessionIdNullable = await TokenStorage.getPersonaSessionId(personaId);
      late String sessionId;
      bool isNewSession = false;

      if (sessionIdNullable == null) {
        isNewSession = true;
        print('🆕 Creating new session for persona: $personaId');
        sessionId = await authRepo.createSession(personaId) ?? (throw Exception('Failed to create session'));
        await TokenStorage.savePersonaSessionId(personaId, sessionId);
        sessionMap[personaId] = sessionId;
      } else {
        sessionId = sessionIdNullable;
        sessionMap[personaId] = sessionId;
        print('🔄 Using existing session for persona: $personaId, sessionId: $sessionId');
      }

      final wsService = WebSocketService();
      wsService.connect(sessionId, token, personaId: personaId);

      if (!Get.isRegistered<ChatController>(tag: tag)) {
        Get.put(ChatController(
          wsService: wsService,
          sessionId: sessionId,
          personaId: personaId,
          isNewSession: isNewSession,
        ), tag: tag);
      }

      Get.to(() => ChatView(
        sessionId: sessionId,
        token: token,
        webSocketService: wsService,
        controllerTag: tag,
      ));

    } catch (e) {
      print('❌ Error in startChatSession: $e');
      Get.snackbar("Error", "Could not start chat session: ${e.toString()}");
    }
  }

  /// ✅ UPDATED: Better error handling
  Future<void> fetchAllAiPersona() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      print("🔄 Fetching all AI personas...");

      final response = await authRepo.getAllAiPersona();
      final model = AllAiPersonaChat.fromJson(response);
      personaList.value = model.data ?? [];

      print("✅ Fetched ${personaList.length} personas");

    } catch (e) {
      hasError.value = true;
      String error = e.toString();

      print("❌ Error fetching personas: $error");

      // ✅ Categorize errors
      if (error.contains('NETWORK_ERROR')) {
        errorMessage.value = 'NETWORK_ERROR';
      } else if (error.contains('SERVER_ERROR')) {
        errorMessage.value = 'SERVER_ERROR';
      } else if (error.contains('Session expired')) {
        errorMessage.value = 'SESSION_EXPIRED';
        // Don't set personaList to empty on session expired
        // User will be redirected to login automatically
      } else {
        errorMessage.value = 'UNKNOWN_ERROR';
      }

      personaList.value = [];

    } finally {
      isLoading.value = false;
    }
  }

  // Refresh data after subscription changes
  Future<void> refreshAfterSubscriptionChange() async {
    try {
      print("🔄 Refreshing data after subscription change...");

      // Refresh subscription status
      try {
        final subController = Get.find<UserIsSubcribedController>();
        await subController.checkAndUpdateSubscriptionStatus();
      } catch (e) {
        print("⚠️ UserIsSubcribedController not found: $e");
      }

      // Refresh persona list
      await fetchAllAiPersona();

      print("✅ Data refreshed successfully");
    } catch (e) {
      print("❌ Error refreshing data: $e");
    }
  }

  // Clear session cache when subscription is canceled or user logs out
  Future<void> clearSessionCache() async {
    sessionMap.clear();
    await TokenStorage.clearAllPersonaSessions();
    print("🧹 Session cache cleared");
  }

  // Get cached session
  String? getCachedSession(int personaId) {
    return sessionMap[personaId];
  }

  // Handle subscription cancellation effects
  Future<void> handleSubscriptionCancellation() async {
    try {
      print("🔄 Handling subscription cancellation...");

      final subController = Get.find<UserIsSubcribedController>();
      final selectedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (selectedPersonaId != null) {
        final List<int> personasToKeep = [selectedPersonaId];

        for (int personaId in sessionMap.keys.toList()) {
          if (!personasToKeep.contains(personaId)) {
            sessionMap.remove(personaId);
            await TokenStorage.savePersonaSessionId(personaId, '');
            print("🗑️ Cleared session for persona: $personaId");
          }
        }

        print("✅ Kept session only for selected persona: $selectedPersonaId");
      } else {
        await clearSessionCache();
      }

    } catch (e) {
      print("❌ Error handling subscription cancellation: $e");
    }
  }
}
