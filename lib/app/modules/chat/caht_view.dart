import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/repository/auth_repo.dart';
import 'package:hr/app/api_servies/token.dart';
import 'package:hr/app/api_servies/webSocketServices.dart';
import 'package:hr/app/common_widgets/customtooltip.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart';
import 'package:hr/app/modules/chat/widget/ai_guidance_widget.dart';
import 'package:hr/app/modules/chat/widget/chat_drawer.dart';
import 'package:hr/app/modules/chat/widget/chat_header.dart' show ChatHeader;
import 'package:hr/app/modules/chat/widget/chat_input_widget.dart';
import 'package:hr/app/modules/chat/widget/message_list_widget.dart';
import 'package:hr/app/modules/chat/widget/suggestions_widget.dart';
import 'package:hr/app/modules/chat/widget/typing_indicator.dart';

import '../main_screen/main_screen_view.dart';
import 'chat_controller.dart';

class ChatView extends StatelessWidget {
  final String sessionId;
  final String token;
  final WebSocketService webSocketService;
  final String controllerTag;

  ChatView({
    super.key,
    required this.sessionId,
    required this.token,
    required this.webSocketService,
    required this.controllerTag,
  });

  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Add safety check for controller existence
    if (!Get.isRegistered<ChatController>(tag: controllerTag)) {
      print('Initializing new ChatController with tag: $controllerTag');
      Get.put(
        ChatController(
          wsService: webSocketService,
          sessionId: sessionId,
          personaId: webSocketService.personaId ?? 0,
        ),
        tag: controllerTag,
        permanent: true,
      );
    }

    final chatController = Get.find<ChatController>(tag: controllerTag);
    final tooltipCtrl = Get.put(ChatTooltipController());

    // FIXED: Use global VoiceService instance instead of creating new one
    VoiceService voiceService;
    if (Get.isRegistered<VoiceService>()) {
      voiceService = Get.find<VoiceService>();
      print('🎵 Using existing global VoiceService');
    } else {
      voiceService = Get.put(VoiceService(), permanent: true);
      print('🎵 Created new global VoiceService');
    }

    return Obx(() {
      final session = chatController.session.value;

      return Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 20),

            // Chat Header
            ChatHeader(
              session: session,
              onBackPressed: () => Get.off(MainScreen()),
            ),

            // AI Guidance Widget
            AIGuidanceWidget(tooltipCtrl: tooltipCtrl),

            // Loading suggestions indicator
            if (chatController.isLoadingSuggestions.value)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Messages List
            MessageListWidget(
              chatController: chatController,
              session: session,
              voiceService: voiceService,
            ),

            // Typing Indicator
            TypingIndicator(
              chatController: chatController,
              session: session,
            ),

            // Suggestions Widget
            SuggestionsWidget(
              chatController: chatController,
              textController: textController,
            ),

            const Divider(height: 1),

            // Chat Input Widget
            ChatInputWidget(
              chatController: chatController,
              voiceService: voiceService,
              textController: textController,
              sessionId: sessionId,
            ),
          ],
        ),

        // Chat Drawer
        endDrawer: ChatDrawer(
          chatController: chatController,
          sessionId: sessionId,
          controllerTag: controllerTag,
          onCreateNewSession: createNewChatSession,
          onLoadSession: loadSession,
          onDeleteHistory: deleteHistory,
        ),
      );
    });
  }

  Future<void> deleteHistory(int sessionId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final result = await AuthRepository().deleteHistory(sessionId);
      Get.back(); // Close loading dialog

      if (result != null && result['success'] == true) {
        Get.snackbar("Deleted", "Session has been deleted successfully",
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar("Error", "Failed to delete session",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "An error occurred while deleting: $e",
          snackPosition: SnackPosition.BOTTOM);
      print("Delete error: $e");
    }
  }

  Future<void> createNewChatSession() async {
    final chatController = Get.find<ChatController>(tag: controllerTag);
    final currentPersonaId = chatController.personaId;

    try {
      // Close drawer first
      Get.back();

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Create new session
      final newSessionId = await AuthRepository().createSession(currentPersonaId);

      if (newSessionId != null) {
        // Save the new session ID
        await TokenStorage.savePersonaSessionId(currentPersonaId, newSessionId);

        final token = await TokenStorage.getLoginAccessToken() ?? '';

        // Create new WebSocket service and controller tag
        final newWebSocket = WebSocketService();
        final newControllerTag = 'chat-$newSessionId-${DateTime.now().millisecondsSinceEpoch}';

        // Connect WebSocket
        await newWebSocket.connect(newSessionId, token, personaId: currentPersonaId);

        // Create new controller
        final newController = ChatController(
          wsService: newWebSocket,
          sessionId: newSessionId,
          personaId: currentPersonaId,
          isNewSession: true,
        );
        newController.isFirstTime.value = true;

        // Put the new controller in GetX
        Get.put(newController, tag: newControllerTag, permanent: true);

        // Close loading dialog
        Get.back();

        // Navigate to new chat view
        Get.offAll(() => ChatView(
          sessionId: newSessionId,
          token: token,
          webSocketService: newWebSocket,
          controllerTag: newControllerTag,
        ));

        // FIXED: Don't delete VoiceService, just cleanup old ChatController
        Future.delayed(const Duration(seconds: 1), () {
          if (Get.isRegistered<ChatController>(tag: controllerTag)) {
            final oldController = Get.find<ChatController>(tag: controllerTag);
            oldController.onClose();
            Get.delete<ChatController>(tag: controllerTag);
          }
        });
      } else {
        Get.back();
        Get.snackbar("Error", "Failed to create a new chat session.");
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Error creating new session: $e");
      print("Error in createNewChatSession: $e");
    }
  }

  Future<void> loadSession(String newSessionId) async {
    try {
      final chatController = Get.find<ChatController>(tag: controllerTag);
      final currentPersonaId = chatController.personaId;
      final token = await TokenStorage.getLoginAccessToken() ?? '';

      // Close drawer first
      Get.back();

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Save the new session ID
      await TokenStorage.savePersonaSessionId(currentPersonaId, newSessionId);

      // Create new WebSocket service and controller tag
      final newWebSocket = WebSocketService();
      final newControllerTag = 'chat-$newSessionId-${DateTime.now().millisecondsSinceEpoch}';

      // Connect WebSocket
      await newWebSocket.connect(newSessionId, token, personaId: currentPersonaId);

      // Create new controller
      final newController = ChatController(
        wsService: newWebSocket,
        sessionId: newSessionId,
        personaId: currentPersonaId,
        isNewSession: false, // This is an existing session
      );

      // Put the new controller in GetX
      Get.put(newController, tag: newControllerTag, permanent: true);

      // Close loading dialog
      Get.back();

      // Navigate to chat view
      Get.offAll(() => ChatView(
        sessionId: newSessionId,
        token: token,
        webSocketService: newWebSocket,
        controllerTag: newControllerTag,
      ));

      // FIXED: Don't delete VoiceService, just cleanup old ChatController
      Future.delayed(const Duration(seconds: 1), () {
        if (Get.isRegistered<ChatController>(tag: controllerTag)) {
          final oldController = Get.find<ChatController>(tag: controllerTag);
          oldController.onClose();
          Get.delete<ChatController>(tag: controllerTag);
        }
      });
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Error loading session: $e");
      print("Error in loadSession: $e");
    }
  }
}