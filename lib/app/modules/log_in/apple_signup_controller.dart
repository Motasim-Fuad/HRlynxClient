import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class AppleSignUpController extends GetxController {
  final userController = Get.put(UserController());
  final AuthRepository authRepo = AuthRepository();
  final isLoading = false.obs;

  // ✅ Terms & Conditions checkbox state
  final isChecked = false.obs;
  late final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
  }

  /// Apple Sign-In with terms check
// Only showing the changed part - rest remains same

  Future<void> handleAppleSignUp() async {
    if (!isChecked.value) {
      Get.snackbar(
        "Terms Not Accepted",
        "Please agree to the Terms and Privacy Policy",
      );
      return;
    }

    try {
      isLoading.value = true;

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        Get.snackbar("Error", "Apple Sign-In is not available on this device");
        isLoading.value = false;
        return;
      }

      final userCredential = await signInWithApple();
      if (userCredential == null) {
        isLoading.value = false;
        return;
      }

      final user = userCredential.user;
      if (user == null || user.email == null) {
        Get.snackbar("Error", "Apple sign-in failed: No user data.");
        return;
      }

      final email = user.email!;
      final name = user.displayName ?? 'Apple User';

      final storedPersonaId = await TokenStorage.getSelectedPersonaId();
      if (storedPersonaId == null) {
        Get.snackbar("Error", "No persona selected. Please complete onboarding first.");
        return;
      }

      final personaBody = {"persona": storedPersonaId};
      final success = await authRepo.SocialSignUpAndSetPersona(
        email: email,
        name: name,
        provider: 'apple',
      );
      await authRepo.setParsonaType(personaBody);

      if (success) {
        await initializeNotificationService();
        await sendFCMTokenToBackend();

        Get.snackbar("Success", "Apple sign-in complete and persona set.");

        // ✅ USE SUBSCRIPTION MANAGER
        await SubscriptionManager.instance.handlePostLoginNavigation();

      } else {
        Get.snackbar("Error", "Failed to set persona after Apple login.");
      }
    } catch (e) {
      if (e.toString().contains('canceled')) {
        Get.snackbar("Cancelled", "Apple Sign-In was cancelled by user");
      } else if (e.toString().contains('network')) {
        Get.snackbar("Error", "Network problem. Please check your internet connection.");
      } else {
        Get.snackbar("Error", "Apple Sign-In failed. Please try again.");
      }
      print("AppleSignUp Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Apple Sign-In with Firebase implementation
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await updateUserDisplayName(
          userCredential.user,
          appleCredential.givenName,
          appleCredential.familyName,
        );
      }

      return userCredential;
    } catch (e) {
      print("❌ Apple Sign-In Error: $e");
      throw e;
    }
  }

  Future<void> updateUserDisplayName(User? user, String? givenName, String? familyName) async {
    if (user != null && (givenName != null || familyName != null)) {
      String displayName = '';
      if (givenName != null) displayName += givenName;
      if (familyName != null) displayName += ' $familyName';
      await user.updateDisplayName(displayName.trim());
      print("Display name updated: ${displayName.trim()}");
    }
  }

  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
      print('✅ FCM token sent to backend after Apple login');
    } catch (e) {
      print('❌ Error sending FCM token after Apple login: $e');
    }
  }
}
