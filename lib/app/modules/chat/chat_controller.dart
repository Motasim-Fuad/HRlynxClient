import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:HRlynx/app/modules/chat/voice_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/webSocketServices.dart';
import '../../api_servies/token.dart';
import '../../model/chat/sessionHistoryModel.dart';
import '../../model/chat/session_chat_model.dart';
import '../../model/chat/suggesions_Model.dart';

class ChatController extends GetxController with GetTickerProviderStateMixin {
  final WebSocketService wsService;
  final String sessionId;
  final int personaId;

  var isTyping = false.obs;
  var messages = <Messages>[].obs;
  var session = Rxn<Session>();
  StreamSubscription? _streamSubscription;
  final suggestions = <String>[].obs;
  var isLoadingSuggestions = false.obs;
  var showSuggestions = true.obs;
  var isFirstTime = true.obs;
  final isReloadingHistory = false.obs;
  late AnimationController historyAnimationController;
  final bool isNewSession;
  var sessionHistory = <SessionHistory>[].obs;

  final TextEditingController textController = TextEditingController();

  var tokenLimitInfo      = Rxn<Map<String, dynamic>>();
  var isTokenLimitReached = false.obs;
  var showNearLimitBanner = false.obs;
  var tokenUsagePercent   = 0.0.obs;
  var tokensRemaining     = 0.obs;
  var tokensTotal         = 20000.obs;
  var limitBannerTitle    = ''.obs;
  var limitBannerMessage  = ''.obs;

  final ScrollController scrollController = ScrollController();

  ChatController({
    required this.wsService,
    required this.sessionId,
    required this.personaId,
    this.isNewSession = false,
  });

  // Syncs token limit after a controller rebuild.
  @override
  void onInit() {
    super.onInit();
    historyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (wsService.isLimitReached) {
      isTokenLimitReached.value = true;
      showNearLimitBanner.value = false;
      limitBannerMessage.value =
      "Daily AI limit reached. Try again tomorrow or upgrade your plan.";
      print('Limit state synced from WebSocketService');
    }

    fetchSessionDetails();
    fetchSuggestions(personaId);
    _setupWebSocketListener();
  }

  @override
  void onClose() {
    print('ChatController close — persona: $personaId, session: $sessionId');
    _streamSubscription?.cancel();
    _streamSubscription = null;
    wsService.disconnect().catchError((e) => print('WS disconnect: $e'));
    historyAnimationController.dispose();
    try {
      if (scrollController.hasClients) scrollController.dispose();
    } catch (e) {
      print('ScrollController dispose error: $e');
    }
    super.onClose();
  }


  void _handleTokenLimitInfo(Map<String, dynamic> status) {
    tokenLimitInfo.value = status;

    final daily     = status['daily_limits'];
    final usage     = status['usage_today'];
    final remaining = status['remaining'];

    if (daily == null || usage == null || remaining == null) return;

    final int    total = daily['tokens']     ?? 20000;
    final int    used  = usage['tokens']     ?? 0;
    final int    left  = remaining['tokens'] ?? 0;

    final double pct = (total > 0 ? (used / total) : 0.0).clamp(0.0, 1.0);

    tokensTotal.value       = total;
    tokensRemaining.value   = left;
    tokenUsagePercent.value = pct;

    print('Token: $used/$total (${(pct * 100).toStringAsFixed(1)}%)');

    if (status['limit_reached'] == true || left <= 0) {
      isTokenLimitReached.value = true;
      showNearLimitBanner.value = false;

      final backendMsg = status['message']?.toString().trim() ?? '';
      limitBannerMessage.value = backendMsg.isNotEmpty
          ? backendMsg
          : "Daily AI limit reached. Try again tomorrow or upgrade your plan.";
    }

    else if (pct >= 0.90) {
      showNearLimitBanner.value = true;
      isTokenLimitReached.value = false;

      limitBannerMessage.value =
      "You're approaching your daily AI limit. Upgrade to continue without interruption.";
    }

    else {
      showNearLimitBanner.value = false;
      isTokenLimitReached.value = false;
    }
  }

  bool get isFreeUser {
    final plan = (tokenLimitInfo.value?['plan'] ?? '').toLowerCase();
    return plan.contains('free') || plan.contains('no subscription');
  }


