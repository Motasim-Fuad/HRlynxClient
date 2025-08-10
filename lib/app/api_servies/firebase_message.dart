import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart';
import 'package:hr/app/api_servies/token.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class FirebaseMeg {
  final msgService = FirebaseMessaging.instance;


  initFCM() async {
    try {
      // Request permission
      NotificationSettings settings = await msgService.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');

        // Get FCM token
        String? token = await msgService.getToken();

        if (token != null) {
          print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@  FCM  token: $token");

          // Backend এ token পাঠান
          await sendTokenToBackend(token);
        }

        // Token refresh হলে backend এ update করুন
        msgService.onTokenRefresh.listen((newToken) {
          print("Token refreshed: $newToken");
          sendTokenToBackend(newToken);
        });

      } else {
        print('User declined or has not accepted permission');
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(handleBackgroundNotification);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(handleForegroundNotification);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationTap);

      // Handle initial message
      handleInitialMessage();

    } catch (e) {
      print("Error initializing FCM: $e");
    }
  }

  // Backend এ FCM token পাঠানোর function
  Future<void> sendTokenToBackend(String token) async {
    final accessToken = await TokenStorage.getLoginAccessToken();
    try {
      // Device type detect করুন
      String deviceType = Platform.isAndroid ? 'android' : 'ios';

      // API endpoint
      String apiUrl = "${ApiConstants.baseUrl}/api/notifications/fcm-tokens/";

      // Request body
      Map<String, dynamic> requestBody = {
        "token": token,
        "device_type": deviceType,
      };

      print("Sending token to backend...");
      print("URL: $apiUrl");
      print("Body: ${jsonEncode(requestBody)}");

      // HTTP POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          // যদি authentication লাগে তাহলে এখানে add করুন
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      if (response.statusCode == 400 && response.body.contains("already exists")) {
        print('✅ Token already exists in backend, skipping insert.  its not a error');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        print("✅ Token successfully sent to backend");

        // Success snackbar show করুন (safely)
        _showSnackbarSafely(
          title: "Success",
          message: "FCM Token registered successfully",
          backgroundColor: Colors.green,
        );

      } else if (response.statusCode == 400) {
        Map<String, dynamic> errorData = jsonDecode(response.body);

        // Check if token already exists
        if (errorData['errors'] != null &&
            errorData['errors']['token'] != null &&
            errorData['errors']['token'].toString().contains('already exists')) {
          print("⚠️ Token already exists in backend");

          // Token already exists - you might want to update it
          // অথবা simply ignore করতে পারেন

        } else {
          print("❌ Validation Error: ${errorData['message']}");
          _showSnackbarSafely(
            title: "Validation Error",
            message: errorData['message'] ?? "Unknown validation error",
            backgroundColor: Colors.orange,
          );
        }

      } else {
        print("❌ Failed to send token. Status: ${response.statusCode}");
        _showSnackbarSafely(
          title: "Error",
          message: "Failed to register FCM token",
          backgroundColor: Colors.red,
        );
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

  // Handle foreground notifications
  Future<void> handleForegroundNotification(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // Custom UI notification show করুন (safely)
    _showSnackbarSafely(
      title: message.notification?.title ?? "Notification",
      message: message.notification?.body ?? "New message received",
      backgroundColor: Colors.blue,
      onTap: () => handleNotificationTap(message),
    );
  }

  // Handle notification tap
  Future<void> handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');

    // Data থেকে navigation information পেতে পারেন
    if (message.data.isNotEmpty) {
      // Example: Navigate based on data
      String? screen = message.data['screen'];
      String? id = message.data['id'];

      if (screen != null) {
        // Navigate to specific screen
        // Get.toNamed('/screen_name', arguments: {'id': id});
        print('Should navigate to: $screen with id: $id');
      }
    }
  }

  // Handle initial message
  Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.messageId}');
      // Handle the initial message
      handleNotificationTap(initialMessage);
    }
  }

  // Manual token refresh function (যদি প্রয়োজন হয়)
  Future<void> refreshAndSendToken() async {
    try {
      await msgService.deleteToken(); // পুরানো token delete করুন
      String? newToken = await msgService.getToken(); // নতুন token get করুন

      if (newToken != null) {
        print("New token generated: $newToken");
        await sendTokenToBackend(newToken);
      }
    } catch (e) {
      print("Error refreshing token: $e");
    }
  }

  // Safe snackbar function to avoid context errors
  void _showSnackbarSafely({
    required String title,
    required String message,
    required Color backgroundColor,
    VoidCallback? onTap,
  }) {
    try {
      // Check if Get context is ready
      if (Get.context != null) {
        Get.showSnackbar(
          GetSnackBar(
            title: title,
            message: message,
            backgroundColor: backgroundColor,
            duration: Duration(seconds: 3),
            onTap: onTap != null ? (snack) => onTap() : null,
            snackPosition:SnackPosition.TOP ,
          ),

        );
      } else {
        // If context not ready, delay and try again
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

// Background message handler
@pragma('vm:entry-point')
Future<void> handleBackgroundNotification(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}