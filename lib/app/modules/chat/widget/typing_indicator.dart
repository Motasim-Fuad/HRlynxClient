import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api_servies/api_Constant.dart';
import '../chat_controller.dart';

class TypingIndicator extends StatelessWidget {
  final ChatController chatController;
  final dynamic session;

  const TypingIndicator({
    super.key,
    required this.chatController,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (chatController.isTyping.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: session != null && session.persona?.avatar != null
                    ? CachedNetworkImageProvider("${ApiConstants.baseUrl}${session.persona!.avatar}")
                    : null,
              ),
              const SizedBox(width: 8),
              const Text(
                "Typing...",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    });
  }
}