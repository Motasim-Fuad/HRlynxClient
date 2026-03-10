// lib/main.dart - FINAL PRODUCTION

import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'app/SplashServices.dart';
import 'app/api_servies/firebase_message.dart';
import 'app/api_servies/notification_services.dart';
import 'app/api_servies/token.dart';
import 'app/modules/payment/payment_controller.dart';

// ─── Background FCM handler (must be top-level) ───────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.messageId}');
}

// ─────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────

void main() {
  // ✅ runZonedGuarded আগে, ensureInitialized ভেতরে
  runZonedGuarded(
        () async {
      WidgetsFlutterBinding.ensureInitialized(); // ← এখানে move করো

      await _loadEnv();
      await _initializeFirebase();
      _setupCrashlytics();

      await Future.wait([
        _configureUI(),
        _initializeRevenueCat(),
        _initializeFCM(),
      ]);

      if (Platform.isIOS) _requestIOSPermissionsAsync();

      debugPrint('✅ All systems ready');
      runApp(const MyApp());
    },
        (error, stack) {
      debugPrint('❌ UNCAUGHT ERROR: $error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

// ─────────────────────────────────────────────────────────────
//  INIT HELPERS
// ─────────────────────────────────────────────────────────────

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env')
        .timeout(const Duration(seconds: 5));
    debugPrint('✅ .env loaded');
  } catch (e) {
    debugPrint('⚠️ .env error: $e');
  }
}

Future<void> _initializeFirebase() async {
  for (int i = 0; i < 3; i++) {
    try {
      await Firebase.initializeApp()
          .timeout(const Duration(seconds: 15));

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      debugPrint('✅ Firebase initialized');
      return;
    } catch (e) {
      debugPrint('⚠️ Firebase attempt ${i + 1} failed: $e');
      if (i < 2) await Future.delayed(const Duration(seconds: 2));
    }
  }
  debugPrint('⚠️ Firebase failed after 3 attempts – continuing');
}

void _setupCrashlytics() {
  try {
    // Flutter framework errors
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Async / platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('✅ Crashlytics ready');
  } catch (e) {
    debugPrint('⚠️ Crashlytics setup error: $e');
  }
}

Future<void> _configureUI() async {
  try {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:        Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    debugPrint('✅ UI configured');
  } catch (e) {
    debugPrint('⚠️ UI error: $e');
  }
}

Future<void> _initializeRevenueCat() async {
  try {
    await Purchases.setLogLevel(LogLevel.debug);

    final apiKey = Platform.isIOS
        ? (dotenv.env['IOS_REVENUECAT_KEY']     ?? '')
        : (dotenv.env['ANDROID_REVENUECAT_KEY'] ?? '');

    if (apiKey.isEmpty) throw Exception('RevenueCat key not found in .env');

    await Purchases.configure(PurchasesConfiguration(apiKey))
        .timeout(const Duration(seconds: 10));

    debugPrint('✅ RevenueCat initialized');
  } catch (e) {
    debugPrint('⚠️ RevenueCat error: $e');
    FirebaseCrashlytics.instance
        .recordError(e, StackTrace.current, reason: '_initializeRevenueCat');
  }
}

Future<void> _initializeFCM() async {
  try {
    await FirebaseMeg().initFCM()
        .timeout(const Duration(seconds: 8));
    debugPrint('✅ FCM initialized');
  } catch (e) {
    debugPrint('⚠️ FCM error: $e');
  }
}

void _requestIOSPermissionsAsync() {
  Future.microtask(() async {
    try {
      final settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 30));

      debugPrint('✅ Permission: ${settings.authorizationStatus}');

      final isAllowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAllowed) return;

      // APNs token – retry up to 5 times
      for (int i = 0; i < 5; i++) {
        final token = await FirebaseMessaging.instance.getAPNSToken();
        if (token != null) {
          debugPrint('✅ APNs token received');
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('⚠️ iOS permission error: $e');
    }
  });
}

// ─────────────────────────────────────────────────────────────
//  APP ROOT
// ─────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title:                    'HRlynx',
      debugShowCheckedModeBanner: false,
      home:                     const _SafeInitScreen(),
      builder: (context, child) {
        // Global error UI
        ErrorWidget.builder = (details) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please restart the app',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
        return child!;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SAFE INIT SCREEN  (splash-time initialisation)
// ─────────────────────────────────────────────────────────────

class _SafeInitScreen extends StatefulWidget {
  const _SafeInitScreen();

  @override
  State<_SafeInitScreen> createState() => _SafeInitScreenState();
}

class _SafeInitScreenState extends State<_SafeInitScreen>
    with WidgetsBindingObserver {

  bool   _showRetry = false;
  String _status    = 'Loading...';

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  // ── Init ───────────────────────────────────────────────────
  Future<void> _initialize() async {
    if (mounted) setState(() { _showRetry = false; _status = 'Loading...'; });

    try {
      // Small delay so the first frame paints before heavy work
      await Future.delayed(const Duration(milliseconds: 200));

      // Init NotificationService early (non-blocking)
      _initNotificationsAsync();

      await SplashService().checkLoginStatus().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Login check timed out'),
      );

    } catch (e, st) {
      debugPrint('❌ Init error: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: '_SafeInitScreen._initialize');

      if (mounted) setState(() { _showRetry = true; _status = 'Loading...'; });
    }
  }

  // ── Notifications (fire-and-forget) ───────────────────────
  void _initNotificationsAsync() {
    Future.microtask(() async {
      try {
        if (!Get.isRegistered<NotificationService>()) {
          Get.put(NotificationService());
        }
      } catch (e) {
        debugPrint('⚠️ Notification init error: $e');
      }
    });
  }

  // ── App resume: check subscription silently ────────────────
  Future<void> _onAppResumed() async {
    try {
      final token = await TokenStorage.getLoginAccessToken()
          .timeout(const Duration(seconds: 3));
      if (token == null) return;

      if (!Get.isRegistered<PaymentController>()) return;

      final controller = Get.find<PaymentController>();
      await controller.getCustomerInfo()
          .timeout(const Duration(seconds: 5));

      if (controller.hasActiveSubscription) {
        final flag = await TokenStorage.getSubscriptionCheckDone();
        if (flag != true) {
          await TokenStorage.saveSubscriptionCheckDone(true);
          debugPrint('✅ Subscription flag synced on resume');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Resume check error: $e');
    }
  }

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width:  48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _status,
              style: TextStyle(
                fontSize:   16,
                color:      Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_showRetry) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _initialize,
                icon:  const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}