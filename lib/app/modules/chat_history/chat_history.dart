
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_history_controller.dart' show ChatHistoryController;

class ChatHistory extends StatelessWidget {
  ChatHistory({super.key});
  final ChatHistoryController controller = Get.put(ChatHistoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                print('search tapped');
              },
              child: Container(
                height: 20,
                width: 20,
                child: TextFormField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),
        ],
        centerTitle: true,
        title: Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
      ),
      body: Obx(
        () => ListView.builder(
          itemCount: controller.historyList.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final item = controller.historyList[index];

            return Dismissible(
              key: Key(item.headline),
              direction: DismissDirection.endToStart,
              background: Container(
                padding: const EdgeInsets.only(right: 20),
                alignment: Alignment.centerRight,
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                controller.removeItem(index);
                Get.snackbar(
                  "Deleted",
                  item.headline,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffe6eceb),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.headline,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
