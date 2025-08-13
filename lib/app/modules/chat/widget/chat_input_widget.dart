import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart';
import 'package:hr/app/modules/chat/widget/voice_recording_widget.dart' show VoiceRecordingWidget;
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Obx(() {
        final isLimitReached = chatController.isSessionLimitReached.value;

        // Show voice recording widget when recording
        if (voiceService.isRecording.value) {
          return VoiceRecordingWidget(
            duration: voiceService.formatDuration(voiceService.recordingDuration.value),
            onCancel: () async {
              await voiceService.cancelRecording();
            },
            onSend: () async {
              if (!isLimitReached) {
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

        // Show normal input row when not at limit
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                enabled: !isLimitReached,
                decoration: InputDecoration(
                  hintText: isLimitReached
                      ? "Session limit reached"
                      : "Type a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  filled: isLimitReached,
                  fillColor: isLimitReached ? Colors.grey.shade100 : null,
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
              onPressed: isLimitReached ? null : () async {
                final started = await voiceService.startRecording();
                if (!started) {
                  Get.snackbar("Error", "Could not start recording");
                }
              },
              icon: Icon(
                Icons.mic,
                color: isLimitReached ? Colors.grey : null,
              ),
              tooltip: isLimitReached ? "Session limit reached" : "Record voice message",
            ),

            // Send button
            IconButton(
              icon: Icon(
                Icons.send,
                color: isLimitReached ? Colors.grey : null,
              ),
              onPressed: isLimitReached ? null : () {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  chatController.send(text);
                  textController.clear();
                  chatController.showSuggestions.value = false;
                  chatController.isFirstTime.value = false;
                }
              },
              tooltip: isLimitReached ? "Session limit reached" : "Send message",
            ),
          ],
        );
      }),
    );
  }
}