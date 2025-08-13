import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/chat/voice_service_controller.dart';
import 'package:hr/app/modules/chat/widget/voice_message_widget.dart';
import 'package:hr/app/utils/chat_utils.dart';
import '../../../api_servies/api_Constant.dart';
import '../chat_controller.dart';

class MessageListWidget extends StatelessWidget {
  final ChatController chatController;
  final dynamic session;
  final VoiceService voiceService;

  const MessageListWidget({
    super.key,
    required this.chatController,
    required this.session,
    required this.voiceService,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() => ListView.builder(
        controller: chatController.scrollController,
        itemCount: chatController.messages.length,
        itemBuilder: (_, i) {
          final message = chatController.messages[i];
          final isMe = message.isUser == true;

          // Debug print for each message
          print("🔍 Displaying message ${message.id}: isVoice=${message.isVoice}, messageType=${message.messageType}, hasVoice=${message.hasVoice}, voice_url=${message.voice_file_url}");

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: session != null && session.persona?.avatar != null
                        ? CachedNetworkImageProvider("${ApiConstants.baseUrl}${session.persona!.avatar}")
                        : null,
                  ),
                if (!isMe) const SizedBox(width: 8),
                Flexible(
                  child: Builder(
                    builder: (context) {
                      // Enhanced check for voice messages
                      bool shouldShowAsVoice = message.isVoice;

                      print("🎯 Message ${message.id} shouldShowAsVoice: $shouldShowAsVoice");

                      if (shouldShowAsVoice) {
                        print("🎤 Rendering as VoiceMessageBubble for message ${message.id}");
                        return VoiceMessageBubble(
                          voiceUrl: message.voice_file_url,
                          transcript: message.transcript ?? message.content,
                          isUser: message.isUser ?? false,
                          timestamp: message.createdAt ?? '',
                          // REMOVED: voiceService parameter - it will get it globally now
                          audioDuration: null, // or calculate from your data
                        );
                      } else {
                        print("📝 Rendering as text bubble for message ${message.id}");
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                message.content ?? '',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTime(parseIsoDate(message.createdAt)),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      )),
    );
  }
}