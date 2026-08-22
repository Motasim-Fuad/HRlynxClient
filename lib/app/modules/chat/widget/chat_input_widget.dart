import 'package:HRlynx/app/modules/chat/voice_service_controller.dart';
import 'package:HRlynx/app/modules/chat/widget/ai_consent_dialog.dart';
import 'package:HRlynx/app/modules/chat/widget/voice_recording_widget.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat_controller.dart';

class ChatInputWidget extends StatelessWidget {
  final ChatController chatController;
  final VoiceService voiceService;
  final String sessionId;

  const ChatInputWidget({
    super.key,
    required this.chatController,
    required this.voiceService,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final consentController = Get.find<ConsentController>();

    return Obx(() {
      final isLimitReached = chatController.isTokenLimitReached.value;
      final showNearLimit = chatController.showNearLimitBanner.value;
      final hasConsented = consentController.hasConsented.value;
      final isFree = chatController.isFreeUser;
      final bannerMessage = chatController.limitBannerMessage.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          if (showNearLimit && !isLimitReached && bannerMessage.isNotEmpty)
            _LimitBanner(
              message: bannerMessage,
              isFree: isFree,
            ),

          if (isLimitReached && bannerMessage.isNotEmpty)
            _LimitBanner(
              message: bannerMessage,
              isFree: isFree,
            ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildInputArea(
              context,
              consentController,
              hasConsented: hasConsented,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInputArea(
      BuildContext context,
      ConsentController consentController, {
        required bool hasConsented,
      }) {

    if (voiceService.isRecording.value) {
      return VoiceRecordingWidget(
        duration: voiceService.formatDuration(
            voiceService.recordingDuration.value),
        onCancel: () async => await voiceService.cancelRecording(),
        onSend: () async {
          if (hasConsented) await chatController.sendVoiceMessage(sessionId);
        },
      );
    }

    if (voiceService.isProcessing.value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text("Processing voice message..."),
          ],
        ),
      );
    }

    if (!hasConsented) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Please agree to the AI Chat Disclosure to start chatting.",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: () => AiConsentDialog.showIfNeeded(context),
              child: const Text("View"),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: chatController.textController,
            decoration: InputDecoration(
              hintText: "Type a message...",
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                ),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ),
        const SizedBox(width: 8),


        IconButton(
          onPressed: chatController.isTokenLimitReached.value
              ? null
              : () async {
            final started = await voiceService.startRecording();
            if (!started) {
              Get.snackbar("Error", "Could not start recording");
            }
          },
          icon: Icon(
            Icons.mic,
            color: chatController.isTokenLimitReached.value
                ? Colors.grey
                : Colors.black,
          ),
        ),

        IconButton(
          icon: Icon(
            Icons.send,
            color: chatController.isTokenLimitReached.value
                ? Colors.grey
                : Colors.black,
          ),
          onPressed: chatController.isTokenLimitReached.value
              ? null
              : () {
            final text = chatController.textController.text.trim();
            if (text.isNotEmpty) {
              chatController.send(text);
              chatController.textController.clear();
              chatController.showSuggestions.value = false;
              chatController.isFirstTime.value = false;
            }
          },
        ),
      ],
    );
  }
}


class _LimitBanner extends StatelessWidget {
  final String message;
  final bool isFree;

  const _LimitBanner({
    required this.message,
    required this.isFree,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade200,
      child: Row(
        children: [

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
              ),
            ),
          ),

          if (isFree) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Get.to(SubscriptionScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Upgrade",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
