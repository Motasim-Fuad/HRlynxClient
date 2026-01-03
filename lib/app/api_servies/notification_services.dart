// lib/app/api_servies/notification_services.dart - PRODUCTION READY

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:get/get.dart';
import '../api_servies/api_Constant.dart';
import '../api_servies/token.dart';
import '../api_servies/neteork_api_services.dart';

class NotificationService extends GetxController {
  static NotificationService get instance => Get.find();

  WebSocketChannel? _channel;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isConnected = false.obs;
  final RxString connectionStatus = 'Disconnected'.obs;

  bool _isConnecting = false;
  bool _shouldStayConnected = true;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _streamSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final token = await TokenStorage.getLoginAccessToken().timeout(
        Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (token != null && token.isNotEmpty) {
        _shouldStayConnected = true;
        connectionStatus.value = 'Initializing...';
        await fetchAllNotifications();
        await connectWebSocket();
        _startHeartbeat();
      } else {
        connectionStatus.value = 'No token';
      }
    } catch (e) {
      print('⚠️ Init error: $e');
      connectionStatus.value = 'Init failed';
    }
  }

  Future<void> connectWebSocket() async {
    if (_isConnecting) {
      print('🔄 Already connecting');
      return;
    }

    try {
      final token = await TokenStorage.getLoginAccessToken().timeout(
        Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (token == null || token.isEmpty) {
        print('❌ No token');
        _shouldStayConnected = false;
        connectionStatus.value = 'Auth required';
        return;
      }

      if (!_shouldStayConnected) {
        print('🛑 Not staying connected');
        connectionStatus.value = 'Disabled';
        return;
      }

      _isConnecting = true;
      connectionStatus.value = 'Connecting...';
      _reconnectTimer?.cancel();
      await _safeDisconnect();

      String wsUrl = _buildWebSocketUrl(token);
      print('🔌 Connecting: $wsUrl');

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['websocket'],
      );

      Timer? timeout = Timer(Duration(seconds: 15), () {
        if (!isConnected.value) {
          print('❌ Connection timeout');
          connectionStatus.value = 'Timeout';
          _channel?.sink.close();
          _isConnecting = false;
          if (_shouldStayConnected) {
            _handleReconnection();
          }
        }
      });

      _streamSubscription = _channel!.stream.listen(
            (data) {
          timeout?.cancel();
          print('📨 Data: $data');
          _handleWebSocketMessage(data);
          _reconnectAttempts = 0;

          if (!isConnected.value) {
            isConnected.value = true;
            connectionStatus.value = 'Connected';
            print('✅ Connected');
          }
        },
        onError: (error) {
          timeout?.cancel();
          print('❌ WS Error: $error');
          isConnected.value = false;
          connectionStatus.value = 'Error';
          _isConnecting = false;

          if (_shouldStayConnected) {
            _handleReconnection();
          }
        },
        onDone: () {
          timeout?.cancel();
          print('🔌 Closed');
          isConnected.value = false;
          connectionStatus.value = 'Disconnected';
          _isConnecting = false;

          if (_shouldStayConnected) {
            _handleReconnection();
          }
        },
      );

      isConnected.value = true;
      connectionStatus.value = 'Connected';
      _reconnectAttempts = 0;
      _isConnecting = false;
      print('✅ WS Connected');

    } catch (e) {
      print('❌ WS Error: $e');
      isConnected.value = false;
      connectionStatus.value = 'Failed';
      _isConnecting = false;

      if (_shouldStayConnected) {
        _handleReconnection();
      }
    }
  }

  String _buildWebSocketUrl(String token) {
    String wsUrl;
    if (ApiConstants.baseUrl.startsWith('https://')) {
      wsUrl = ApiConstants.baseUrl.replaceFirst('https://', 'wss://');
    } else if (ApiConstants.baseUrl.startsWith('http://')) {
      wsUrl = ApiConstants.baseUrl.replaceFirst('http://', 'ws://');
    } else {
      wsUrl = 'wss://${ApiConstants.baseUrl}';
    }
    return '$wsUrl/ws/notifications/?token=$token';
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_shouldStayConnected && _channel != null && isConnected.value) {
        try {
          final ping = jsonEncode({
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          _channel!.sink.add(ping);
          print('💓 Heartbeat');
        } catch (e) {
          print('❌ Heartbeat failed: $e');
          isConnected.value = false;
          connectionStatus.value = 'Heartbeat failed';
          if (_shouldStayConnected) {
            _handleReconnection();
          }
        }
      } else if (!_shouldStayConnected) {
        timer.cancel();
      }
    });
  }

  void _handleReconnection() async {
    if (_isConnecting || !_shouldStayConnected) return;

    try {
      final token = await TokenStorage.getLoginAccessToken().timeout(
        Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (token == null || token.isEmpty) {
        print('❌ No token for reconnect');
        _shouldStayConnected = false;
        connectionStatus.value = 'Auth required';
        await disconnectWebSocket();
        return;
      }
    } catch (e) {
      print('⚠️ Reconnect token check failed: $e');
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max attempts reached');
      _reconnectAttempts = 0;
      connectionStatus.value = 'Paused';

      _reconnectTimer = Timer(Duration(minutes: 2), () {
        if (_shouldStayConnected) {
          _handleReconnection();
        }
      });
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _getReconnectDelay());
    connectionStatus.value = 'Reconnecting in ${delay.inSeconds}s';
    print('🔄 Reconnect #$_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () async {
      if (_shouldStayConnected) {
        await connectWebSocket();
      }
    });
  }

  int _getReconnectDelay() {
    final baseDelay = [2, 5, 10, 20, 30][min(_reconnectAttempts - 1, 4)];
    final random = Random();
    final jitter = max(1, (baseDelay * 0.1).round());
    return baseDelay + random.nextInt(jitter);
  }

  Future<void> _safeDisconnect() async {
    if (_streamSubscription != null) {
      await _streamSubscription!.cancel();
      _streamSubscription = null;
    }

    if (_channel != null) {
      try {
        await _channel!.sink.close(status.normalClosure);
        print('🔌 Disconnected');
      } catch (e) {
        print('⚠️ Disconnect error: $e');
      } finally {
        _channel = null;
        isConnected.value = false;
      }
    }
  }

  Future<void> _handleWebSocketMessage(dynamic data) async {
    try {
      if (data == null || data.toString().isEmpty) {
        print('⚠️ Empty message');
        return;
      }

      final Map<String, dynamic> message = jsonDecode(data);

      if (!message.containsKey('type')) {
        print('⚠️ Missing type');
        return;
      }

      switch (message['type']) {
        case 'notification':
          await _handleNotificationMessage(message);
          break;
        case 'pong':
          print('💓 Pong');
          break;
        case 'error':
          await _handleErrorMessage(message);
          break;
        default:
          print('ℹ️ Unknown: ${message['type']}');
      }
    } catch (e) {
      print('❌ Message error: $e');
    }
  }

  Future<void> _handleNotificationMessage(Map<String, dynamic> message) async {
    try {
      if (!message.containsKey('data')) {
        print('⚠️ Missing data');
        return;
      }

      final notification = NotificationModel.fromJson(message['data']);

      final exists = notifications.indexWhere((n) => n.id == notification.id);
      if (exists == -1) {
        notifications.insert(0, notification);
        _updateUnreadCount();
        print('✅ New notification: ${notification.title}');
      }
    } catch (e) {
      print('❌ Notification error: $e');
    }
  }

  Future<void> _handleErrorMessage(Map<String, dynamic> message) async {
    final error = message['message'] ?? 'Unknown';
    final code = message['code'];

    print('❌ Server error: $error ($code)');

    switch (code) {
      case 'invalid_token':
      case 'token_expired':
        await forceDisconnectDueToInvalidToken();
        break;
      default:
        connectionStatus.value = 'Error: $error';
    }
  }

  Future<void> forceDisconnectDueToInvalidToken() async {
    print('🚫 Invalid token - disconnecting');
    _shouldStayConnected = false;
    connectionStatus.value = 'Auth failed';
    await disconnectWebSocket();
  }

  Future<void> disconnectWebSocket() async {
    print('🛑 Disconnecting');
    _shouldStayConnected = false;
    connectionStatus.value = 'Disconnecting...';
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts;
    await _safeDisconnect();
    connectionStatus.value = 'Disconnected';
  }

  Future<void> enableConnection() async {
    print('✅ Enabling connection');
    _shouldStayConnected = true;
    _reconnectAttempts = 0;
    _isConnecting = false;

    try {
      final token = await TokenStorage.getLoginAccessToken().timeout(
        Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (token != null && token.isNotEmpty) {
        await connectWebSocket();
        _startHeartbeat();
      } else {
        connectionStatus.value = 'No token';
      }
    } catch (e) {
      print('⚠️ Enable error: $e');
      connectionStatus.value = 'Enable failed';
    }
  }

  Future<void> fetchAllNotifications() async {
    try {
      final url = "${ApiConstants.baseUrl}/api/notifications/list/";
      final response = await NetworkApiServices.getApi(
        url,
        withAuth: true,
        tokenType: 'login',
      ).timeout(Duration(seconds: 10));

      if (response != null && response['results'] != null) {
        final List<dynamic> results = response['results'];
        notifications.value =
            results.map((json) => NotificationModel.fromJson(json)).toList();
        _updateUnreadCount();
        print('✅ Fetched ${notifications.length} notifications');
      }
    } catch (e) {
      print('⚠️ Fetch error: $e');
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final index = notifications.indexWhere((n) => n.id == id);
      if (index == -1) return false;

      final original = notifications[index];
      if (original.isRead) return true;

      notifications[index] = original.copyWith(isRead: true);
      notifications.refresh();
      _updateUnreadCount();

      final success = await _attemptMarkAsReadAPI(id);

      if (!success) {
        notifications[index] = original;
        notifications.refresh();
        _updateUnreadCount();
      }

      return success;
    } catch (e) {
      print('⚠️ Mark read error: $e');
      return false;
    }
  }

  Future<bool> _attemptMarkAsReadAPI(int id) async {
    final attempts = [
      {
        'url': "${ApiConstants.baseUrl}/api/notifications/list/$id/",
        'method': 'PATCH',
        'body': {'is_read': true}
      },
    ];

    for (final attempt in attempts) {
      try {
        dynamic response;
        if (attempt['method'] == 'PATCH') {
          final String url = attempt['url'] as String;  // Explicit cast to String
          final Map<String, dynamic> body = attempt['body'] as Map<String, dynamic>;
          response = await NetworkApiServices.patchApi(
            url,
            body,
            withAuth: true,
            tokenType: 'login',
          ).timeout(Duration(seconds: 5));
        }

        if (response != null) {
          print('✅ Marked as read');
          return true;
        }
      } catch (e) {
        print('⚠️ Attempt failed: $e');
        continue;
      }
    }

    return false;
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  @override
  void onClose() {
    print('🧹 Cleaning up');
    _shouldStayConnected = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    disconnectWebSocket();
    super.onClose();
  }
}
///right as ai ///
// class NotificationModel {
//   final int id;
//   final String title;
//   final String message;
//   final String notificationType;
//   final bool isRead;
//   final Map<String, dynamic> data;
//   final String? sentAt;
//   final String createdAt;
//
//   NotificationModel({
//     required this.id,
//     required this.title,
//     required this.message,
//     required this.notificationType,
//     required this.isRead,
//     required this.data,
//     this.sentAt,
//     required this.createdAt,
//   });
//
//   factory NotificationModel.fromJson(Map<String, dynamic> json) {
//     try {
//       return NotificationModel(
//         id: json['id'] ?? 0,
//         title: json['title'] ?? 'Notification',
//         message: json['message'] ?? '',
//         notificationType: json['notification_type'] ?? 'general',
//         isRead: json['is_read'] ?? false,
//         data: Map<String, dynamic>.from(json['data'] ?? {}),
//         sentAt: json['sent_at'],
//         createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
//       );
//     } catch (e) {
//       return NotificationModel(
//         id: json['id'] ?? 0,
//         title: 'Error',
//         message: 'Unable to load',
//         notificationType: 'error',
//         isRead: false,
//         data: {},
//         createdAt: DateTime.now().toIso8601String(),
//       );
//     }
//   }
//
//   NotificationModel copyWith({bool? isRead}) {
//     return NotificationModel(
//       id: id,
//       title: title,
//       message: message,
//       notificationType: notificationType,
//       isRead: isRead ?? this.isRead,
//       data: data,
//       sentAt: sentAt,
//       createdAt: createdAt,
//     );
//   }
// }

// Enhanced Notification Model with better validation
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final Map<String, dynamic> data;
  final String? sentAt;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.data,
    this.sentAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? 'Notification',
        message: json['message'] ?? '',
        notificationType: json['notification_type'] ?? 'general',
        isRead: json['is_read'] ?? false,
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        sentAt: json['sent_at'],
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('❌ Error parsing notification JSON: $e');
      // Return a default notification if parsing fails
      return NotificationModel(
        id: json['id'] ?? 0,
        title: 'Error Loading Notification',
        message: 'Unable to load notification content',
        notificationType: 'error',
        isRead: false,
        data: {},
        createdAt: DateTime.now().toIso8601String(),
      );
    }
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? notificationType,
    bool? isRead,
    Map<String, dynamic>? data,
    String? sentAt,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timeAgo {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get formatted date for display
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today ${_formatTime(dateTime)}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${_formatTime(dateTime)}';
      } else if (difference.inDays < 7) {
        return '${_getDayName(dateTime.weekday)} ${_formatTime(dateTime)}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// FIXED: Check if notification has action data
  bool get hasAction => data.containsKey('action') && data['action'] != null;

  /// FIXED: Get action type from data - handle both string and object formats
  String? get actionType {
    if (data['action'] is String) {
      return data['action'];
    } else if (data['action'] is Map) {
      return data['action']['type'];
    }
    return null;
  }

  /// Get action URL from data
  String? get actionUrl {
    if (data['action'] is Map) {
      return data['action']['url'];
    }
    return null;
  }

  /// Convert to JSON for storage or transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'is_read': isRead,
      'data': data,
      'sent_at': sentAt,
      'created_at': createdAt,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, isRead: $isRead, type: $notificationType)';
  }
}