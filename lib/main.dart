
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hr/app/api_servies/firebase_message.dart';
import 'app/SplashServices.dart';
import 'app/api_servies/notification_services.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,

  );

  await FirebaseMeg().initFCM();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Stripe.publishableKey = 'pk_test_51RVMTHQU9tGM4LXBf8ZHLjC18DYzzWu4HnxSCojMGP58ZO8x1K2sFbNZ5xGLmIRt6KjZpo77V0RKs4m6dwoxoFLi00u06pnafX';

  try {
    await Stripe.instance.applySettings();
    print('✅ Stripe initialized successfully');
  } catch (e) {
    print('❌ Stripe initialization error: $e');
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
