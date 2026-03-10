// lib/app/modules/sign_up/google_signup_controller.dart - FINAL PRODUCTION

import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:HRlynx/app/common_widgets/loading_overlay.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class GoogleSignUpController extends GetxController {
  // ─── Dependencies ─────────────────────────────────────────────
  final _userController = Get.put(UserController());
  final _authRepo        = AuthRepository();

  // ─── State ────────────────────────────────────────────────────
  final isLoading = false.obs;
  final isChecked = false.obs;
  final formKey   = GlobalKey<FormState>();

  static const _iosClientId =
      '907467608466-9c7kk86ghtfqrvou3hpk3m45uj3sg07v.apps.googleusercontent.com';

  // ─────────────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────────────

  void toggleCheckbox(bool? value) => isChecked.value = value ?? false;

  Future<void> handleGoogleSignUp() async {
    if (!_guardTerms()) return;

    try {
      isLoading.value = true;
      LoadingOverlay.show(message: 'Connecting to Google...');

      // Step 1: Google sign-in ──────────────────────────────────
      final googleUser = await _getGoogleUser();
      if (googleUser == null) return;

      // Step 2: Firebase auth ───────────────────────────────────
      LoadingOverlay.updateMessage('Authenticating...');
      final userCredential = await _firebaseSignIn(googleUser);
      if (userCredential == null) return;

      final user = userCredential.user;
      if (!_isValidUser(user)) return;

      // Step 3: Persona fetch ───────────────────────────────────
      LoadingOverlay.updateMessage('Creating your account...');
      final personaId = await TokenStorage.getSelectedPersonaId();
      if (personaId == null) {
        _hideAndSnack(
            'Error', 'No persona selected. Please complete onboarding first.');
        return;
      }

      // Step 4: Backend sign-up + persona set (sequential – order matters) ──
      final success = await _withRetry(
            () => _authRepo.SocialSignUpAndSetPersona(
          email:    user!.email!,
          name:     user.displayName ?? 'Google User',
          provider: 'google',
        ),
        maxAttempts: 2,
        tag: 'googleSignUp',
      );

      if (success != true) {
        _hideAndSnack('Error', 'Failed to complete sign-in. Please try again.');
        return;
      }

      // Step 5: Post-login ──────────────────────────────────────
      _initializeFirebaseServicesAsync();

      LoadingOverlay.updateMessage('Setting up profile...');
      await _authRepo.setParsonaType({'persona': personaId});

      // SubscriptionManager owns LoadingOverlay from here ───────
      await SubscriptionManager.instance.handlePostLoginNavigation();

    } on FirebaseAuthException catch (e) {
      _hideOverlay();
      _handleFirebaseError(e);
    } catch (e, st) {
      _hideOverlay();
      _handleGeneralError(e);
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'handleGoogleSignUp');
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

  Future<GoogleSignInAccount?> _getGoogleUser() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes:   ['email', 'profile'],
        clientId: Platform.isIOS ? _iosClientId : null,
      );
      await googleSignIn.signOut(); // force account picker
      final account = await googleSignIn.signIn();
      if (account == null) _hideOverlay(); // user cancelled
      return account;
    } catch (e) {
      _hideOverlay();
      _handleGeneralError(e);
      return null;
    }
  }

  Future<UserCredential?> _firebaseSignIn(
      GoogleSignInAccount googleUser) async {
    try {
      final auth = await googleUser.authentication;
      if (auth.accessToken == null || auth.idToken == null) {
        _hideAndSnack('Error', 'Failed to get authentication tokens.');
        return null;
      }
      return await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken:     auth.idToken,
        ),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      _hideOverlay();
      _handleGeneralError(e);
      return null;
    }
  }

  bool _isValidUser(User? user) {
    if (user != null && user.email != null) return true;
    _hideAndSnack('Error', 'Google sign-in failed: No user data.');
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

  // ── Overlay helpers ───────────────────────────────────────────
  void _hideOverlay() => LoadingOverlay.hide();

  void _hideAndSnack(String title, String message) {
    _hideOverlay();
    Get.snackbar(
      title, message,
      snackPosition:   SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText:       Colors.white,
      duration:        const Duration(seconds: 4),
    );
    isLoading.value = false;
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
    Get.snackbar(
      'Error', msg,
      snackPosition:   SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText:       Colors.white,
      duration:        const Duration(seconds: 4),
    );
  }

  void _handleGeneralError(dynamic e) {
    final isConfig = e.toString().contains('ApiException: 10');
    Get.snackbar(
      isConfig ? 'Configuration Error' : 'Error',
      isConfig
          ? 'Google Sign-In is not properly configured. Please contact support.'
          : 'Something went wrong. Please try again.',
      snackPosition:   SnackPosition.TOP,
      backgroundColor: isConfig ? Colors.orange : Colors.red,
      colorText:       Colors.white,
      duration:        const Duration(seconds: 5),
    );
  }
}