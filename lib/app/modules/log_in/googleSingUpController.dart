// lib/app/modules/sign_up/google_signup_controller.dart

import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class GoogleSignUpController extends GetxController {
  final userController = Get.put(UserController());
  final AuthRepository authRepo = AuthRepository();
  final isLoading = false.obs;

  final isChecked = false.obs;
  late final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
  }

  Future<void> handleGoogleSignUp() async {
    if (!isChecked.value) {
      Get.snackbar(
        "Terms Not Accepted",
        "Please agree to the Terms and Privacy Policy",
      );
      return;
    }

    try {
      isLoading.value = true;

      // ✅ PLATFORM-SPECIFIC CONFIGURATION
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // ✅ Only add clientId for iOS/iPad (NOT for Android)
        clientId: Platform.isIOS
            ? '907467608466-9c7kk86ghtfqrvou3hpk3m45uj3sg07v.apps.googleusercontent.com'
            : null,
      );

      // ✅ Sign out first to ensure clean state
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ User cancelled Google Sign-In');
        isLoading.value = false;
        return;
      }

      print('✅ Google User: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;

      // ✅ Detailed token check
      if (googleAuth.accessToken == null) {
        print('❌ Access token is null');
        Get.snackbar("Error", "Failed to get access token");
        isLoading.value = false;
        return;
      }

      if (googleAuth.idToken == null) {
        print('❌ ID token is null');
        Get.snackbar("Error", "Failed to get ID token");
        isLoading.value = false;
        return;
      }

      print('✅ Tokens received successfully');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null || user.email == null) {
        Get.snackbar("Error", "Google sign-in failed: No user data.");
        isLoading.value = false;
        return;
      }

      print('✅ Firebase user authenticated: ${user.email}');

      final email = user.email!;
      final name = user.displayName ?? 'Google User';

      final storedPersonaId = await TokenStorage.getSelectedPersonaId();
      if (storedPersonaId == null) {
        Get.snackbar(
          "Error",
          "No persona selected. Please complete onboarding first.",
        );
        isLoading.value = false;
        return;
      }

      final personaBody = {"persona": storedPersonaId};
      final success = await authRepo.SocialSignUpAndSetPersona(
        email: email,
        name: name,
        provider: 'google',
      );




      if (success) {
        // ✅ Non-blocking notifications
        try {
          await initializeNotificationService();
          await sendFCMTokenToBackend();
        } catch (e) {
          print('⚠️ Non-critical notification error: $e');
        }
        await authRepo.setParsonaType(personaBody);

        Get.snackbar("title", "persona set successfully");

        await SubscriptionManager.instance.handlePostLoginNavigation();

      } else {
        Get.snackbar("Error", "Failed to complete sign-in. Please try again.");
      }

    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');

      String errorMessage = 'Authentication failed';

      switch (e.code) {
        case 'network-request-failed':
          errorMessage = 'Network problem. Please check your connection.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials. Please try again.';
          break;
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with this email.';
          break;
        default:
          errorMessage = e.message ?? 'Something went wrong';
      }

      Get.snackbar(
        "Error",
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

    } catch (e) {
      print('❌ GoogleSignUp Error: $e');

      // ✅ Handle ApiException: 10 specifically
      if (e.toString().contains('ApiException: 10')) {
        Get.snackbar(
          "Configuration Error",
          "Google Sign-In is not properly configured. Please contact support.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          "Error",
          "Something went wrong. Please try again.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initializeNotificationService() async {
    try {
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }
      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Notification service error: $e');
      rethrow;
    }
  }

  Future<void> sendFCMTokenToBackend() async {
    try {
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();
      print('✅ FCM token sent');
    } catch (e) {
      print('❌ FCM token error: $e');
      rethrow;
    }
  }
}