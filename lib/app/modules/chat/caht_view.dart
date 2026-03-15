import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/api_servies/webSocketServices.dart';
import 'package:HRlynx/app/common_widgets/customtooltip.dart';
import 'package:HRlynx/app/modules/chat/voice_service_controller.dart';
import 'package:HRlynx/app/modules/chat/widget/ai_consent_dialog.dart';
import 'package:HRlynx/app/modules/chat/widget/ai_guidance_widget.dart';
import 'package:HRlynx/app/modules/chat/widget/chat_drawer.dart';
import 'package:HRlynx/app/modules/chat/widget/chat_header.dart';
import 'package:HRlynx/app/modules/chat/widget/chat_input_widget.dart';
import 'package:HRlynx/app/modules/chat/widget/message_list_widget.dart';
import 'package:HRlynx/app/modules/chat/widget/suggestions_widget.dart';
import 'package:HRlynx/app/modules/chat/widget/typing_indicator.dart';
import 'package:HRlynx/app/modules/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main_screen/main_screen_view.dart';
import 'chat_controller.dart';

class ChatView extends StatelessWidget {
  final String sessionId;
  final String token;
  final WebSocketService webSocketService;
  final String controllerTag;

  const ChatView({
    super.key,
    required this.sessionId,
    required this.token,
    required this.webSocketService,
    required this.controllerTag,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ChatController>(tag: controllerTag)) {
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

    final chatController    = Get.find<ChatController>(tag: controllerTag);
    final tooltipCtrl       = Get.put(ChatTooltipController());
    final profileController = Get.put(ProfileController());

    final consentController = Get.isRegistered<ConsentController>()
        ? Get.find<ConsentController>()
        : Get.put(ConsentController(), permanent: true);

    VoiceService voiceService;
    if (Get.isRegistered<VoiceService>()) {
      voiceService = Get.find<VoiceService>();
      print('🎵 Using existing global VoiceService');
    } else {
      voiceService = Get.put(VoiceService(), permanent: true);
      print('🎵 Created new global VoiceService');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AiConsentDialog.showIfNeeded(context);
    });

    return Obx(() {
      final session = chatController.session.value;

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              ChatHeader(
                session: session,
                onBackPressed: () => Get.off(MainScreen()),
              ),

              AIGuidanceWidget(tooltipCtrl: tooltipCtrl),

              if (chatController.isLoadingSuggestions.value)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              MessageListWidget(
                chatController: chatController,
                session: session,
                voiceService: voiceService,
                profileController: profileController,
              ),

              TypingIndicator(
                chatController: chatController,
                session: session,
              ),

              SuggestionsWidget(
                chatController: chatController,
              ),

              ChatInputWidget(
                chatController: chatController,
                voiceService: voiceService,
                sessionId: sessionId,
              ),
            ],
          ),
        ),
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
      Get.dialog(const Center(child: CircularProgressIndicator()),
          barrierDismissible: false);
      final result = await AuthRepository().deleteHistory(sessionId);
      Get.back();
      Get.snackbar(
        result != null && result['success'] == true ? "Deleted" : "Error",
        result != null && result['success'] == true
            ? "Session has been deleted successfully"
            : "Failed to delete session",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "An error occurred: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> createNewChatSession() async {
    final chatController   = Get.find<ChatController>(tag: controllerTag);
    final currentPersonaId = chatController.personaId;

    try {
      Get.back();
      Get.dialog(const Center(child: CircularProgressIndicator()),
          barrierDismissible: false);

      final newSessionId = await AuthRepository().createSession(currentPersonaId);

      if (newSessionId != null) {
        await TokenStorage.savePersonaSessionId(currentPersonaId, newSessionId);
        final tkn          = await TokenStorage.getLoginAccessToken() ?? '';
        final newWebSocket = WebSocketService();
        final newTag = 'chat-$newSessionId-${DateTime.now().millisecondsSinceEpoch}';

        // ✅ নতুন session — limit reset করো connect এর আগে
        newWebSocket.resetForNewSession();
        await newWebSocket.connect(newSessionId, tkn, personaId: currentPersonaId);

        final newController = ChatController(
          wsService: newWebSocket,
          sessionId: newSessionId,
          personaId: currentPersonaId,
          isNewSession: true,
        );
        newController.isFirstTime.value = true;
        Get.put(newController, tag: newTag, permanent: true);

        Get.back();
        Get.offAll(() => ChatView(
          sessionId: newSessionId,
          token: tkn,
          webSocketService: newWebSocket,
          controllerTag: newTag,
        ));

        Future.delayed(const Duration(seconds: 1), () {
          if (Get.isRegistered<ChatController>(tag: controllerTag)) {
            Get.delete<ChatController>(tag: controllerTag, force: true);
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
      final chatController   = Get.find<ChatController>(tag: controllerTag);
      final currentPersonaId = chatController.personaId;
      final tkn              = await TokenStorage.getLoginAccessToken() ?? '';

      Get.back();
      Get.dialog(const Center(child: CircularProgressIndicator()),
          barrierDismissible: false);

      await TokenStorage.savePersonaSessionId(currentPersonaId, newSessionId);
      final newWebSocket = WebSocketService();
      final newTag = 'chat-$newSessionId-${DateTime.now().millisecondsSinceEpoch}';

      // ✅ নতুন session load — limit reset করো connect এর আগে
      newWebSocket.resetForNewSession();
      await newWebSocket.connect(newSessionId, tkn, personaId: currentPersonaId);

      final newController = ChatController(
        wsService: newWebSocket,
        sessionId: newSessionId,
        personaId: currentPersonaId,
        isNewSession: false,
      );
      Get.put(newController, tag: newTag, permanent: true);

      Get.back();
      Get.offAll(() => ChatView(
        sessionId: newSessionId,
        token: tkn,
        webSocketService: newWebSocket,
        controllerTag: newTag,
      ));

      Future.delayed(const Duration(seconds: 1), () {
        if (Get.isRegistered<ChatController>(tag: controllerTag)) {
          Get.delete<ChatController>(tag: controllerTag, force: true);
        }
      });
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Error loading session: $e");
      print("Error in loadSession: $e");
    }
  }
}