import 'package:HRlynx/app/modules/chat/voice_service_controller.dart';
import 'package:HRlynx/app/modules/chat/widget/voice_message_widget.dart';
import 'package:HRlynx/app/modules/profile/profile_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../api_servies/api_Constant.dart';
import '../chat_controller.dart';

class MessageListWidget extends StatelessWidget {
  final ChatController chatController;
  final dynamic session;
  final VoiceService voiceService;
  final ProfileController profileController;

  const MessageListWidget({
    super.key,
    required this.chatController,
    required this.session,
    required this.voiceService,
    required this.profileController,
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

          final previousMessage = i > 0 ? chatController.messages[i - 1] : null;
          final showDateSeparator = _shouldShowDateSeparator(previousMessage, message);

          return Column(
            children: [
              if (showDateSeparator) _buildDateSeparator(message.createdAt),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: session != null &&
                            session.persona?.avatar != null &&
                            session.persona!.avatar!.isNotEmpty
                            ? CachedNetworkImageProvider("${session.persona!.avatar}")
                            : null,
                        child: session == null ||
                            session.persona?.avatar == null ||
                            session.persona!.avatar!.isEmpty
                            ? Icon(Icons.smart_toy, size: 20, color: Colors.grey[600])
                            : null,
                      ),
                    if (!isMe) const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          _buildMessageContent(message, isMe),

                          const SizedBox(height: 4),
                          _buildTimeDisplay(message, isMe),
                        ],
                      ),
                    ),
                    if (isMe) const SizedBox(width: 8),
                    if (isMe)
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileController.userProfilePicture.value != null &&
                            profileController.userProfilePicture.value!.isNotEmpty
                            ? CachedNetworkImageProvider(profileController.userProfilePicture.value!)
                            : null,
                        child: profileController.userProfilePicture.value == null ||
                            profileController.userProfilePicture.value!.isEmpty
                            ? Icon(Icons.person, size: 20, color: Colors.grey[600])
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      )),
    );
  }

  Widget _buildDateSeparator(String? timestamp) {
    final date = _parseDate(timestamp);
    final formattedDate = _formatDate(date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formattedDate,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(dynamic message, bool isMe) {
    bool shouldShowAsVoice = message.isVoice;

    if (shouldShowAsVoice) {
      return VoiceMessageBubble(
        voiceUrl: message.voice_file_url,
        transcript: message.transcript ?? message.content,
        isUser: message.isUser ?? false,
        timestamp: message.createdAt ?? '',
        audioDuration: null,
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        /*child: SelectableText(
          message.content ?? '',
          style: const TextStyle(fontSize: 15),
        ),*/
        child: MarkdownBody(
          data: message.content ?? '',
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 15, height: 1.4),
            strong: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isMe ? Colors.blue[900] : Colors.black87,
            ),
            em: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15),
            h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            listBullet: const TextStyle(fontSize: 15),
            blockquoteDecoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border(left: BorderSide(color: Colors.grey, width: 3)),
            ),
            code: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              backgroundColor: Color(0xFFEEEEEE),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTimeDisplay(dynamic message, bool isMe) {
    final date = _parseDate(message.createdAt);
    final formattedTime = _formatTime(date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.check,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(dynamic previousMessage, dynamic currentMessage) {
    if (previousMessage == null) return true;

    try {
      final prevDate = _parseDate(previousMessage.createdAt);
      final currDate = _parseDate(currentMessage.createdAt);

      final prevDay = DateTime(prevDate.year, prevDate.month, prevDate.day);
      final currDay = DateTime(currDate.year, currDate.month, currDate.day);

      return prevDay != currDay;
    } catch (e) {
      return false;
    }
  }

  DateTime _parseDate(String? timestamp) {
    try {
      if (timestamp != null && timestamp.isNotEmpty) {
        return DateTime.parse(timestamp).toLocal();
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return 'Today';
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else if (now.difference(messageDay).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}
