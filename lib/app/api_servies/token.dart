
// lib/app/api_servies/token.dart

import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  // Login tokens
  static const _loginAccessTokenKey = 'login_access_token';
  static const _loginRefreshTokenKey = 'login_refresh_token';

  // OTP tokens
  static const _otpAccessTokenKey = 'otp_access_token';
  static const _otpRefreshTokenKey = 'otp_refresh_token';

  // Reset password tokens
  static const _resetAccessTokenKey = 'reset_access_token';
  static const _resetRefreshTokenKey = 'reset_refresh_token';

  // ✅ In-memory fallback for critical flags
  static bool? _inMemorySubscriptionFlag;

  /// ===== LOGIN TOKENS =====
  static Future<void> saveLoginTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginAccessTokenKey, accessToken);
    await prefs.setString(_loginRefreshTokenKey, refreshToken);
  }

  static Future<String?> getLoginAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginAccessTokenKey);
  }

  static Future<String?> getLoginRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginRefreshTokenKey);
  }

  /// ===== OTP TOKENS =====
  static Future<void> saveOtpTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_otpAccessTokenKey, accessToken);
    await prefs.setString(_otpRefreshTokenKey, refreshToken);
  }

  static Future<String?> getOtpAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_otpAccessTokenKey);
  }

  static Future<String?> getOtpRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_otpRefreshTokenKey);
  }

  /// ===== RESET PASSWORD TOKENS =====
  static Future<void> saveResetTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resetAccessTokenKey, accessToken);
    await prefs.setString(_resetRefreshTokenKey, refreshToken);
  }

  static Future<String?> getResetAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resetAccessTokenKey);
  }

  static Future<String?> getResetRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resetRefreshTokenKey);
  }

  /// ===== Store selected persona Id =======
  static const _selectedPersonaIdKey = 'selected_persona_id';

  static Future<void> saveSelectedPersonaId(int personaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedPersonaIdKey, personaId);
  }

  static Future<int?> getSelectedPersonaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_selectedPersonaIdKey);
  }

  static Future<void> clearSelectedPersonaId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedPersonaIdKey);
  }

  /// ===== STORE PERSONA SESSION ID  =====
  static String _personaSessionKey(int personaId) => 'session_persona_$personaId';

  static Future<void> savePersonaSessionId(int personaId, String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personaSessionKey(personaId), sessionId);
  }

  static Future<String?> getPersonaSessionId(int personaId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_personaSessionKey(personaId));
  }

  static Future<bool> hasPersonaSession(int personaId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_personaSessionKey(personaId));
  }

  static Future<void> clearAllPersonaSessions() async {
    final prefs = await SharedPreferences.getInstance();
    for (int id = 1; id <= 8; id++) {
      await prefs.remove(_personaSessionKey(id));
    }
  }

  ///==== user id & email ====///
  static const _userIDkey = 'user_id';
  static const _userEmailkey = 'user_email';

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIDkey, userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIDkey);
  }

  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIDkey);
  }

  static Future<void> saveUserEmail(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailkey, userEmail);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailkey);
  }

  static Future<void> clearUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailkey);
  }

  /// ===== SUBSCRIPTION CHECK FLAG (IMPROVED WITH RETRY & FALLBACK) =====
  static const _subscriptionCheckDoneKey = 'subscription_check_done';

  // ✅ IMPROVED: Save with retry and verification
  static Future<void> saveSubscriptionCheckDone(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_subscriptionCheckDoneKey, value);

      if (success) {
        print('✅ Subscription check done flag saved: $value');
        // Also save to in-memory as backup
        _inMemorySubscriptionFlag = value;
      } else {
        print('❌ Failed to save subscription flag - attempting retry');
        // ✅ Retry once after delay
        await Future.delayed(Duration(milliseconds: 200));
        final retrySuccess = await prefs.setBool(_subscriptionCheckDoneKey, value);

        if (retrySuccess) {
          print('✅ Retry successful');
          _inMemorySubscriptionFlag = value;
        } else {
          print('❌ Retry failed - using in-memory fallback only');
          _inMemorySubscriptionFlag = value;
        }
      }
    } catch (e) {
      print('❌ Error saving subscription check done flag: $e');
      // ✅ Fallback to in-memory storage
      _inMemorySubscriptionFlag = value;
      print('⚠️ Using in-memory storage as fallback');
    }
  }

  // ✅ IMPROVED: Get with in-memory fallback
  static Future<bool?> getSubscriptionCheckDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_subscriptionCheckDoneKey);

      print('📋 Subscription check done flag from storage: $value');

      // ✅ If SharedPreferences returns null but we have in-memory value
      if (value == null && _inMemorySubscriptionFlag != null) {
        print('⚠️ Using in-memory fallback value: $_inMemorySubscriptionFlag');
        return _inMemorySubscriptionFlag;
      }

      // ✅ Sync in-memory with storage value
      if (value != null) {
        _inMemorySubscriptionFlag = value;
      }

      return value;
    } catch (e) {
      print('❌ Error getting subscription check done flag: $e');
      print('⚠️ Returning in-memory fallback: $_inMemorySubscriptionFlag');
      return _inMemorySubscriptionFlag;
    }
  }

  // ✅ NEW: Verify if flag was actually saved
  static Future<bool> verifySubscriptionFlagSaved(bool expectedValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actualValue = prefs.getBool(_subscriptionCheckDoneKey);

      final isVerified = actualValue == expectedValue;
      print('🔍 Verification: Expected=$expectedValue, Actual=$actualValue, Match=$isVerified');

      return isVerified;
    } catch (e) {
      print('❌ Error verifying subscription flag: $e');
      return false;
    }
  }

  // Clear subscription check done flag
  static Future<void> clearSubscriptionCheckFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subscriptionCheckDoneKey);
      _inMemorySubscriptionFlag = null; // Also clear in-memory
      print('✅ Subscription check flag cleared');
    } catch (e) {
      print('❌ Error clearing subscription check flag: $e');
    }
  }

  /// ===== CLEAR TOKENS =====

  //Clear login token
  static Future<void> clearLoginTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginAccessTokenKey);
    await prefs.remove(_loginRefreshTokenKey);
  }

  static Future<void> clearAllTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginAccessTokenKey);
    await prefs.remove(_loginRefreshTokenKey);
    await prefs.remove(_otpAccessTokenKey);
    await prefs.remove(_otpRefreshTokenKey);
    await prefs.remove(_resetAccessTokenKey);
    await prefs.remove(_resetRefreshTokenKey);
    await prefs.remove(_subscriptionCheckDoneKey);
    _inMemorySubscriptionFlag = null; // Clear in-memory on logout
  }
}