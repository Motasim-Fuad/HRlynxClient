// lib/app/api_servies/notification_services.dart - FIXED WITH DEDUPLICATION

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

  // ✅ Track notification IDs to prevent duplicates
  final Set<int> _notificationIds = {};

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

      // ✅ FIXED: Using ApiConstants.wsBaseUrl directly — no port:0 issue
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

  // ✅ FIXED: Use ApiConstants.wsBaseUrl directly — eliminates port:0 bug
  String _buildWebSocketUrl(String token) {
    return '${ApiConstants.wsBaseUrl}/ws/notifications/?token=$token';
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
        print('⚠️ Empty WebSocket message received');
        return;
      }

      print('📨📨📨 RAW WebSocket message received: $data');

      final Map<String, dynamic> message = jsonDecode(data);

      if (!message.containsKey('type')) {
        print('⚠️ WebSocket message missing "type" field');
        return;
      }

      print('📋 Message type: ${message['type']}');

      switch (message['type']) {
        case 'notification':
          print('🔔 Processing notification message...');
          await _handleNotificationMessage(message);
          break;
        case 'pong':
          print('💓 Pong received from server');
          break;
        case 'error':
          print('❌ Error message received from server');
          await _handleErrorMessage(message);
          break;
        default:
          print('ℹ️ Unknown message type: ${message['type']}');
      }
    } catch (e, stackTrace) {
      print('❌ Error handling WebSocket message: $e');
      print('📍 Stack trace: $stackTrace');
    }
  }

  // ✅ Handle notification message with deduplication
  Future<void> _handleNotificationMessage(Map<String, dynamic> message) async {
    try {
      if (!message.containsKey('data')) {
        print('⚠️ Missing data in WebSocket message');
        return;
      }

      final notification = NotificationModel.fromJson(message['data']);

      print('📨 WebSocket notification received: ID=${notification.id}, Title="${notification.title}"');

      // ✅ CHECK FOR DUPLICATES USING ID
      if (_notificationIds.contains(notification.id)) {
        print('⚠️⚠️⚠️ DUPLICATE DETECTED! Notification ID ${notification.id} already exists - SKIPPING');
        return;
      }

      // ✅ DOUBLE CHECK: Also check in notifications list
      final existsInList = notifications.any((n) => n.id == notification.id);
      if (existsInList) {
        print('⚠️⚠️⚠️ DUPLICATE DETECTED IN LIST! Notification ID ${notification.id} - SKIPPING');
        return;
      }

      // ✅ ADD TO TRACKING SET
      _notificationIds.add(notification.id);

      // ✅ ADD TO LIST
      notifications.insert(0, notification);
      _updateUnreadCount();

      print('✅✅✅ NEW notification added successfully: ID=${notification.id}, Title="${notification.title}"');
      print('📊 Total notifications: ${notifications.length}, Tracked IDs: ${_notificationIds.length}');

    } catch (e, stackTrace) {
      print('❌ Error handling notification message: $e');
      print('📍 Stack trace: $stackTrace');
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

  // ✅ Fetch with deduplication
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

        // ✅ CLEAR OLD DATA
        notifications.clear();
        _notificationIds.clear();

        // ✅ ADD WITH DEDUPLICATION
        for (var json in results) {
          try {
            final notification = NotificationModel.fromJson(json);

            if (!_notificationIds.contains(notification.id)) {
              _notificationIds.add(notification.id);
              notifications.add(notification);
            } else {
              print('⚠️ Skipping duplicate notification ID: ${notification.id}');
            }
          } catch (e) {
            print('❌ Error parsing notification: $e');
          }
        }

        _updateUnreadCount();
        print('✅ Fetched ${notifications.length} unique notifications (${_notificationIds.length} IDs tracked)');
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
    try {
      final String url = "${ApiConstants.baseUrl}/api/notifications/list/$id/";
      final Map<String, dynamic> body = {'is_read': true};

      final response = await NetworkApiServices.patchApi(
        url,
        body,
        withAuth: true,
        tokenType: 'login',
      ).timeout(Duration(seconds: 5));

      if (response != null) {
        print('✅ Marked as read: $id');
        return true;
      }
      return false;
    } catch (e) {
      print('⚠️ Mark read API failed: $e');
      return false;
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  @override
  void onClose() {
    print('🧹 Cleaning up NotificationService');
    _shouldStayConnected = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _notificationIds.clear();
    notifications.clear();
    disconnectWebSocket();
    super.onClose();
  }
}

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}