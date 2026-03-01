
import 'package:HRlynx/app/modules/chat/voice_service_controller.dart';
import 'package:HRlynx/app/modules/chat/widget/ai_consent_dialog.dart';
import 'package:HRlynx/app/modules/chat/widget/voice_recording_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat_controller.dart';

class ChatInputWidget extends StatelessWidget {
  final ChatController chatController;
  final VoiceService voiceService;
  final TextEditingController textController;
  final String sessionId;

  const ChatInputWidget({
    super.key,
    required this.chatController,
    required this.voiceService,
    required this.textController,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    final consentController = Get.find<ConsentController>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Obx(() {
        final isLimitReached = chatController.isSessionLimitReached.value;
        final hasConsented = consentController.hasConsented.value; // ✅

        // Show voice recording widget when recording
        if (voiceService.isRecording.value) {
          return VoiceRecordingWidget(
            duration: voiceService.formatDuration(voiceService.recordingDuration.value),
            onCancel: () async {
              await voiceService.cancelRecording();
            },
            onSend: () async {
              if (!isLimitReached && hasConsented) {
                await chatController.sendVoiceMessage(sessionId);
              }
            },
          );
        }

        // Show processing widget when processing voice
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

        // Show disabled input when limit reached
        if (isLimitReached) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Session limit reached. Create a new session to continue chatting.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // ✅ Consent not given — show locked input UI
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

        // Normal input row
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                enabled: !isLimitReached,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onTap: () {
                  if (isLimitReached) {
                    chatController.showLimitReachedDialog();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),

            // Voice button
            IconButton(
              onPressed: () async {
                final started = await voiceService.startRecording();
                if (!started) {
                  Get.snackbar("Error", "Could not start recording");
                }
              },
              icon: const Icon(Icons.mic),
              tooltip: "Record voice message",
            ),

            // Send button
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  chatController.send(text);
                  textController.clear();
                  chatController.showSuggestions.value = false;
                  chatController.isFirstTime.value = false;
                }
              },
              tooltip: "Send message",
            ),
          ],
        );
      }),
    );
  }
}
//```
//
//---
//
//## How it flows
//```
//App opens ChatView
//└─> ConsentController loads SharedPrefs
//└─> hasConsented = false → input shows locked UI 🔒
//└─> AiConsentDialog.showIfNeeded() triggers dialog
//
//User clicks "Cancel"
//└─> Dialog closes, hasConsented stays false → still locked 🔒
//
//User clicks "Agree & Continue"
//└─> consentController.giveConsent() called
//└─> hasConsented.value = true (reactive!)
//└─> Obx rebuilds → normal input appears instantly ✅