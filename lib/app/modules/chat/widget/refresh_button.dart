import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat_controller.dart';

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
            chatController.isReloadingHistory.value = true;
            chatController.historyAnimationController.repeat();

            await chatController.reloadHistory();

            chatController.historyAnimationController.stop();
            chatController.isReloadingHistory.value = false;
          }
        },
      );
    });
  }
}
