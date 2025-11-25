// lib/app/modules/sign_up/google_signup_controller.dart

import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  // Future<void> handleGoogleSignUp() async {
  //   if (!isChecked.value) {
  //     Get.snackbar(
  //       "Terms Not Accepted",
  //       "Please agree to the Terms and Privacy Policy",
  //     );
  //     return;
  //   }
  //
  //   try {
  //     isLoading.value = true;
  //
  //     final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  //     if (googleUser == null) return;
  //
  //     final googleAuth = await googleUser.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final userCredential =
  //     await FirebaseAuth.instance.signInWithCredential(credential);
  //     final user = userCredential.user;
  //
  //     if (user == null || user.email == null) {
  //       Get.snackbar("Error", "Google sign-in failed: No user data.");
  //       return;
  //     }
  //
  //     final email = user.email!;
  //     final name = user.displayName ?? 'Google User';
  //
  //     final storedPersonaId = await TokenStorage.getSelectedPersonaId();
  //     if (storedPersonaId == null) {
  //       Get.snackbar(
  //         "Error",
  //         "No persona selected. Please complete onboarding first.",
  //       );
  //       return;
  //     }
  //
  //     final personaBody = {"persona": storedPersonaId};
  //     final success = await authRepo.SocialSignUpAndSetPersona(
  //       email: email,
  //       name: name,
  //       provider: 'google',
  //     );
  //     await authRepo.setParsonaType(personaBody);
  //
  //     if (success) {
  //       await initializeNotificationService();
  //       await sendFCMTokenToBackend();
  //
  //       Get.snackbar("Success", "Google sign-in complete and persona set.");
  //
  //       // ✅ USE SUBSCRIPTION MANAGER
  //       await SubscriptionManager.instance.handlePostLoginNavigation();
  //
  //     } else {
  //       Get.snackbar("Error", "Failed to set persona after Google login.");
  //     }
  //   } catch (e) {
  //     if (e.toString().contains("[firebase_auth/network-request-failed]")) {
  //       Get.snackbar(
  //         "Error",
  //         "I think your network has a problem or timeout. Please try again.",
  //       );
  //     }
  //     print("GoogleSignUp Error: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }



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

      // ✅ ADD CONFIGURATION
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // ✅ IMPORTANT: Add this for iPad support
        clientId: '907467608466-9c7kk86ghtfqrvou3hpk3m45uj3sg07v.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return; // User cancelled
      }

      final googleAuth = await googleUser.authentication;

      // ✅ ADD NULL CHECK
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        Get.snackbar("Error", "Failed to get Google credentials");
        isLoading.value = false;
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null || user.email == null) {
        Get.snackbar("Error", "Google sign-in failed: No user data.");
        isLoading.value = false;
        return;
      }

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
      await authRepo.setParsonaType(personaBody);

      if (success) {
        // ✅ NON-BLOCKING NOTIFICATIONS
        try {
          await initializeNotificationService();
          await sendFCMTokenToBackend();
        } catch (e) {
          print('⚠️ Non-critical error (notifications): $e');
        }

        Get.snackbar("Success", "Google sign-in complete!");
        await SubscriptionManager.instance.handlePostLoginNavigation();

      } else {
        Get.snackbar("Error", "Failed to set persona after Google login.");
      }
    } on FirebaseAuthException catch (e) {
      // ✅ FIREBASE-SPECIFIC ERRORS
      if (e.code == 'network-request-failed') {
        Get.snackbar(
          "Error",
          "Network problem. Please check your connection.",
        );
      } else if (e.code == 'user-disabled') {
        Get.snackbar("Error", "This account has been disabled.");
      } else {
        Get.snackbar("Error", "Authentication failed: ${e.message}");
      }
      print("Firebase Auth Error: ${e.code} - ${e.message}");
    } catch (e) {
      Get.snackbar("Error", "Something went wrong. Please try again.");
      print("❌ GoogleSignUp Error: $e");
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
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  Future<void> sendFCMTokenToBackend() async {
    try {
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();
      print('✅ FCM token sent to backend after Google login');
    } catch (e) {
      print('❌ Error sending FCM token after Google login: $e');
    }
  }
}