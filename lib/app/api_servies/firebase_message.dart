// lib/app/api_servies/firebase_message.dart - PRODUCTION READY

import 'package:HRlynx/app/api_servies/api_Constant.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/notification/notification_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMeg {
  final msgService = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initFCM() async {
    try {
      print('📱 ========================================');
      print('📱 INITIALIZING FCM');
      print('📱 ========================================\n');

      // Initialize local notifications with timeout
      await initializeLocalNotifications().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Local notifications timeout');
        },
      );

      // Request permission with timeout
      NotificationSettings settings = await msgService.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Permission request timeout');
          throw TimeoutException('Permission timeout');
        },
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted permission');

        if (Platform.isIOS) {
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

          await waitForAPNsToken();
        }

        String? fcmToken = await msgService.getToken().timeout(
          Duration(seconds: 5),
          onTimeout: () {
            print('⚠️ FCM token fetch timeout');
            return null;
          },
        );

        if (fcmToken != null) {
          print("✅ FCM Token: $fcmToken");
        } else {
          print("⚠️ FCM token not available");
        }

        msgService.onTokenRefresh.listen((newToken) {
          print("Token refreshed: $newToken");
          _sendTokenIfLoggedIn(newToken);
        });
      } else {
        print('ℹ️ Permission denied');
      }

      FirebaseMessaging.onBackgroundMessage(handleBackgroundNotification);
      FirebaseMessaging.onMessage.listen(handleForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(handleNotificationTap);
      handleInitialMessage();

      print('\n✅ FCM READY\n');

    } catch (e) {
      print("⚠️ FCM init error: $e");
    }
  }

  Future<void> waitForAPNsToken() async {
    String? apnsToken;
    int attempts = 0;

    while (apnsToken == null && attempts < 15) {
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        print("⏳ Waiting for APNs ($attempts/15)...");
        await Future.delayed(Duration(seconds: 3));
        attempts++;
      }
    }

    if (apnsToken != null) {
      print("✅ APNs Token: $apnsToken");
    } else {
      print("⚠️ APNs token not available");
    }
  }

  Future<void> sendFCMTokenAfterLogin() async {
    try {
      String? token = await msgService.getToken().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Token fetch timeout');
          return null;
        },
      );

      if (token != null) {
        print("📤 Sending FCM token...");
        await sendTokenToBackend(token);
      } else {
        print("⚠️ No FCM token");
      }
    } catch (e) {
      print("⚠️ FCM token send error: $e");
    }
  }

  Future<void> _sendTokenIfLoggedIn(String token) async {
    final accessToken = await TokenStorage.getLoginAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      await sendTokenToBackend(token);
    } else {
      print("ℹ️ User not logged in");
    }
  }

  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: true,
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

  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Important notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >()
        ?.createNotificationChannel(channel);
  }

  Future<void> sendTokenToBackend(String token) async {
    final accessToken = await TokenStorage.getLoginAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      print("⚠️ No access token");
      return;
    }

    try {
      String deviceType = Platform.isAndroid ? 'android' : 'ios';
      String apiUrl = "${ApiConstants.baseUrl}/api/notifications/fcm-tokens/";

      Map<String, dynamic> requestBody = {
        "token": token,
        "device_type": deviceType,
      };

      print("📤 Sending to backend...");
      print("Device: $deviceType");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Backend send timeout');
          throw TimeoutException('Backend timeout');
        },
      );

      print("Response: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Token sent to backend");
      } else if (response.statusCode == 400) {
        Map<String, dynamic> errorData = jsonDecode(response.body);
        if (errorData['errors'] != null &&
            errorData['errors']['token'] != null &&
            errorData['errors']['token'].toString().contains('already exists')) {
          print("⚠️ Token already exists");
        } else {
          print("⚠️ Validation error: ${errorData['message']}");
        }
      } else {
        print("⚠️ Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Backend send error: $e");
    }
  }

  Future<void> handleForegroundNotification(RemoteMessage message) async {
    print('📨 Foreground: ${message.notification?.title}');

    if (Platform.isAndroid) {
      await showLocalNotification(message);
    }
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Important notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: null,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'New message',
      details,
      payload: jsonEncode(message.data),
    );
  }

  void onNotificationTap(NotificationResponse response) {
    print('📌 Notification tapped');

    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        handleNotificationData(data);
      } catch (e) {
        print('⚠️ Payload parse error: $e');
      }
    }
  }

  Future<void> handleNotificationTap(RemoteMessage message) async {
    print('📌 Notification tapped: ${message.messageId}');
    handleNotificationData(message.data);
  }

  void handleNotificationData(Map<String, dynamic> data) {
    String? id = data['id'];
    Get.to(() => NotificationView(), arguments: {'id': id});
    print('→ NotificationView: $id');
  }

  Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('📌 App opened from notification: ${initialMessage.messageId}');
      handleNotificationTap(initialMessage);
    }
  }

  Future<void> refreshAndSendToken() async {
    try {
      await msgService.deleteToken();
      String? newToken = await msgService.getToken();

      if (newToken != null) {
        print("New token: $newToken");
        await _sendTokenIfLoggedIn(newToken);
      }
    } catch (e) {
      print("⚠️ Token refresh error: $e");
    }
  }
}

@pragma('vm:entry-point')
Future<void> handleBackgroundNotification(RemoteMessage message) async {
  print('📨 Background: ${message.messageId}');
  print('Title: ${message.notification?.title}');
}