import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../chat_controller.dart';
import 'refresh_button.dart';
import 'history_list_widget.dart';

class ChatDrawer extends StatelessWidget {
  final ChatController chatController;
  final String sessionId;
  final String controllerTag;
  final Future<void> Function() onCreateNewSession;
  final Future<void> Function(String) onLoadSession;
  final Future<void> Function(int) onDeleteHistory;

  const ChatDrawer({
    super.key,
    required this.chatController,
    required this.sessionId,
    required this.controllerTag,
    required this.onCreateNewSession,
    required this.onLoadSession,
    required this.onDeleteHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: Get.width * 0.8,
      child: Container(
        color: AppColors.primarycolor,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                color: Colors.teal.shade900,
                child: ListTile(
                  style: ListTileStyle.list,
                  title: const Text("New Chat", style: TextStyle(color: Colors.white)),
                  leading: const Icon(Icons.edit_note_rounded, color: Colors.white),
                  onTap: onCreateNewSession,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          const Icon(Icons.history, color: Colors.white),
                          const SizedBox(width: 20),
                          const Text(
                            "History",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          RefreshButton(chatController: chatController),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: HistoryListWidget(
                        chatController: chatController,
                        sessionId: sessionId,
                        onLoadSession: onLoadSession,
                        onDeleteHistory: onDeleteHistory,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}