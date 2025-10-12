import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Add this
import 'app/SplashServices.dart';
import 'app/api_servies/firebase_message.dart';
import 'app/api_servies/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white, // 🔹 এখানে তুমি চাও যেই রঙ সেট করো
    statusBarIconBrightness: Brightness.dark, // 🔹 আইকনগুলো dark হবে যাতে দেখা যায়
  ));
  await Firebase.initializeApp();

  // Initialize RevenueCat early
  await _initializeRevenueCat();

  await FirebaseMeg().initFCM();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (Platform.isIOS) {
    final settings = await FirebaseMessaging.instance.requestPermission();
    print("Permission status: ${settings.authorizationStatus}");

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print("APNs immediate check: $apnsToken");
  }

  runApp(const MyApp());
}

// Add this function
Future<void> _initializeRevenueCat() async {
  try {
    await Purchases.setLogLevel(LogLevel.debug);

    String apiKey;
    if (Platform.isIOS) {
      apiKey = "appl_DVYOGtnCsySsMcoKkRTVYpJlQZw";
    } else {
      apiKey = "goog_fHaUFeIYngJgHloZDbONohOyWSM";
    }

    PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);

    print("RevenueCat initialized successfully");
  } catch (e) {
    print("RevenueCat initialization error: $e");
  }
}

// Rest of your code remains the same
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      onInit: () {
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}