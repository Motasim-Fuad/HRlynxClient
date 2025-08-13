import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../api_servies/repository/auth_repo.dart';
import '../../../model/chat/sessionHistoryModel.dart';
import '../chat_controller.dart';
import 'package:hr/app/modules/chat/widget/sessionTitle.dart' show SessionHistoryTile;

// Separate widget for history list to avoid Obx issues
class HistoryListWidget extends StatelessWidget {
  final ChatController chatController;
  final String sessionId;
  final Function(String) onLoadSession;
  final Function(int) onDeleteHistory;

  const HistoryListWidget({
    super.key,
    required this.chatController,
    required this.sessionId,
    required this.onLoadSession,
    required this.onDeleteHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // This Obx watches for the reload trigger
      chatController.isReloadingHistory.value; // This line ensures Obx watches this observable

      return FutureBuilder(
        future: AuthRepository().fetchPersonaChatHistory(chatController.personaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!['success']) {
            return const Center(child: Text("Failed to load history", style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final sessions = (data['sessions'] as List).map((e) => SessionHistory.fromJson(e)).toList();

          if (sessions.isEmpty) {
            return const Center(child: Text("No chat history", style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              // Add bounds checking
              if (index >= sessions.length) {
                return const SizedBox.shrink();
              }

              final session = sessions[index];
              final isCurrentSession = session.id == sessionId;

              return SessionHistoryTile(
                session: session,
                onTap: () => onLoadSession(session.id),
                onDelete: isCurrentSession ? null : () async {
                  await onDeleteHistory(int.parse(session.id));
                  // Trigger rebuild by updating the observable
                  chatController.reloadHistory();
                },
                isCurrentSession: isCurrentSession,
              );
            },
          );
        },
      );
    });
  }
}