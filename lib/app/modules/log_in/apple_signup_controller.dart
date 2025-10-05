import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';
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

  /// Google Sign-In এর exact same logic কিন্তু Apple Sign-In দিয়ে
  Future<void> handleAppleSignUp() async {
    try {
      isLoading.value = true;

      // Step 1: Apple Sign-In এর availability check করুন
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        Get.snackbar("Error", "Apple Sign-In is not available on this device");
        isLoading.value = false;
        return;
      }

      // Step 2: Apple Sign-In via Firebase
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

      // Step 3: Get stored persona ID from onboarding (same as Google)
      final storedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (storedPersonaId == null) {
        Get.snackbar("Error", "No persona selected. Please complete onboarding first.");
        return;
      }

      print("✅ Using stored persona ID: $storedPersonaId");

      // Step 4: Send to backend social login API with stored persona ID
      final personaBody = {
        "persona": storedPersonaId, // Use stored persona ID
      };

      final success = await authRepo.SocialSignUpAndSetPersona(
        email: email,
        name: name,
        provider: 'apple', // 👈 Provider changed to 'apple'
      );
      await authRepo.setParsonaType(personaBody);

      print("send selected persona id to api");

      userController.setUserEmail(user.email ?? 'No Email Found');

      // Step 5: Handle success or failure (same as Google)
      if (success) {
        // Apple login successful হওয়ার পর notification service এবং FCM token setup করুন
        await initializeNotificationService();
        await sendFCMTokenToBackend();

        Get.snackbar("Success", "Apple sign-in complete and persona set.");
        print("Apple signin successful with persona ID: $storedPersonaId");
        Get.to(SubscriptionScreen());
      } else {
        Get.snackbar("Error", "Failed to set persona after Apple login.");
      }
    } catch (e) {
      // Handle Apple Sign-In specific errors
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
      // Generate nonce for security
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      // Apple Sign-In request
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print("Apple Sign-In Response:");
      print("User ID: ${appleCredential.userIdentifier}");
      print("Email: ${appleCredential.email}");
      print("Full Name: ${appleCredential.givenName} ${appleCredential.familyName}");

      // Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Update display name if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await updateUserDisplayName(
          userCredential.user,
          appleCredential.givenName,
          appleCredential.familyName,
        );
      }

      print("✅ Apple Sign-In Successful");
      print("Firebase User: ${userCredential.user?.email}");

      return userCredential;
    } catch (e) {
      print("❌ Apple Sign-In Error: $e");
      throw e;
    }
  }

  /// Update user display name
  Future<void> updateUserDisplayName(User? user, String? givenName, String? familyName) async {
    if (user != null && (givenName != null || familyName != null)) {
      String displayName = '';
      if (givenName != null) displayName += givenName;
      if (familyName != null) displayName += ' $familyName';

      await user.updateDisplayName(displayName.trim());
      print("Display name updated: ${displayName.trim()}");
    }
  }

  /// Generate random nonce for security
  String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 hash
  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if Apple Sign-In is available
  Future<bool> isAppleSignInAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  // Initialize notification service (exact same as Google)
  Future<void> initializeNotificationService() async {
    try {
      // Register notification service if not already registered
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }

      // Get instance and enable connection
      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Send FCM token to backend after Apple login (exact same as Google)
  Future<void> sendFCMTokenToBackend() async {
    try {
      // Firebase message service এর instance নিন
      final firebaseMsg = FirebaseMeg();
      await firebaseMsg.sendFCMTokenAfterLogin();
      print('✅ FCM token sent to backend after Apple login');
    } catch (e) {
      print('❌ Error sending FCM token after Apple login: $e');
    }
  }
}