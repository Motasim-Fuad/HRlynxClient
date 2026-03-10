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
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class GoogleSignUpController extends GetxController {
  final _userController = Get.put(UserController());
  final _authRepo        = AuthRepository();

  final isLoading = false.obs;
  final isChecked = false.obs;
  final formKey   = GlobalKey<FormState>();

  static const _iosClientId =
      '907467608466-9c7kk86ghtfqrvou3hpk3m45uj3sg07v.apps.googleusercontent.com';

  void toggleCheckbox(bool? value) => isChecked.value = value ?? false;

  Future<void> handleGoogleSignUp() async {
    if (!_guardTerms()) return;

    try {
      isLoading.value = true;

      // Step 1: Google sign-in
      final googleUser = await _getGoogleUser();
      if (googleUser == null) return;

      // Step 2: Firebase auth
      final userCredential = await _firebaseSignIn(googleUser);
      if (userCredential == null) return;

      final user = userCredential.user;
      if (!_isValidUser(user)) return;

      // Step 3: Persona fetch
      final personaId = await TokenStorage.getSelectedPersonaId();
      if (personaId == null) {
        _showSnack('Error',
            'No persona selected. Please complete onboarding first.');
        return;
      }

      // Step 4: Backend sign-up (with retry)
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
        _showSnack('Error', 'Failed to complete sign-in. Please try again.');
        return;
      }

      // Step 5: Post-login
      _initializeFirebaseServicesAsync();
      await _authRepo.setParsonaType({'persona': personaId});

      Get.snackbar("Success", "SingIn Successful",backgroundColor: Colors.white,snackPosition: SnackPosition.TOP);

      await SubscriptionManager.instance.handlePostLoginNavigation();

    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e, st) {
      _handleGeneralError(e);
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'handleGoogleSignUp');
    } finally {
      isLoading.value = false;
    }
  }

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
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) isLoading.value = false; // user cancelled
      return account;
    } catch (e) {
      _handleGeneralError(e);
      return null;
    }
  }

  Future<UserCredential?> _firebaseSignIn(
      GoogleSignInAccount googleUser) async {
    try {
      final auth = await googleUser.authentication;
      if (auth.accessToken == null || auth.idToken == null) {
        _showSnack('Error', 'Failed to get authentication tokens.');
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
      _handleGeneralError(e);
      return null;
    }
  }

  bool _isValidUser(User? user) {
    if (user != null && user.email != null) return true;
    _showSnack('Error', 'Google sign-in failed: No user data.');
    return false;
  }

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

  void _initializeFirebaseServicesAsync() {
    Future.microtask(() async {
      try {
        if (!Get.isRegistered<NotificationService>()) {
          Get.put(NotificationService());
        }
        await NotificationService.instance.enableConnection();
        await FirebaseMeg().sendFCMTokenAfterLogin();
      } catch (e) {
        debugPrint('⚠️ Firebase services error: $e');
      }
    });
  }

  void _showSnack(String title, String message, {Color color = Colors.red}) {
    isLoading.value = false;
    Get.snackbar(
      title, message,
      snackPosition:   SnackPosition.TOP,
      backgroundColor: color,
      colorText:       Colors.white,
      duration:        const Duration(seconds: 4),
    );
  }

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
    _showSnack('Error', msg);
  }

  void _handleGeneralError(dynamic e) {
    final isConfig = e.toString().contains('ApiException: 10');
    _showSnack(
      isConfig ? 'Configuration Error' : 'Error',
      isConfig
          ? 'Google Sign-In is not properly configured. Please contact support.'
          : 'Something went wrong. Please try again.',
      color: isConfig ? Colors.orange : Colors.red,
    );
  }
}