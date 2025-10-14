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

  /// ===== SUBSCRIPTION CHECK FLAG (NEW) =====
  // ✅ Subscription check flag
  static const _subscriptionCheckDoneKey = 'subscription_check_done';
  // Save subscription check done flag
  static Future<void> saveSubscriptionCheckDone(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_subscriptionCheckDoneKey, value);
      print('✅ Subscription check done flag saved: $value');
    } catch (e) {
      print('❌ Error saving subscription check done flag: $e');
    }
  }

  // Get subscription check done flag
  static Future<bool?> getSubscriptionCheckDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_subscriptionCheckDoneKey);
      print('📋 Subscription check done flag: $value');
      return value;
    } catch (e) {
      print('❌ Error getting subscription check done flag: $e');
      return null;
    }
  }

  // Clear subscription check done flag
  static Future<void> clearSubscriptionCheckFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subscriptionCheckDoneKey);
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
    // ✅ Also clear subscription check flag on logout
    await prefs.remove(_subscriptionCheckDoneKey);
  }
}