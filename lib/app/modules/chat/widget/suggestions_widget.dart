import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../chat_controller.dart';

class SuggestionsWidget extends StatelessWidget {
  final ChatController chatController;

  // ✅ textController parameter সরানো — chatController.textController ব্যবহার হয়

  const SuggestionsWidget({
    super.key,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if ((chatController.isFirstTime.value || chatController.showSuggestions.value) &&
          chatController.suggestions.isNotEmpty) {
        return Container(
          alignment: const AlignmentDirectional(-0.8, 1),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: chatController.suggestions.map((suggestion) {
                return GestureDetector(
                  onTap: () {
                    // ✅ chatController.onSuggestionTap — internally uses textController
                    chatController.onSuggestionTap(suggestion);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      suggestion,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    });
  }
}