
import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';
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

  // ✅ Terms & Conditions checkbox
  final isChecked = false.obs;
  late final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
  }

  Future<void> handleGoogleSignUp() async {
    // ✅ Check terms acceptance
    if (!isChecked.value) {
      Get.snackbar(
        "Terms Not Accepted",
        "Please agree to the Terms and Privacy Policy",
      );
      return;
    }

    try {
      isLoading.value = true;

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null || user.email == null) {
        Get.snackbar("Error", "Google sign-in failed: No user data.");
        return;
      }

      final email = user.email!;
      final name = user.displayName ?? 'Google User';

      // ✅ Get persona ID from onboarding
      final storedPersonaId = await TokenStorage.getSelectedPersonaId();
      if (storedPersonaId == null) {
        Get.snackbar(
          "Error",
          "No persona selected. Please complete onboarding first.",
        );
        return;
      }

      // ✅ Send to backend
      final personaBody = {"persona": storedPersonaId};
      final success = await authRepo.SocialSignUpAndSetPersona(
        email: email,
        name: name,
        provider: 'google',
      );
      await authRepo.setParsonaType(personaBody);


      if (success) {
        await initializeNotificationService();
        await sendFCMTokenToBackend();

        // ✅ Reset subscription check flag for first time user
        await TokenStorage.clearSubscriptionCheckFlag();

        Get.snackbar("Success", "Google sign-in complete and persona set.");
        Get.to(SubscriptionScreen());
      } else {
        Get.snackbar("Error", "Failed to set persona after Google login.");
      }
    } catch (e) {
      if (e.toString().contains(
          "[firebase_auth/network-request-failed]")) {
        Get.snackbar(
          "Error",
          "I think your network has a problem or timeout. Please try again.",
        );
      }
      print("GoogleSignUp Error: $e");
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
