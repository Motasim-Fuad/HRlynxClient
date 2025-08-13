import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat_controller.dart';

// Separate widget for refresh button to avoid Obx issues
class RefreshButton extends StatelessWidget {
  final ChatController chatController;

  const RefreshButton({super.key, required this.chatController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return IconButton(
        icon: chatController.isReloadingHistory.value
            ? RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: chatController.historyAnimationController,
              curve: Curves.linear,
            ),
          ),
          child: const Icon(Icons.refresh, color: Colors.white),
        )
            : const Icon(Icons.refresh, color: Colors.white),
        onPressed: () async {
          if (!chatController.isReloadingHistory.value) {
            // Start animation
            chatController.isReloadingHistory.value = true;
            chatController.historyAnimationController.repeat();

            // Make API call
            await chatController.reloadHistory();

            // Stop animation
            chatController.historyAnimationController.stop();
            chatController.isReloadingHistory.value = false;
          }
        },
      );
    });
  }
}