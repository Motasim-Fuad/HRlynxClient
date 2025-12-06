// lib/app/services/biometric_service.dart
// ✅ FIXED VERSION - Proper state management

import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    // ✅ IMPORTANT: Add these options for iOS reliability
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _userEmailKey = 'biometric_user_email';
  static const _hasLoggedInBeforeKey = 'has_logged_in_before';

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({String reason = 'Please authenticate to login'}) async {
    try {
      final bool isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        print('⚠️ Biometric authentication not available');
        return false;
      }

      final bool authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      print('❌ Biometric authentication error: ${e.code}');

      if (e.code == auth_error.notAvailable) {
        print('⚠️ Biometric not available on this device');
      } else if (e.code == auth_error.notEnrolled) {
        print('⚠️ No biometrics enrolled');
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        print('⚠️ Biometric authentication locked');
      }

      return false;
    } catch (e) {
      print('❌ Unexpected biometric error: $e');
      return false;
    }
  }

  /// Enable biometric login for a user
  Future<bool> enableBiometricLogin(String email) async {
    try {
      print('💾 Enabling biometric login for: $email');

      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      await _secureStorage.write(key: _userEmailKey, value: email);
      await _secureStorage.write(key: _hasLoggedInBeforeKey, value: 'true');

      // ✅ Verify immediately after saving
      await Future.delayed(Duration(milliseconds: 100));
      final verified = await isBiometricEnabled();

      if (verified) {
        print('✅ Biometric login enabled successfully');
        return true;
      } else {
        print('❌ Biometric enable verification failed');
        return false;
      }
    } catch (e) {
      print('❌ Error enabling biometric login: $e');
      return false;
    }
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _userEmailKey);
      print('✅ Biometric login disabled');
    } catch (e) {
      print('❌ Error disabling biometric login: $e');
    }
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      final result = enabled == 'true';
      print('📋 Biometric enabled check: $result');
      return result;
    } catch (e) {
      print('❌ Error checking biometric status: $e');
      return false;
    }
  }

  /// Get stored email for biometric login
  Future<String?> getStoredEmail() async {
    try {
      final email = await _secureStorage.read(key: _userEmailKey);
      print('📧 Stored email: ${email ?? "None"}');
      return email;
    } catch (e) {
      print('❌ Error getting stored email: $e');
      return null;
    }
  }

  /// Check if user has logged in before
  Future<bool> hasLoggedInBefore() async {
    try {
      final value = await _secureStorage.read(key: _hasLoggedInBeforeKey);
      return value == 'true';
    } catch (e) {
      print('❌ Error checking login history: $e');
      return false;
    }
  }

  /// ✅ NEW: Clear only biometric data (not login history)
  Future<void> clearBiometricDataOnly() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _userEmailKey);
      // ✅ DON'T delete _hasLoggedInBeforeKey
      print('✅ Biometric data cleared (keeping login history)');
    } catch (e) {
      print('❌ Error clearing biometric data: $e');
    }
  }

  /// Clear all biometric data (for logout)
  Future<void> clearBiometricData() async {
    try {
      await _secureStorage.deleteAll();
      print('✅ All biometric data cleared');
    } catch (e) {
      print('❌ Error clearing biometric data: $e');
    }
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }

  /// ✅ NEW: Debug method to check all stored values
  Future<Map<String, String?>> debugGetAllValues() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      final email = await _secureStorage.read(key: _userEmailKey);
      final hasLoggedIn = await _secureStorage.read(key: _hasLoggedInBeforeKey);

      return {
        'enabled': enabled,
        'email': email,
        'hasLoggedIn': hasLoggedIn,
      };
    } catch (e) {
      print('❌ Error in debugGetAllValues: $e');
      return {};
    }
  }
}