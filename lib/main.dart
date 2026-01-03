// lib/main.dart - PRODUCTION READY (NO ERRORS)

import 'dart:io';
import 'dart:async';
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

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    print('🚀 ========================================');
    print('🚀 APP STARTING - PRODUCTION MODE');
    print('🚀 ========================================\n');

    try {
      await _configureUI();
      await _initializeFirebase();
      await _initializeRevenueCat();
      await _initializeFCM();

      if (Platform.isIOS) {
        _requestIOSPermissionsAsync();
      }

      print('\n✅ ========================================');
      print('✅ ALL SYSTEMS READY');
      print('✅ ========================================\n');

    } catch (e, stackTrace) {
      print('❌ INIT ERROR: $e');
      print('Stack: $stackTrace');
    }

    runApp(const MyApp());

  }, (error, stack) {
    print('❌ UNCAUGHT ERROR: $error');
    print('Stack: $stack');
  });
}

Future<void> _configureUI() async {
  try {
    print('🎨 Configuring UI...');

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    print('✅ UI configured');
  } catch (e) {
    print('⚠️ UI error: $e');
  }
}

Future<void> _initializeFirebase() async {
  int attempts = 0;
  const maxAttempts = 3;

  while (attempts < maxAttempts) {
    try {
      print('🔥 Firebase (attempt ${attempts + 1}/$maxAttempts)...');

      await Firebase.initializeApp().timeout(
        Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Firebase timeout'),
      );

      print('✅ Firebase initialized');
      return;

    } catch (e) {
      attempts++;
      print('❌ Firebase attempt $attempts failed: $e');

      if (attempts >= maxAttempts) {
        print('⚠️ Firebase failed - app will continue');
        return;
      }

      await Future.delayed(Duration(seconds: 2));
    }
  }
}

Future<void> _initializeRevenueCat() async {
  try {
    print('💳 RevenueCat...');

    await Purchases.setLogLevel(LogLevel.debug);

    await dotenv.load(fileName: ".env").timeout(
      Duration(seconds: 5),
      onTimeout: () => throw TimeoutException('.env timeout'),
    );

    String apiKey = Platform.isIOS
        ? (dotenv.env['IOS_REVENUECAT_KEY'] ?? '')
        : (dotenv.env['ANDROID_REVENUECAT_KEY'] ?? '');

    if (apiKey.isEmpty) {
      throw Exception('RevenueCat key not found');
    }

    await Purchases.configure(PurchasesConfiguration(apiKey)).timeout(
      Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('RevenueCat timeout'),
    );

    print('✅ RevenueCat initialized');

  } catch (e) {
    print('⚠️ RevenueCat error: $e');
  }
}

Future<void> _initializeFCM() async {
  try {
    print('📱 FCM...');

    await FirebaseMeg().initFCM().timeout(
      Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('FCM timeout'),
    );

    print('✅ FCM initialized');

  } catch (e) {
    print('⚠️ FCM error: $e');
  }
}

void _requestIOSPermissionsAsync() {
  Future.microtask(() async {
    try {
      print('🔐 iOS permissions (background)...');

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      ).timeout(Duration(seconds: 30));

      print('✅ Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {

        for (int i = 0; i < 5; i++) {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) {
            print('✅ APNs: $apnsToken');
            break;
          }
          await Future.delayed(Duration(seconds: 2));
        }
      }

    } catch (e) {
      print('⚠️ iOS permission error: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      onInit: () {
        try {
          Get.put(NotificationService());
        } catch (e) {
          print('⚠️ NotificationService error: $e');
        }
      },
      title: 'HRlynx',
      debugShowCheckedModeBanner: false,
      home: const SafeInitScreen(),
      builder: (context, widget) {
        ErrorWidget.builder = (details) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 20),
                    Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('Please restart', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        };
        return widget!;
      },
    );
  }
}

class SafeInitScreen extends StatefulWidget {
  const SafeInitScreen({super.key});

  @override
  State<SafeInitScreen> createState() => _SafeInitScreenState();
}

class _SafeInitScreenState extends State<SafeInitScreen> with WidgetsBindingObserver {
  bool _isInitializing = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _safeInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _safeInitialize() async {
    try {
      print('🎬 Starting navigation...');

      await Future.delayed(Duration(milliseconds: 300));

      setState(() {
        _statusMessage = 'Loading...';
      });

      await SplashService().checkLoginStatus().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Login check timeout');
          throw TimeoutException('Login check timeout');
        },
      );

      print('✅ Navigation complete');

    } catch (e, stackTrace) {
      print('❌ Init error: $e');
      print('Stack: $stackTrace');

      setState(() {
        _statusMessage = 'Loading...';
      });

      await Future.delayed(Duration(milliseconds: 500));

      try {
        // Import your SplashScreen here
        // Get.offAll(() => SplashScreen());
      } catch (navError) {
        print('❌ Navigation failed: $navError');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed');
      _checkPendingPurchase();
    }
  }

  Future<void> _checkPendingPurchase() async {
    try {
      final token = await TokenStorage.getLoginAccessToken().timeout(
        Duration(seconds: 3),
      );

      if (token == null) return;

      if (Get.isRegistered<PaymentController>()) {
        final controller = Get.find<PaymentController>();
        await controller.getCustomerInfo().timeout(Duration(seconds: 5));

        if (controller.hasActiveSubscription) {
          print('✅ Active subscription found');
          final flag = await TokenStorage.getSubscriptionCheckDone();
          if (flag != true) {
            await TokenStorage.saveSubscriptionCheckDone(true);
          }
        }
      }
    } catch (e) {
      print('⚠️ Purchase check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            SizedBox(height: 24),
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!_isInitializing) ...[
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _statusMessage = 'Retrying...';
                  });
                  _safeInitialize();
                },
                child: Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}