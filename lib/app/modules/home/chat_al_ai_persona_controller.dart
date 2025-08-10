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

      // ADDED: Check if persona is accessible before starting chat
      final subController = Get.find<UserIsSubcribedController>();
      final isAccessible = await subController.isPersonaAccessible(personaId);

      if (!isAccessible) {
        print('❌ Persona $personaId is not accessible');

        // Show appropriate message based on subscription status
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

      // Step 1: Get existing sessionId if stored
      String? sessionIdNullable = await TokenStorage.getPersonaSessionId(personaId);
      late String sessionId;
      bool isNewSession = false;

      if (sessionIdNullable == null) {
        // This is a new session
        isNewSession = true;
        print('🆕 Creating new session for persona: $personaId');
        sessionId = await authRepo.createSession(personaId) ?? (throw Exception('Failed to create session'));
        await TokenStorage.savePersonaSessionId(personaId, sessionId);
        sessionMap[personaId] = sessionId; // Cache it
      } else {
        // This is an existing session
        sessionId = sessionIdNullable;
        sessionMap[personaId] = sessionId; // Cache it
        print('🔄 Using existing session for persona: $personaId, sessionId: $sessionId');
      }

      final wsService = WebSocketService();
      wsService.connect(sessionId, token, personaId: personaId);

      if (!Get.isRegistered<ChatController>(tag: tag)) {
        Get.put(ChatController(
          wsService: wsService,
          sessionId: sessionId,
          personaId: personaId,
          isNewSession: isNewSession, // Pass the flag here
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

  Future<void> fetchAllAiPersona() async {
    try {
      isLoading.value = true;
      print("🔄 Fetching all AI personas...");

      final response = await authRepo.getAllAiPersona();
      final model = AllAiPersonaChat.fromJson(response);
      personaList.value = model.data ?? [];

      print("✅ Fetched ${personaList.length} personas");
    } catch (e) {
      print("❌ Error fetching personas: $e");
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
    // Also clear from TokenStorage
    await TokenStorage.clearAllPersonaSessions();
    print("🧹 Session cache cleared");
  }

  // Get cached session
  String? getCachedSession(int personaId) {
    return sessionMap[personaId];
  }

  // ADDED: Method to handle subscription cancellation effects
  Future<void> handleSubscriptionCancellation() async {
    try {
      print("🔄 Handling subscription cancellation...");

      // Get the subscription controller
      final subController = Get.find<UserIsSubcribedController>();

      // Get the selected persona ID from onboarding
      final selectedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (selectedPersonaId != null) {
        // Clear sessions for all personas except the selected one
        final List<int> personasToKeep = [selectedPersonaId];

        // Clear sessions for non-accessible personas
        for (int personaId in sessionMap.keys.toList()) {
          if (!personasToKeep.contains(personaId)) {
            sessionMap.remove(personaId);
            await TokenStorage.savePersonaSessionId(personaId, ''); // Clear from storage
            print("🗑️ Cleared session for persona: $personaId");
          }
        }

        print("✅ Kept session only for selected persona: $selectedPersonaId");
      } else {
        // If no selected persona, clear all sessions
        await clearSessionCache();
      }

    } catch (e) {
      print("❌ Error handling subscription cancellation: $e");
    }
  }
}