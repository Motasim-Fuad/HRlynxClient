// lib/app/modules/sign_up/google_signup_controller.dart - OPTIMIZED

import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:HRlynx/app/common_widgets/loading_overlay.dart';
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

  /// ✅ OPTIMIZED: Shows loading during entire process
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
      //LoadingOverlay.show(message: 'Connecting to Google...');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: Platform.isIOS
            ? '907467608466-9c7kk86ghtfqrvou3hpk3m45uj3sg07v.apps.googleusercontent.com'
            : null,
      );

      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        LoadingOverlay.hide();
        isLoading.value = false;
        return;
      }

      LoadingOverlay.updateMessage('Authenticating...');
      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        LoadingOverlay.hide();
        Get.snackbar("Error", "Failed to get authentication tokens");
        isLoading.value = false;
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null || user.email == null) {
        LoadingOverlay.hide();
        Get.snackbar("Error", "Google sign-in failed: No user data.");
        isLoading.value = false;
        return;
      }

      LoadingOverlay.updateMessage('Creating your account...');
      final email = user.email!;
      final name = user.displayName ?? 'Google User';

      final storedPersonaId = await TokenStorage.getSelectedPersonaId();
      if (storedPersonaId == null) {
        LoadingOverlay.hide();
        Get.snackbar("Error", "No persona selected. Please complete onboarding first.");
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
        // Non-blocking notifications
        _initializeFirebaseServices();

        //LoadingOverlay.updateMessage('Setting up profile...');
        await authRepo.setParsonaType(personaBody);

        // Subscription Manager handles its own loading
        LoadingOverlay.hide();
        await SubscriptionManager.instance.handlePostLoginNavigation();

      } else {
        LoadingOverlay.hide();
        Get.snackbar("Error", "Failed to complete sign-in. Please try again.");
      }

    } on FirebaseAuthException catch (e) {
      LoadingOverlay.hide();
      _handleFirebaseError(e);
    } catch (e) {
      LoadingOverlay.hide();
      _handleGeneralError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
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
  }

  void _handleGeneralError(dynamic e) {
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
  }

  Future<void> _initializeFirebaseServices() async {
    Future.microtask(() async {
      try {
        await initializeNotificationService();
        await sendFCMTokenToBackend();
      } catch (e) {
        print('⚠️ Firebase services error: $e');
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
      rethrow;
    }
  }

  Future<void> sendFCMTokenToBackend() async {
    try {
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();
    } catch (e) {
      rethrow;
    }
  }
}