
import 'package:get/get.dart';

import 'chat_history_model.dart' show ChatHistoryModel;

class ChatHistoryController extends GetxController {
  var historyList = <ChatHistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    historyList.addAll([
      ChatHistoryModel(
        headline: 'Give me the name of the most famous Songwriters',
        time: '08 August 2024 | 03:23 AM',
      ),
      ChatHistoryModel(
        headline: 'What to visit in Japan',
        time: '08 August 2024 | 03:23 AM',
      ),
      ChatHistoryModel(
        headline: 'How to renovate my house',
        time: '08 August 2024 | 03:23 AM',
      ),
      ChatHistoryModel(
        headline: 'Why is the sky blue',
        time: '08 August 2024 | 03:23 AM',
      ),
    ]);
  }

  void removeItem(int index) {
    historyList.removeAt(index);
  }
}
