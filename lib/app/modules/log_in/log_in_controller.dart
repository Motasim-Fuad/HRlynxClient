// lib/app/modules/log_in/log_in_controller.dart - OPTIMIZED

import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:HRlynx/app/common_widgets/loading_overlay.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class LogInController extends GetxController {
  final userController = Get.put(UserController());
  final AuthRepository authRepo = AuthRepository();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isObscured = true.obs;
  final isChecked = false.obs;
  final isLoading = false.obs;

  late final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    emailController.clear();
    passwordController.clear();
    isChecked.value = false;
  }

  void toggleObscureText() {
    isObscured.value = !isObscured.value;
  }

  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
  }

  /// ✅ OPTIMIZED: Shows loading overlay during login
  Future<void> loginUser() async {
    if (!formKey.currentState!.validate()) return;

    if (!isChecked.value) {
      Get.snackbar(
        "Terms Not Accepted",
        "Please agree to the Terms and Privacy Policy",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      isLoading.value = true;
     // LoadingOverlay.show(message: 'Logging in...');

      // API Call
      final response = await authRepo.login(email, password);

      final data = response['data'];
      final access = data?['access'];
      final refresh = data?['refresh'];
      final user = data?['user'];
      final userid = user?['id'];
      final useremail = user?['email'];

      if (access != null && refresh != null) {
        // Save tokens
      //  LoadingOverlay.updateMessage('Saving session...');
        await TokenStorage.saveLoginTokens(access, refresh);
        await TokenStorage.saveUserEmail(useremail);
        await TokenStorage.saveUserId(userid);

        // Initialize Firebase (non-blocking)
        _initializeFirebaseServices();

        // Set Persona
       // LoadingOverlay.updateMessage('Setting up profile...');
        final storedPersonaId = await TokenStorage.getSelectedPersonaId();
        if (storedPersonaId == null) {
          LoadingOverlay.hide();
          Get.snackbar("Error", "No persona selected. Please complete onboarding first.");
          isLoading.value = false;
          return;
        }

        final personaBody = {"persona": storedPersonaId};
        await authRepo.setParsonaType(personaBody);

        // Navigate via Subscription Manager (it has its own loading)
        LoadingOverlay.hide();
        await SubscriptionManager.instance.handlePostLoginNavigation();

      } else {
        LoadingOverlay.hide();
        Get.snackbar(
          "Failed",
          "Login token missing.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      LoadingOverlay.hide();
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('❌ Login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Non-blocking Firebase initialization
  Future<void> _initializeFirebaseServices() async {
    Future.microtask(() async {
      try {
        await initializeNotificationService();
        await sendFCMTokenToBackend();
        print('✅ Firebase services initialized');
      } catch (e) {
        print('⚠️ Firebase initialization error: $e');
      }
    });
  }

  Future<void> initializeNotificationService() async {
    try {
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }
      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();
    } catch (e) {
      print('❌ Notification service error: $e');
    }
  }

  Future<void> sendFCMTokenToBackend() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();
      print('🔥 FCM token sent: $fcmToken');
    } catch (e) {
      print('❌ FCM token error: $e');
    }
  }
}