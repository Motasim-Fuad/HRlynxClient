import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hr/app/api_servies/firebase_message.dart';
import 'app/SplashServices.dart';
import 'app/api_servies/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await FirebaseMeg().initFCM();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

// iOS notification debug
  if (Platform.isIOS) {
    final settings = await FirebaseMessaging.instance.requestPermission();
    print("🔔 Permission status: ${settings.authorizationStatus}");

    // APNs token check
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print("🍎 APNs immediate check: $apnsToken");
  }



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      onInit: () {
        // Register the notification service
        Get.put(NotificationService());
      },
      title: 'HRlynx',
      debugShowCheckedModeBanner: false,
      home: const InitScreen(),
    );
  }
}

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    SplashService().checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    // Show temporary loading UI while deciding
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}