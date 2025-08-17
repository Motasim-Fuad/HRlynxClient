import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart';
import 'package:hr/app/api_servies/token.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMeg {
  final msgService = FirebaseMessaging.instance;

  // ✅ Local Notifications Plugin - ADDED
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  initFCM() async {
    try {
      // ✅ Initialize local notifications - ADDED
      await initializeLocalNotifications();

      // Request permission
      NotificationSettings settings = await msgService.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');

        // Get FCM token
        String? token = await msgService.getToken();

        if (token != null) {
          print("FCM token: $token");
          await sendTokenToBackend(token);
        }

        // Token refresh listener
        msgService.onTokenRefresh.listen((newToken) {
          print("Token refreshed: $newToken");
          sendTokenToBackend(newToken);
        });
      } else {
        print('User declined or has not accepted permission');
      }

      // ✅ Handle background messages - UPDATED
      FirebaseMessaging.onBackgroundMessage(handleBackgroundNotification);

      // ✅ Handle foreground messages - UPDATED
      FirebaseMessaging.onMessage.listen(handleForegroundNotification);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationTap);

      // Handle initial message
      handleInitialMessage();
    } catch (e) {
      print("Error initializing FCM: $e");
    }
  }

  // ✅ Initialize Local Notifications - NEW FUNCTION
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    // ✅ Create notification channel for Android - IMPORTANT
    await createNotificationChannel();
  }

  // ✅ Create Notification Channel - NEW FUNCTION
  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // Same as in AndroidManifest
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Backend এ FCM token পাঠানোর function
  Future<void> sendTokenToBackend(String token) async {
    final accessToken = await TokenStorage.getLoginAccessToken();
    try {
      String deviceType = Platform.isAndroid ? 'android' : 'ios';
      String apiUrl = "${ApiConstants.baseUrl}/api/notifications/fcm-tokens/";

      Map<String, dynamic> requestBody = {
        "token": token,
        "device_type": deviceType,
      };

      print("Sending token to backend...");
      print("URL: $apiUrl");
      print("Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 400 &&
          response.body.contains("already exists")) {
        print('✅ Token already exists in backend, skipping insert.');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Token successfully sent to backend");
      } else if (response.statusCode == 400) {
        Map<String, dynamic> errorData = jsonDecode(response.body);
        if (errorData['errors'] != null &&
            errorData['errors']['token'] != null &&
            errorData['errors']['token'].toString().contains('already exists')) {
          print("⚠️ Token already exists in backend");
        } else {
          print("❌ Validation Error: ${errorData['message']}");
        }
      } else {
        print("❌ Failed to send token. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error sending token to backend: $e");
      _showSnackbarSafely(
        title: "Network Error",
        message: "Failed to connect to server",
        backgroundColor: Colors.red,
      );
    }
  }

  // ✅ Handle foreground notifications - UPDATED
  Future<void> handleForegroundNotification(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // ✅ Show local notification when app is in foreground
    await showLocalNotification(message);

    // Also show snackbar
    _showSnackbarSafely(
      title: message.notification?.title ?? "Notification",
      message: message.notification?.body ?? "New message received",
      backgroundColor: Colors.blue,
      onTap: () => handleNotificationTap(message),
    );
  }

  // ✅ Show Local Notification - NEW FUNCTION
  Future<void> showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  // ✅ Handle notification tap from local notifications - NEW FUNCTION
  void onNotificationTap(NotificationResponse notificationResponse) {
    print('Local notification tapped');

    if (notificationResponse.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(notificationResponse.payload!);
        handleNotificationData(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle notification tap
  Future<void> handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    handleNotificationData(message.data);
  }

  // ✅ Handle notification data - NEW FUNCTION
  void handleNotificationData(Map<String, dynamic> data) {
    if (data.isNotEmpty) {
      String? screen = data['screen'];
      String? id = data['id'];

      if (screen != null) {
        // Navigate to specific screen
        // Get.toNamed('/screen_name', arguments: {'id': id});
        print('Should navigate to: $screen with id: $id');
      }
    }
  }

  // Handle initial message
  Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.messageId}');
      handleNotificationTap(initialMessage);
    }
  }

  // Manual token refresh function
  Future<void> refreshAndSendToken() async {
    try {
      await msgService.deleteToken();
      String? newToken = await msgService.getToken();

      if (newToken != null) {
        print("New token generated: $newToken");
        await sendTokenToBackend(newToken);
      }
    } catch (e) {
      print("Error refreshing token: $e");
    }
  }

  // Safe snackbar function
  void _showSnackbarSafely({
    required String title,
    required String message,
    required Color backgroundColor,
    VoidCallback? onTap,
  }) {
    try {
      if (Get.context != null) {
        Get.showSnackbar(
          GetSnackBar(
            title: title,
            message: message,
            backgroundColor: backgroundColor,
            duration: Duration(seconds: 3),
            onTap: onTap != null ? (snack) => onTap() : null,
            snackPosition: SnackPosition.TOP,
          ),
        );
      } else {
        Future.delayed(Duration(milliseconds: 500), () {
          if (Get.context != null) {
            Get.showSnackbar(
              GetSnackBar(
                title: title,
                message: message,
                backgroundColor: backgroundColor,
                duration: Duration(seconds: 3),
                onTap: onTap != null ? (snack) => onTap() : null,
              ),
            );
          } else {
            print("Snackbar: $title - $message (Context not available)");
          }
        });
      }
    } catch (e) {
      print("Snackbar Error: $e");
      print("Snackbar: $title - $message");
    }
  }
}

// ✅ Background message handler - UPDATED
@pragma('vm:entry-point')
Future<void> handleBackgroundNotification(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');

  // ✅ Background এ local notification show করার জন্য - ADDED
  // Note: Background এ local notification automatically handle হয়
}