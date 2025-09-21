import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/api_Constant.dart';
import 'package:hr/app/api_servies/token.dart';
import 'package:hr/app/modules/notification/notification_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMeg {
  final msgService = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  initFCM() async {
    try {
      // Initialize local notifications
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

        // iOS specific setup - শুধু একবার করুন
        if (Platform.isIOS) {
          await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

          // APNs token এর জন্য wait করুন
          await waitForAPNsToken();
        }

        // FCM token get করুন
        String? fcmToken = await msgService.getToken();
        if (fcmToken != null) {
          print("🚀 FCM Token: $fcmToken");
        } else {
          print("❌ Failed to get FCM token");
        }

        // Token refresh listener
        msgService.onTokenRefresh.listen((newToken) {
          print("Token refreshed: $newToken");
          _sendTokenIfLoggedIn(newToken);
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

  // APNs token এর জন্য অপেক্ষা করার function
  Future<void> waitForAPNsToken() async {
    String? apnsToken;
    int attempts = 0;

    while (apnsToken == null && attempts < 15) { // আরো বেশি সময় দিন
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        print("⏳ APNs token এর জন্য wait করছি... ($attempts/15)");
        await Future.delayed(Duration(seconds: 3)); // একটু বেশি সময় দিন
        attempts++;
      }
    }

    if (apnsToken != null) {
      print("✅ APNs Token received: $apnsToken");
    } else {
      print("❌ APNs Token পাওয়া যায়নি");
    }
  }

  // Login এর পর এই method call করুন
  Future<void> sendFCMTokenAfterLogin() async {
    try {
      String? token = await msgService.getToken();
      if (token != null) {
        print("FCM token after login: $token");
        await sendTokenToBackend(token);
      } else {
        print("No FCM token available");
      }
    } catch (e) {
      print("Error getting FCM token after login: $e");
    }
  }

  // Helper function: শুধু logged in user দের জন্য token send করুন
  Future<void> _sendTokenIfLoggedIn(String token) async {
    final accessToken = await TokenStorage.getLoginAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      await sendTokenToBackend(token);
    } else {
      print("User not logged in, skipping token send");
    }
  }

  // Initialize Local Notifications
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: false, // আমরা manually request করবো
      requestBadgePermission: false,
      requestSoundPermission: false,
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

    await createNotificationChannel();
  }

  // Create Notification Channel
  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
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

    if (accessToken == null || accessToken.isEmpty) {
      print("❌ No access token available, cannot send FCM token");
      return;
    }

    try {
      String deviceType = Platform.isAndroid ? 'android' : 'ios';
      String apiUrl = "${ApiConstants.baseUrl}/api/notifications/fcm-tokens/";

      Map<String, dynamic> requestBody = {
        "token": token,
        "device_type": deviceType,
      };

      print("Sending token to backend...");
      print("Device Type: $deviceType"); // এটা নিশ্চিত করুন
      print("Token: $token");

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
    }
  }

  // Handle foreground notifications - iOS এর জন্য local notification show করবে না
  Future<void> handleForegroundNotification(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // iOS এর জন্য local notification show করার দরকার নেই
    // কারণ iOS automatically foreground notification show করে
    if (Platform.isAndroid) {
      await showLocalNotification(message);
    }

    // Snackbar show করুন
    _showSnackbarSafely(
      title: message.notification?.title ?? "Notification",
      message: message.notification?.body ?? "New message received",
      backgroundColor: Colors.blue,
      onTap: () => handleNotificationTap(message),
    );
  }

  // Show Local Notification (শুধু Android এর জন্য)
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

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: null, // iOS এর জন্য null
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  // Handle notification tap from local notifications
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

  // Handle notification data
  void handleNotificationData(Map<String, dynamic> data) {
    String? id = data['id'];
    Get.to(() => NotificationView(), arguments: {'id': id});
    print('Navigated to NotificationView with id: $id');
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
        await _sendTokenIfLoggedIn(newToken);
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
      }
    } catch (e) {
      print("Snackbar Error: $e");
      print("Snackbar: $title - $message");
    }
  }

  // iOS Notification Debug
  Future<void> debugIOSNotifications() async {
    if (!Platform.isIOS) return;

    print("🍎 === iOS Notification Debug ===");

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    print("🍎 Authorization Status: ${settings.authorizationStatus}");
    print("🍎 Alert Setting: ${settings.alert}");
    print("🍎 Badge Setting: ${settings.badge}");
    print("🍎 Sound Setting: ${settings.sound}");

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print("🍎 APNs Token Available: ${apnsToken != null}");
    if (apnsToken != null) {
      print("🍎 APNs Token: $apnsToken");
    } else {
      print("🍎 ❌ NO APNs TOKEN - This is the main problem!");
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    print("🍎 FCM Token: $fcmToken");
  }

  // Test করার জন্য local notification
  Future<void> testLocalNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      '🔥 DIAGNOSTIC TEST',
      'যদি এটা দেখতে পান, iOS notifications কাজ করছে!',
      notificationDetails,
    );

    print("🔥 Local test notification sent - check করুন দেখা যাচ্ছে কিনা");
  }

  // Full diagnostic test
  Future<void> fullNotificationDiagnostic() async {
    print("🔥 === FULL NOTIFICATION DIAGNOSTIC ===");

    // Test 1: Local notification
    print("📱 Testing local notification...");
    await testLocalNotification();

    // Test 2: Check all settings
    await debugIOSNotifications();

    // Test 3: Check handlers
    print("🔥 Foreground message handler ready: ${FirebaseMessaging.onMessage != null}");

    // Test 4: Check backend token format
    print("🔥 Backend expects this token format for iOS:");
    print("🔥 Token: ${await FirebaseMessaging.instance.getToken()}");
    print("🔥 Device type: ios");

    print("🔥 যদি local notification কাজ করে কিন্তু push না করে, backend এর সমস্যা");
    print("🔥 যদি local notification fail করে, iOS setup এর সমস্যা");
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> handleBackgroundNotification(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}