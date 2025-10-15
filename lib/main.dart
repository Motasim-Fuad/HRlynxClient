// lib/main.dart

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app/SplashServices.dart';
import 'app/api_servies/firebase_message.dart';
import 'app/api_servies/notification_services.dart';
import 'app/api_servies/token.dart';
import 'app/modules/payment/payment_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar color
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Initialize RevenueCat early
  await _initializeRevenueCat();

  // Initialize FCM
  await FirebaseMeg().initFCM();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // iOS specific permissions
  if (Platform.isIOS) {
    final settings = await FirebaseMessaging.instance.requestPermission();
    print("Permission status: ${settings.authorizationStatus}");

    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    print("APNs immediate check: $apnsToken");
  }

  runApp(const MyApp());
}

/// ✅ Initialize RevenueCat
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

    print("✅ RevenueCat initialized successfully");
  } catch (e) {
    print("❌ RevenueCat initialization error: $e");
  }
}

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

/// ✅ IMPROVED: Added WidgetsBindingObserver for app lifecycle
class _InitScreenState extends State<InitScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SplashService().checkLoginStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ CRITICAL: Detect when app resumes from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - checking for pending purchases');
      _checkPendingPurchase();
    }
  }

  /// ✅ NEW: Check if purchase completed while app was in background
  Future<void> _checkPendingPurchase() async {
    try {
      final token = await TokenStorage.getLoginAccessToken();
      if (token == null) {
        print('⚠️ No login token - skipping purchase check');
        return;
      }

      print('🔍 User is logged in - checking subscription status');

      // Check if PaymentController exists
      if (Get.isRegistered<PaymentController>()) {
        final controller = Get.find<PaymentController>();

        // Refresh customer info from RevenueCat
        await controller.getCustomerInfo();

        if (controller.hasActiveSubscription) {
          print('✅ Active subscription found on resume');

          // Update flag if not set
          final flag = await TokenStorage.getSubscriptionCheckDone();
          if (flag != true) {
            await TokenStorage.saveSubscriptionCheckDone(true);
            print('✅ Subscription flag updated on resume');
          }
        } else {
          print('ℹ️ No active subscription found');
        }
      } else {
        print('⚠️ PaymentController not registered yet');
      }
    } catch (e) {
      print('⚠️ Error checking pending purchase on resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}