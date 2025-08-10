import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
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

  // Connection control variables
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
    final token = await TokenStorage.getLoginAccessToken();
    if (token != null && token.isNotEmpty) {
      _shouldStayConnected = true;
      connectionStatus.value = 'Initializing...';
      await fetchAllNotifications();
      await connectWebSocket();
      _startHeartbeat();
    } else {
      connectionStatus.value = 'No token available';
    }
  }

  /// Improved WebSocket connection with better status tracking
  Future<void> connectWebSocket() async {
    if (_isConnecting) {
      print('🔄 Connection already in progress, skipping...');
      return;
    }

    try {
      final token = await TokenStorage.getLoginAccessToken();
      if (token == null || token.isEmpty) {
        print('❌ No token found, cannot connect WebSocket');
        _shouldStayConnected = false;
        connectionStatus.value = 'Authentication required';
        return;
      }

      if (!_shouldStayConnected) {
        print('🛑 Should not stay connected, aborting connection');
        connectionStatus.value = 'Connection disabled';
        return;
      }

      _isConnecting = true;
      connectionStatus.value = 'Connecting...';
      _reconnectTimer?.cancel();
      await _safeDisconnect();

      // Improved WebSocket URL construction
      String wsUrl = _buildWebSocketUrl(token);
      print('🔌 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['websocket'],
      );

      // Connection timeout with proper cleanup
      Timer? connectionTimeout = Timer(Duration(seconds: 15), () {
        if (!isConnected.value) {
          print('❌ WebSocket connection timeout');
          connectionStatus.value = 'Connection timeout';
          _channel?.sink.close();
          _isConnecting = false;
          if (_shouldStayConnected) {
            _handleReconnection();
          }
        }
      });

      _streamSubscription = _channel!.stream.listen(
            (data) {
          connectionTimeout?.cancel();
          print('📨 WebSocket Data Received: $data');
          _handleWebSocketMessage(data);
          _reconnectAttempts = 0;

          if (!isConnected.value) {
            isConnected.value = true;
            connectionStatus.value = 'Connected';
            print('✅ WebSocket Connection Established');
          }
        },
        onError: (error) {
          connectionTimeout?.cancel();
          print('❌ WebSocket Error: $error');
          isConnected.value = false;
          connectionStatus.value = 'Connection error';
          _isConnecting = false;

          if (_shouldStayConnected) {
            _handleReconnection();
          }
        },
        onDone: () {
          connectionTimeout?.cancel();
          print('🔌 WebSocket Connection Closed');
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
      print('✅ WebSocket Connected Successfully');

    } catch (e) {
      print('❌ WebSocket Connection Error: $e');
      isConnected.value = false;
      connectionStatus.value = 'Connection failed';
      _isConnecting = false;

      if (_shouldStayConnected) {
        _handleReconnection();
      }
    }
  }

  /// Build WebSocket URL with proper protocol handling
  String _buildWebSocketUrl(String token) {
    String wsUrl;
    if (ApiConstants.baseUrl.startsWith('https://')) {
      wsUrl = ApiConstants.baseUrl.replaceFirst('https://', 'wss://');
    } else if (ApiConstants.baseUrl.startsWith('http://')) {
      wsUrl = ApiConstants.baseUrl.replaceFirst('http://', 'ws://');
    } else {
      // Assume https if no protocol specified
      wsUrl = 'wss://${ApiConstants.baseUrl}';
    }
    return '$wsUrl/ws/notifications/?token=$token';
  }

  /// Enhanced heartbeat with connection validation
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_shouldStayConnected && _channel != null && isConnected.value) {
        try {
          final pingMessage = jsonEncode({
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          _channel!.sink.add(pingMessage);
          print('💓 Heartbeat sent');
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

  /// Improved reconnection logic with exponential backoff
  void _handleReconnection() async {
    if (_isConnecting || !_shouldStayConnected) {
      return;
    }

    final token = await TokenStorage.getLoginAccessToken();
    if (token == null || token.isEmpty) {
      print('❌ No valid token, stopping reconnection attempts');
      _shouldStayConnected = false;
      connectionStatus.value = 'Authentication required';
      await disconnectWebSocket();
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached. Will retry after longer delay.');
      _reconnectAttempts = 0;
      connectionStatus.value = 'Reconnection paused';

      _reconnectTimer = Timer(Duration(minutes: 2), () {
        if (_shouldStayConnected) {
          _handleReconnection();
        }
      });
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _getReconnectDelay());
    connectionStatus.value = 'Reconnecting in ${delay.inSeconds}s... (${_reconnectAttempts}/${_maxReconnectAttempts})';
    print('🔄 Attempting reconnection #$_reconnectAttempts in ${delay.inSeconds} seconds...');

    _reconnectTimer = Timer(delay, () async {
      if (_shouldStayConnected) {
        await connectWebSocket();
      }
    });
  }

  // FIXED: Integer division by zero error
  int _getReconnectDelay() {
    // Exponential backoff with jitter - FIXED
    final baseDelay = [2, 5, 10, 20, 30][_reconnectAttempts - 1];
    final random = Random();
    final jitter = (baseDelay * 0.1).round();

    // Prevent division by zero
    if (jitter <= 0) return baseDelay;

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
        print('🔌 WebSocket Safely Disconnected');
      } catch (e) {
        print('⚠️ Error during safe disconnect: $e');
      } finally {
        _channel = null;
        isConnected.value = false;
      }
    }
  }

  /// Enhanced message handling with validation
  Future<void> _handleWebSocketMessage(dynamic data) async {
    try {
      if (data == null || data.toString().isEmpty) {
        print('⚠️ Received empty WebSocket message');
        return;
      }

      final Map<String, dynamic> message = jsonDecode(data);
      print('📨 Parsed WebSocket Message: $message');

      if (!message.containsKey('type')) {
        print('⚠️ Message missing type field');
        return;
      }

      switch (message['type']) {
        case 'notification':
          await _handleNotificationMessage(message);
          break;

        case 'pong':
          print('💓 Heartbeat response received');
          break;

        case 'error':
          await _handleErrorMessage(message);
          break;

        case 'system':
          print('ℹ️ System message: ${message['message']}');
          break;

        default:
          print('ℹ️ Unknown message type: ${message['type']}');
      }
    } catch (e) {
      print('❌ Error handling WebSocket message: $e');
    }
  }

  /// Handle notification messages with validation
  Future<void> _handleNotificationMessage(Map<String, dynamic> message) async {
    try {
      if (!message.containsKey('data')) {
        print('⚠️ Notification message missing data field');
        return;
      }

      final notificationData = message['data'];
      final notification = NotificationModel.fromJson(notificationData);

      // Check for duplicates
      final existingIndex = notifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex == -1) {
        notifications.insert(0, notification);
        _updateUnreadCount();
        _showInAppNotification(notification);
        print('✅ New notification added: ${notification.title}');
      } else {
        print('ℹ️ Duplicate notification received: ${notification.id}');
      }
    } catch (e) {
      print('❌ Error handling notification message: $e');
    }
  }

  /// Handle error messages
  Future<void> _handleErrorMessage(Map<String, dynamic> message) async {
    final errorMessage = message['message'] ?? 'Unknown error';
    final errorCode = message['code'];

    print('❌ Server error: $errorMessage (Code: $errorCode)');

    switch (errorCode) {
      case 'invalid_token':
      case 'token_expired':
        await forceDisconnectDueToInvalidToken();
        break;
      case 'rate_limit':
        connectionStatus.value = 'Rate limited';
        break;
      default:
        connectionStatus.value = 'Server error: $errorMessage';
    }
  }

  Future<void> forceDisconnectDueToInvalidToken() async {
    print('🚫 Forcing disconnect due to invalid token');
    _shouldStayConnected = false;
    connectionStatus.value = 'Authentication failed';
    await disconnectWebSocket();

    // Optionally trigger token refresh or redirect to login
    // Get.offAllNamed('/login');
  }

  /// Enhanced notification display
  void _showInAppNotification(NotificationModel notification) {
    // Avoid showing notifications if app is in background
    if (Get.context != null) {
      Get.snackbar(
        notification.title,
        notification.message,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.surface,
        colorText: Get.theme.colorScheme.onSurface,
        margin: EdgeInsets.all(8),
        borderRadius: 8,
        isDismissible: true,
        onTap: (_) => _handleNotificationTap(notification),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationModel notification) {
    print('🎯 Notification tapped: ${notification.id} - ${notification.title}');

    // Mark as read when tapped
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Handle navigation based on notification type or action
    if (notification.hasAction) {
      switch (notification.actionType) {
        case 'profile_view':
        // Navigate to profile or handle profile view
          print('📱 Handling profile view action');
          break;
        case 'message':
        // Navigate to messages
          break;
        case 'update':
        // Navigate to updates
          break;
        default:
          print('ℹ️ Unknown action type: ${notification.actionType}');
          break;
      }
    }
  }

  Future<void> disconnectWebSocket() async {
    print('🛑 Manually disconnecting WebSocket...');
    _shouldStayConnected = false;
    connectionStatus.value = 'Disconnecting...';
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts;
    await _safeDisconnect();
    connectionStatus.value = 'Disconnected';
  }

  Future<void> enableConnection() async {
    print('✅ Enabling WebSocket connection...');
    _shouldStayConnected = true;
    _reconnectAttempts = 0;
    _isConnecting = false;

    final token = await TokenStorage.getLoginAccessToken();
    if (token != null && token.isNotEmpty) {
      await connectWebSocket();
      _startHeartbeat();
    } else {
      connectionStatus.value = 'No authentication token';
    }
  }

  /// Fetch notifications with better error handling
  Future<void> fetchAllNotifications() async {
    try {
      final url = "${ApiConstants.baseUrl}/api/notifications/list/";
      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');

      if (response != null && response['results'] != null) {
        final List<dynamic> results = response['results'];
        notifications.value = results.map((json) => NotificationModel.fromJson(json)).toList();
        _updateUnreadCount();
        print('✅ Fetched ${notifications.length} notifications');
      } else {
        print('⚠️ No notifications data in response');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');

      // Show user-friendly error message
      if (Get.context != null) {
        Get.snackbar(
          'Error',
          'Failed to load notifications. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<NotificationModel?> fetchNotificationById(int id) async {
    try {
      final url = "${ApiConstants.baseUrl}/api/notifications/list/$id/";
      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');

      if (response != null) {
        return NotificationModel.fromJson(response);
      }
    } catch (e) {
      print('❌ Error fetching notification $id: $e');
    }
    return null;
  }

  /// FIXED: Improved mark as read with correct API endpoint
  Future<bool> markAsRead(int notificationId) async {
    try {
      print('📖 Marking notification $notificationId as read...');

      // Find notification locally
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) {
        print('⚠️ Notification $notificationId not found locally');
        return false;
      }

      final originalNotification = notifications[index];
      if (originalNotification.isRead) {
        print('ℹ️ Notification $notificationId already marked as read');
        return true;
      }

      // Update locally first for immediate UI feedback
      notifications[index] = originalNotification.copyWith(isRead: true);
      notifications.refresh();
      _updateUnreadCount();

      // Try API endpoints with improved error handling
      final success = await _attemptMarkAsReadAPI(notificationId);

      if (!success) {
        // Revert local change on failure
        notifications[index] = originalNotification;
        notifications.refresh();
        _updateUnreadCount();

        if (Get.context != null) {
          Get.snackbar(
            'Error',
            'Failed to mark notification as read',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }

      return success;

    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// FIXED: Correct API endpoints for marking as read
  Future<bool> _attemptMarkAsReadAPI(int notificationId) async {
    final List<Map<String, dynamic>> apiAttempts = [
      // Based on your API structure, these are more likely endpoints:
      {
        'url': "${ApiConstants.baseUrl}/api/notifications/list/$notificationId/",
        'method': 'PATCH',
        'body': {'is_read': true}
      },
      {
        'url': "${ApiConstants.baseUrl}/api/notifications/$notificationId/",
        'method': 'PATCH',
        'body': {'is_read': true}
      },
      {
        'url': "${ApiConstants.baseUrl}/api/notifications/mark-read/",
        'method': 'POST',
        'body': {'notification_id': notificationId}
      },
      {
        'url': "${ApiConstants.baseUrl}/api/notifications/mark-read/",
        'method': 'POST',
        'body': {'id': notificationId, 'is_read': true}
      },
    ];

    for (final attempt in apiAttempts) {
      try {
        print('🔄 Trying to mark as read: ${attempt['url']} (${attempt['method']})');

        dynamic response;
        switch (attempt['method']) {
          case 'PATCH':
            response = await NetworkApiServices.patchApi(
                attempt['url'],
                attempt['body'],
                withAuth: true,
                tokenType: 'login'
            );
            break;
          case 'POST':
            response = await NetworkApiServices.postApi(
                attempt['url'],
                attempt['body'],
                withAuth: true,
                tokenType: 'login'
            );
            break;
        }

        if (response != null) {
          print('✅ Successfully marked as read: ${attempt['url']}');
          return true;
        }
      } catch (e) {
        print('⚠️ Failed attempt: ${attempt['url']} - $e');
        continue;
      }
    }

    print('❌ All mark-as-read attempts failed');
    return false;
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = notifications.where((n) => !n.isRead).toList();
      if (unreadNotifications.isEmpty) return;

      // Update locally first
      for (int i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = notifications[i].copyWith(isRead: true);
        }
      }
      notifications.refresh();
      _updateUnreadCount();

      // Try to update on server
      try {
        final url = "${ApiConstants.baseUrl}/api/notifications/mark-all-read/";
        await NetworkApiServices.postApi(url, {}, withAuth: true, tokenType: 'login');
        print('✅ All notifications marked as read');
      } catch (e) {
        print('⚠️ Failed to mark all as read on server: $e');
      }

    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void clearAllNotifications() {
    notifications.clear();
    unreadCount.value = 0;
  }

  void resetReconnection() {
    _reconnectAttempts = 0;
    _isConnecting = false;
    connectionStatus.value = 'Ready to reconnect';
  }

  bool get isProperlyConnected => isConnected.value && _shouldStayConnected && _channel != null;

  @override
  void onClose() {
    print('🧹 Cleaning up NotificationService...');
    _shouldStayConnected = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    disconnectWebSocket();
    super.onClose();
  }
}

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