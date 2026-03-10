// lib/app/modules/sign_up/apple_signup_controller.dart - FINAL PRODUCTION

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:HRlynx/app/common_widgets/loading_overlay.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';
import '../../api_servies/biometric_service.dart';

class AppleSignUpController extends GetxController {
  // ─── Dependencies ─────────────────────────────────────────────
  final _userController  = Get.put(UserController());
  final _authRepo         = AuthRepository();
  final _biometricService = BiometricService();

  // ─── State ────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isChecked = false.obs;
  final formKey   = GlobalKey<FormState>();

  // ─────────────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────────────

  void toggleCheckbox(bool? value) => isChecked.value = value ?? false;

  Future<void> handleAppleSignUp() async {
    if (!_guardTerms()) return;

    try {
      isLoading.value = true;
      LoadingOverlay.show(message: 'Connecting to Apple...');

      // Step 1: Device check ────────────────────────────────────
      if (!await SignInWithApple.isAvailable()) {
        _hideAndSnack('Error', 'Apple Sign-In is not available on this device.');
        return;
      }

      // Step 2: Apple + Firebase sign-in ────────────────────────
      LoadingOverlay.updateMessage('Authenticating...');
      final userCredential = await _appleFirebaseSignIn();
      if (userCredential == null) return;

      final user = userCredential.user;
      if (!_isValidUser(user)) return;

      // Step 3: Persona fetch ────────────────────────────────────
      LoadingOverlay.updateMessage('Creating your account...');
      final personaId = await TokenStorage.getSelectedPersonaId();
      if (personaId == null) {
        _hideAndSnack(
            'Error', 'No persona selected. Please complete onboarding first.');
        return;
      }

      // Step 4: Backend sign-up (with retry) ────────────────────
      final success = await _withRetry(
            () => _authRepo.SocialSignUpAndSetPersona(
          email:    user!.email!,
          name:     user.displayName ?? 'Apple User',
          provider: 'apple',
        ),
        maxAttempts: 2,
        tag: 'appleSignUp',
      );

      if (success != true) {
        _hideAndSnack('Error', 'Failed to complete sign-in. Please try again.');
        return;
      }

      // Step 5: Post-login ──────────────────────────────────────
      _initializeFirebaseServicesAsync();
      _enableBiometricAsync(user!.email!);

      LoadingOverlay.updateMessage('Setting up profile...');
      await _authRepo.setParsonaType({'persona': personaId});

      // SubscriptionManager owns LoadingOverlay from here ───────
      await SubscriptionManager.instance.handlePostLoginNavigation();

    } on SignInWithAppleAuthorizationException catch (e) {
      _hideOverlay();
      if (e.code != AuthorizationErrorCode.canceled) {
        _snack('Error', 'Apple Sign-In error: ${e.message}');
      }
    } on FirebaseAuthException catch (e) {
      _hideOverlay();
      _handleFirebaseError(e);
    } catch (e, st) {
      _hideOverlay();
      _handleGeneralError(e);
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'handleAppleSignUp');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────

  bool _guardTerms() {
    if (isChecked.value) return true;
    Get.snackbar(
      'Terms Not Accepted',
      'Please agree to the Terms and Privacy Policy',
      snackPosition: SnackPosition.TOP,
    );
    return false;
  }

  Future<UserCredential?> _appleFirebaseSignIn() async {
    try {
      final rawNonce = _generateNonce();
      final nonce    = _sha256(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken:     appleCredential.identityToken,
        rawNonce:    rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Apple only sends name on first sign-in
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _updateDisplayName(
          userCredential.user,
          appleCredential.givenName,
          appleCredential.familyName,
        );
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException {
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      _hideOverlay();
      _handleGeneralError(e);
      return null;
    }
  }

  Future<void> _updateDisplayName(
      User? user, String? given, String? family) async {
    if (user == null) return;
    final name =
    [given, family].where((s) => s != null && s.isNotEmpty).join(' ').trim();
    if (name.isNotEmpty) {
      await user.updateDisplayName(name).catchError((_) {});
    }
  }

  bool _isValidUser(User? user) {
    if (user != null && user.email != null) return true;
    _hideAndSnack('Error', 'Apple sign-in failed: No user data.');
    return false;
  }

  // ── Retry with exponential back-off ──────────────────────────
  Future<T?> _withRetry<T>(
      Future<T> Function() fn, {
        int maxAttempts = 3,
        String tag = '',
      }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        return await fn();
      } catch (e) {
        debugPrint('⚠️ [$tag] attempt ${i + 1} failed: $e');
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: pow(2, i).toInt()));
      }
    }
    return null;
  }

  // ── Biometric (fire-and-forget) ───────────────────────────────
  void _enableBiometricAsync(String email) {
    Future.microtask(() async {
      try {
        await _biometricService.enableBiometricLogin(email);
        debugPrint('✅ Biometric enabled');
      } catch (e) {
        debugPrint('⚠️ Biometric error: $e');
      }
    });
  }

  // ── Firebase (fire-and-forget) ────────────────────────────────
  void _initializeFirebaseServicesAsync() {
    Future.microtask(() async {
      try {
        if (!Get.isRegistered<NotificationService>()) {
          Get.put(NotificationService());
        }
        await NotificationService.instance.enableConnection();
        await FirebaseMeg().sendFCMTokenAfterLogin();
        debugPrint('✅ Firebase services initialised');
      } catch (e) {
        debugPrint('⚠️ Firebase services error: $e');
      }
    });
  }

  // ── Crypto ────────────────────────────────────────────────────
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rng = Random.secure();
    return List.generate(
        length, (_) => charset[rng.nextInt(charset.length)])
        .join();
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  // ── Overlay helpers ───────────────────────────────────────────
  void _hideOverlay() => LoadingOverlay.hide();

  void _hideAndSnack(String title, String message) {
    _hideOverlay();
    _snack(title, message);
    isLoading.value = false;
  }

  void _snack(String title, String message,
      {Color color = Colors.red}) {
    Get.snackbar(
      title, message,
      snackPosition:   SnackPosition.TOP,
      backgroundColor: color,
      colorText:       Colors.white,
      duration:        const Duration(seconds: 4),
    );
  }

  // ── Error handlers ────────────────────────────────────────────
  void _handleFirebaseError(FirebaseAuthException e) {
    final msg = switch (e.code) {
      'network-request-failed'                   =>
      'Network problem. Please check your connection.',
      'user-disabled'                            =>
      'This account has been disabled.',
      'invalid-credential'                       =>
      'Invalid credentials. Please try again.',
      'account-exists-with-different-credential' =>
      'An account already exists with this email.',
      _ => e.message ?? 'Authentication failed.',
    };
    _snack('Error', msg);
  }

  void _handleGeneralError(dynamic e) {
    final str = e.toString();
    if (str.contains('network') || str.contains('Network')) {
      _snack('Error', 'Network problem. Please check your connection.');
    } else {
      _snack('Error', 'Something went wrong. Please try again.');
    }
  }
}