  // Blocks send when the daily token limit is reached.
  void send(String msg) {
    if (isTokenLimitReached.value) {
      print('Send blocked — token limit reached');
      return;
    }

    showSuggestions.value = false;
    messages.add(Messages(
      id: null,
      content: msg,
      isUser: true,
      createdAt: DateTime.now().toIso8601String(),
    ));
    update();
    messages.refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

    if (!wsService.isConnected) {
      _attemptReconnect().then((_) {
        if (wsService.isConnected) {
          wsService.sendMessage(msg);
        } else {
          Get.snackbar('Connection Error', 'Unable to send message.',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      });
    } else {
      wsService.sendMessage(msg);
    }
  }


  Future<void> sendVoiceMessage(String sessionId) async {
    if (isTokenLimitReached.value) {
      print('Voice blocked — token limit reached');
      return;
    }

    final voiceService = Get.find<VoiceService>();
    try {
      final response = await voiceService.stopRecordingAndSendToChat(sessionId);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        int? messageId;
        if (data['message_id'] != null) {
          messageId = data['message_id'] is String
              ? int.tryParse(data['message_id'])
              : data['message_id'] as int?;
        }
        messages.add(Messages(
          id: messageId,
          content: data['transcript'],
          isUser: true,
          createdAt: DateTime.now().toIso8601String(),
          messageType: 'voice',
          voice_file_url: data['voice_url'],
          transcript: data['transcript'],
        ));
        update();
        messages.refresh();
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
        if (wsService.isConnected && data['transcript'] != null) {
          wsService.sendMessage(data['transcript']);
        }
      } else {
        Get.snackbar('Error', 'Failed to send voice message');
      }
    } catch (e) {
      print('Voice error: $e');
      Get.snackbar('Error', 'Error: $e');
    }
  }


  void _setupWebSocketListener() {
    _streamSubscription?.cancel();
    Future.delayed(const Duration(milliseconds: 500), () {
      _streamSubscription = wsService.stream.listen(
        _handleWebSocketMessage,
        onError: (e) { print('WS error: $e'); _handleConnectionError(); },
        onDone:  () { print('WS closed'); isTyping.value = false; },
      );
      print('WS listener ready');
    });
  }

  void _handleWebSocketMessage(dynamic event) {
    try {
      Map<String, dynamic> data;
      if (event is String) {
        data = jsonDecode(event);
      } else if (event is Map<String, dynamic>) {
        data = event;
      } else {
        return;
      }

      switch (data['type']) {
        case 'connection':
          print('WS connected: ${data['message']}');
          break;

        case 'error':
          _handleWebSocketError(data['message'] ?? 'Unknown error');
          break;

        case 'typing':
          isTyping.value = data['is_typing'] == true;
          break;

        case 'chat_message':
        case 'message':
          (data['message_type'] ?? 'text') == 'voice'
              ? _handleIncomingVoiceMessage(data)
              : _handleIncomingMessage(data);
          break;

        case 'limit_reached':
          isTyping.value = false;
          final limitInfo = data['limit_info'];
          if (limitInfo != null) {
            final msg = limitInfo['message']?.toString().trim() ?? '';
            limitBannerMessage.value = msg.isNotEmpty
                ? msg
                : "Daily AI limit reached. Try again tomorrow or upgrade your plan.";

            final status = limitInfo['status'];
            if (status != null) {
              _handleTokenLimitInfo(Map<String, dynamic>.from(status));
            } else {
              isTokenLimitReached.value = true;
              showNearLimitBanner.value = false;
            }
          }
          print('Limit reached: ${limitBannerMessage.value}');
          break;

        case 'pong':
          print('Pong');
          break;

        default:
          print('Unknown type: ${data['type']}');
      }
    } catch (e) {
      print('WS parse error: $e');
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      isTyping.value = false;

      if (data['limit_info'] != null) {
        _handleTokenLimitInfo(Map<String, dynamic>.from(data['limit_info']));
      }

      final String content =
          data['content']?.toString() ?? data['message']?.toString() ?? '';
      if (content.isEmpty) return;

      final raw = data['message_id'] ?? data['id'];
      final int? messageId =
      raw == null ? null : (raw is String ? int.tryParse(raw) : raw as int?);

      messages.add(Messages(
        id: messageId,
        content: content,
        isUser: false,
        createdAt: data['timestamp'] ??
            data['created_at'] ??
            DateTime.now().toIso8601String(),
      ));
      print('AI message added. Total: ${messages.length}');
      update();
      messages.refresh();
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    } catch (e) {
      print('Incoming message error: $e');
    }
  }

  void _handleIncomingVoiceMessage(Map<String, dynamic> data) {
    try {
      isTyping.value = false;
      if (data['limit_info'] != null) {
        _handleTokenLimitInfo(Map<String, dynamic>.from(data['limit_info']));
      }

      if ((data['message_type'] ?? '') == 'voice') {
        final raw = data['message_id'] ?? data['id'];
        final int? messageId =
        raw == null ? null : (raw is String ? int.tryParse(raw) : raw as int?);

        messages.add(Messages(
          id: messageId,
          content: data['transcript'] ?? data['content'],
          isUser: false,
          createdAt: data['timestamp'] ??
              data['created_at'] ??
              DateTime.now().toIso8601String(),
          messageType: 'voice',
          voice_file_url: data['voice_url'],
          transcript: data['transcript'],
        ));
        update();
        messages.refresh();
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
      } else {
        _handleIncomingMessage(data);
      }
    } catch (e) {
      print('Incoming voice error: $e');
    }
  }

  void _handleWebSocketError(String errorMessage) {
    Color  bg    = Colors.red;
    String title = 'Connection Error';
    String msg   = errorMessage;

    if (errorMessage.contains('429') || errorMessage.contains('quota') ||
        errorMessage.contains('exceeded') || errorMessage.contains('insufficient_quota')) {
      title = 'AI Usage Limit Reached';
      msg   = "You've exceeded your AI usage quota.";
      bg    = Colors.orange.shade700;
      isTyping.value = false;
    } else if (errorMessage.contains('401')) {
      title = 'Authentication Error';
      msg   = 'Your session has expired. Please login again.';
    } else if (errorMessage.contains('500')) {
      title = 'Server Error';
      msg   = 'Server is experiencing issues. Please try again later.';
    }

    Get.snackbar(title, msg,
        backgroundColor: bg,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8);
  }

  void _handleConnectionError() {
    isTyping.value = false;
    Future.delayed(const Duration(seconds: 3), () {
      if (!wsService.isConnected) _attemptReconnect();
    });
  }

  Future<void> _attemptReconnect() async {
    try {
      final token = await TokenStorage.getLoginAccessToken();
      if (token != null) {
        await wsService.connect(sessionId, token, personaId: personaId);
        _setupWebSocketListener();
        print('Reconnected');
      }
    } catch (e) {
      print('Reconnect failed: $e');
    }
  }


  Future<void> fetchSuggestions(int personaId) async {
    try {
      if (!isNewSession) { showSuggestions.value = false; return; }
      isLoadingSuggestions.value = true;
      final response = await AuthRepository().AiSuggestions(personaId);
      if (response != null) {
        final model = SuggesionsModel.fromJson(response);
        if (model.success) {
          suggestions.assignAll(model.suggestions);
          showSuggestions.value = suggestions.isNotEmpty;
          return;
        }
      }
      suggestions.clear();
      showSuggestions.value = false;
    } catch (e) {
      print('Suggestions error: $e');
      suggestions.clear();
      showSuggestions.value = false;
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  void onSuggestionTap(String suggestion) {
    textController.text = suggestion;
    textController.selection =
        TextSelection.fromPosition(TextPosition(offset: suggestion.length));
    showSuggestions.value = false;
    isFirstTime.value = false;
  }


  Future<void> fetchSessionDetails() async {
    try {
      final sessionIdInt = sessionIdAsInt;
      if (sessionIdInt == null) {
        print("Invalid session ID: '$sessionId'");
        return;
      }

      final response = await AuthRepository().fetchSessionsDetails(sessionIdInt);
      final model    = SessonChatHistoryModel.fromJson(response);
      session.value  = model.session;
      messages.clear();

      if (model.messages != null && model.messages!.isNotEmpty) {
        List<Messages> sorted = List.from(model.messages!);
        sorted.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

        List<Messages> filtered = [];
        Set<String>    seen     = {};

        for (int i = 0; i < sorted.length; i++) {
          final msg     = sorted[i];
          final content = msg.content?.trim() ?? '';
          if (content.isEmpty) { filtered.add(msg); continue; }
          if (seen.contains(content)) continue;

          List<Messages> dupes = [msg];
          for (int j = i + 1; j < math.min(i + 6, sorted.length); j++) {
            if (sorted[j].content?.trim() == content) dupes.add(sorted[j]);
          }

          if (dupes.length > 1) {
            final voice = dupes.firstWhereOrNull(_isVoiceMessage);
            final text  = dupes.firstWhereOrNull((m) => !_isVoiceMessage(m));
            if (voice != null) {
              filtered.add(Messages(
                id: voice.id, content: voice.content, isUser: voice.isUser,
                createdAt: voice.createdAt, messageType: 'voice', hasVoice: true,
                voice_file_url: voice.voice_file_url,
                transcript: voice.transcript ?? voice.content,
              ));
            } else if (text != null) {
              filtered.add(text);
            }
          } else {
            filtered.add(msg);
          }
          seen.add(content);
        }
        messages.assignAll(filtered);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    } catch (e) {
      print("fetchSessionDetails error: $e");
    }
  }

  Future<void> reloadHistory() async {
    try {
      final r = await AuthRepository().fetchPersonaChatHistory(personaId);
      print(r != null && r['success'] == true ? 'History reloaded' : 'Failed to reload');
    } catch (e) {
      print('Error reloading history: $e');
    }
  }

  Future<void> refreshSessionHistory() async {
    try {
      final r = await AuthRepository().fetchPersonaChatHistory(personaId);
      if (r != null && r['success'] == true) {
        sessionHistory.assignAll(
            (r['sessions'] as List).map((e) => SessionHistory.fromJson(e)).toList());
      }
    } catch (e) {
      print('Error refreshing session history: $e');
    }
  }

  int? get sessionIdAsInt => int.tryParse(sessionId.toString());

  bool _isVoiceMessage(Messages m) =>
      m.messageType == 'voice' ||
          m.hasVoice == true ||
          (m.voice_file_url != null && m.voice_file_url!.isNotEmpty);

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void navigateToOldSession() {}
}
