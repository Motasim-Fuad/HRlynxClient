import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/main_screen/main_screen_view.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();
  static SubscriptionManager get instance => _instance;

  static String get _adminEmail  => dotenv.env['ADMIN_ACCESS_EMAIL'] ?? '';
  static String get _clientEmail => dotenv.env['CLINT_ACCESS_EMAIL'] ?? '';

  static const _kRevenueCatReadyTimeout = Duration(seconds: 5);
  static const _kRestoreTimeout         = Duration(seconds: 10);
  static const _kCustomerInfoTimeout    = Duration(seconds: 8);
  static const _kRetryTimeout           = Duration(seconds: 5);
  static const _kUserIdTimeout          = Duration(seconds: 3);
  static const _kEmailTimeout           = Duration(seconds: 2);


  Future<void> handlePostLoginNavigation() async {
    try {
      final userId = await _getUserIdSafely();
      if (userId == null) {
        debugPrint('Navigation: userId null → subscription screen');
        _navigateToSubscriptionScreen();
        return;
      }

      if (await _isAdminOrClientUser()) {
        debugPrint('Navigation: admin/client → main screen');
        _navigateToMainScreen();
        return;
      }

      final controllerReady = await _ensurePaymentControllerReady(userId);
      if (!controllerReady) {
        final cached = await _getCachedSubscriptionState();
        debugPrint('Navigation: revenueCat not ready, cached=$cached');
        cached ? _navigateToMainScreen() : _navigateToSubscriptionScreen();
        return;
      }

      await _restorePurchasesAndSync();

      final hasActive = await _checkRevenueCatSubscription();
      if (hasActive) {
        await TokenStorage.saveSubscriptionCheckDone(true);
        debugPrint('Navigation: active subscription → main screen');
        _navigateToMainScreen();
        return;
      }

      await _recordFirstTimeUserIfNeeded();
      debugPrint('Navigation: no subscription → subscription screen');
      _navigateToSubscriptionScreen();

    } catch (e, st) {
      debugPrint('POST-LOGIN ERROR: $e $st');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'handlePostLoginNavigation');
      final cached = await _getCachedSubscriptionState();
      cached ? _navigateToMainScreen() : _navigateToSubscriptionScreen();
    }
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
        debugPrint('[$tag] attempt ${i + 1} failed: $e');
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: pow(2, i).toInt()));
      }
    }
    return null;
  }

  Future<int?> _getUserIdSafely() async {
    try {
      final id = await TokenStorage.getUserId()
          .timeout(_kUserIdTimeout, onTimeout: () => null);
      return (id != null && id > 0) ? id : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isAdminOrClientUser() async {
    if (_adminEmail.isEmpty && _clientEmail.isEmpty) return false;
    try {
      final email = await TokenStorage.getUserEmail()
          .timeout(_kEmailTimeout, onTimeout: () => null);
      if (email == null) return false;
      final lower = email.toLowerCase();
      return lower == _adminEmail.toLowerCase() ||
          lower == _clientEmail.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _ensurePaymentControllerReady(int userId) async {
    try {
      if (Get.isRegistered<PaymentController>()) {
        Get.delete<PaymentController>(force: true);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      Get.put(PaymentController(userId: userId));
      final controller = Get.find<PaymentController>();

      if (controller.isRevenueCatAvailable.value &&
          controller.isRevenueCatUserLoggedIn.value) {
        return true;
      }

      final completer = Completer<void>();
      Worker? worker;
      worker = ever(controller.isRevenueCatAvailable, (bool val) {
        if (val && !completer.isCompleted) {
          completer.complete();
          worker?.dispose();
        }
      });

      await completer.future.timeout(
        _kRevenueCatReadyTimeout,
        onTimeout: () => worker?.dispose(),
      );

      return controller.isRevenueCatAvailable.value &&
          controller.isRevenueCatUserLoggedIn.value;
    } catch (e, st) {
      debugPrint('PaymentController boot error: $e');
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: '_ensurePaymentControllerReady');
      return false;
    }
  }

  Future<void> _restorePurchasesAndSync() async {
    try {
      final controller = Get.find<PaymentController>();

      bool restoreOk = false;
      bool infoOk    = false;

      await Future.wait([
        _withRetry(
              () => controller.restorePurchases().timeout(_kRestoreTimeout),
          maxAttempts: 2,
          tag: 'restorePurchases',
        ).then((_) => restoreOk = true).catchError((_) {
          restoreOk = false;
          return null;
        }),
        _withRetry(
              () => controller.getCustomerInfo().timeout(_kCustomerInfoTimeout),
          maxAttempts: 2,
          tag: 'getCustomerInfo',
        ).then((_) => infoOk = true).catchError((_) {
          infoOk = false;
          return null;
        }),
      ]);

      if (!infoOk) {
        debugPrint('CustomerInfo failed – last retry...');
        await controller
            .getCustomerInfo()
            .timeout(_kRetryTimeout)
            .catchError((_) => null);
      }

      debugPrint('Sync done – restore=$restoreOk, info=$infoOk');
    } catch (e) {
      debugPrint('_restorePurchasesAndSync error: $e');
    }
  }

  Future<bool> _checkRevenueCatSubscription() async {
    try {
      final controller = Get.find<PaymentController>();

      await controller
          .getCustomerInfo()
          .timeout(_kCustomerInfoTimeout)
          .catchError((_) => null);

      final info = controller.customerInfo.value;
      if (info == null) {
        debugPrint('CustomerInfo null – using cache');
        return _getCachedSubscriptionState();
      }

      final active = info.entitlements.active.isNotEmpty;
      debugPrint('Entitlements active=$active');
      return active;
    } catch (e) {
      debugPrint('_checkRevenueCatSubscription: $e');
      return _getCachedSubscriptionState();
    }
  }

  Future<bool> _getCachedSubscriptionState() async {
    try {
      final done = await TokenStorage.getSubscriptionCheckDone()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      return done == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _recordFirstTimeUserIfNeeded() async {
    try {
      if (await _getCachedSubscriptionState()) return;
      try {
        final controller = Get.find<PaymentController>();
        final info       = controller.customerInfo.value;
        if (info != null) {
          final hasPurchaseHistory =
              info.allPurchasedProductIdentifiers.isNotEmpty ||
                  info.nonSubscriptionTransactions.isNotEmpty ||
                  info.entitlements.all.isNotEmpty;
          if (hasPurchaseHistory) {
            await TokenStorage.saveSubscriptionCheckDone(true);
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('_recordFirstTimeUserIfNeeded: $e');
    }
  }

  void _navigateToSubscriptionScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => SubscriptionScreen());
    });
  }

  void _navigateToMainScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => MainScreen());
    });
  }


  static Future<void> markSubscriptionActive() async {
    try {
      await TokenStorage.saveSubscriptionCheckDone(true);
      debugPrint('Subscription marked active');
    } catch (e) {
      debugPrint('markSubscriptionActive: $e');
    }
  }
}
