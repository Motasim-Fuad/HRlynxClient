// lib/app/modules/log_in/log_in_controller.dart - FINAL PRODUCTION

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:HRlynx/app/api_servies/firebase_message.dart';
import 'package:HRlynx/app/api_servies/notification_services.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/subscription_manager.dart';
import 'package:HRlynx/app/common_widgets/loading_overlay.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';

class LogInController extends GetxController {
  // ─── Dependencies ─────────────────────────────────────────────
  final _userController = Get.put(UserController());
  final _authRepo        = AuthRepository();

  // ─── Text controllers ─────────────────────────────────────────
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  // ─── State ────────────────────────────────────────────────────
  final isObscured = true.obs;
  final isChecked  = false.obs;
  final isLoading  = false.obs;
  final formKey    = GlobalKey<FormState>();

  // ─────────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    emailController.clear();
    passwordController.clear();
    isChecked.value = false;
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────
  //  PUBLIC API
  // ─────────────────────────────────────────────────────────────

  void toggleObscureText()       => isObscured.value = !isObscured.value;
  void toggleCheckbox(bool? val) => isChecked.value  = val ?? false;

  Future<void> loginUser() async {
    if (!formKey.currentState!.validate()) return;
    if (!_guardTerms()) return;

    final email    = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      isLoading.value = true;
      LoadingOverlay.show(message: 'Logging in...');

      // Step 1: Authenticate (with retry) ──────────────────────
      final response = await _withRetry(
            () => _authRepo.login(email, password),
        maxAttempts: 2,
        tag: 'login',
      );

      final data    = response?['data'];
      final access  = data?['access']  as String?;
      final refresh = data?['refresh'] as String?;
      final user    = data?['user']    as Map<String, dynamic>?;

      if (access == null || refresh == null) {
        _hideAndSnack(
          'Login Failed',
          data?['detail'] ?? 'Invalid credentials. Please try again.',
        );
        return;
      }

      // Step 2: Persist session + fetch persona (parallel) ─────
      LoadingOverlay.updateMessage('Saving session...');

      final personaFuture = TokenStorage.getSelectedPersonaId();

      await Future.wait([
        TokenStorage.saveLoginTokens(access, refresh),
        if (user?['email'] != null)
          TokenStorage.saveUserEmail(user!['email'] as String),
        if (user?['id'] != null)
          TokenStorage.saveUserId(user!['id']),
      ]);

      final personaId = await personaFuture;
      if (personaId == null) {
        _hideAndSnack(
            'Error', 'No persona selected. Please complete onboarding first.');
        return;
      }

      // Step 3: Firebase (fire-and-forget) ─────────────────────
      _initializeFirebaseServicesAsync();

      // Step 4: Set persona ─────────────────────────────────────
      LoadingOverlay.updateMessage('Setting up profile...');
      await _authRepo.setParsonaType({'persona': personaId});

      // SubscriptionManager owns LoadingOverlay from here ───────
      await SubscriptionManager.instance.handlePostLoginNavigation();

    } catch (e, st) {
      _hideOverlay();
      _handleLoginError(e);
      debugPrint('❌ Login error: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'loginUser');
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
      snackPosition:   SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText:       Colors.white,
    );
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

  void _hideAndSnack(String title, String message, {Color color = Colors.red}) {
    _hideOverlay();
    Get.snackbar(
      title, message,
      snackPosition:   SnackPosition.TOP,
      backgroundColor: color,
      colorText:       Colors.white,
      duration:        const Duration(seconds: 4),
    );
    isLoading.value = false;
  }

  // ── Error handler ─────────────────────────────────────────────
  void _handleLoginError(dynamic e) {
    final str = e.toString();
    final String message;

    if (str.contains('SocketException') ||
        str.contains('network') ||
        str.contains('Network')) {
      message = 'Network problem. Please check your connection.';
    } else if (str.contains('401') ||
        str.contains('Unauthorized') ||
        str.contains('credentials')) {
      message = 'Incorrect email or password.';
    } else if (str.contains('timeout') ||
        str.contains('TimeoutException')) {
      message = 'Request timed out. Please try again.';
    } else {
      message = 'Something went wrong. Please try again.';
    }

    Get.snackbar(
      'Error', message,
      snackPosition:   SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText:       Colors.white,
      duration:        const Duration(seconds: 4),
    );
  }
}