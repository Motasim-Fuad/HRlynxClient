import 'dart:io';

import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api_Constant.dart';
import '../neteork_api_services.dart';
import '../token.dart';

class AuthRepository {
  final _api = NetworkApiServices();

  final userController = Get.put(UserController());

  // ---------- Persona ----------
  Future<dynamic> getParsonaType() async {
    String url = "${ApiConstants.baseUrl}/api/aipersona/personas/";

    try {
      // Use the retry mechanism for CloudFlare issues
      return await NetworkApiServices.getApiWithRetry(
        url,
        withAuth: false,
        maxRetries: 3,
        retryDelay: Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ Final error after retries: $e');

      // Provide user-friendly error message
      if (e.toString().contains('CloudFlare') ||
          e.toString().contains('523') ||
          e.toString().contains('tunnel')) {
        throw Exception('Connection issue detected. Please check your internet connection and try again.');
      }

      rethrow;
    }
  }

  Future<dynamic> setParsonaType(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/aipersona/select-persona/";
    return await NetworkApiServices.postApi(url, body, withAuth: true, tokenType: 'login');
  }

  // ---------- Auth ----------
  Future<dynamic> login(String email, String password) async {
    final body = {
      "email": email,
      "password": password,
    };
    String url = "${ApiConstants.baseUrl}/api/auth/login/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }

  Future<dynamic> signup(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/register/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }

  Future<dynamic> singUpOtp(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/verify-email/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }

  Future<dynamic> resendOtp(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/resend-otp/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }

  // ---------- Logout ----------
  Future<dynamic> LogOut() async {
    String url = "${ApiConstants.baseUrl}/api/auth/logout/";

    // Get the refresh token first
    final refreshToken = await TokenStorage.getLoginRefreshToken();

    // Ensure it's not null
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception("No refresh token found for logout.");
    }

    // Send it in the body as expected by backend
    final body = {
      "refresh": refreshToken,
    };

    return await NetworkApiServices.postApi(
      url,
      body,
      withAuth: true,
      tokenType: 'login',
    );
  }



  // ---------- Forgot Password ----------
  Future<dynamic> forgotPassword(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/password/reset-request/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }

  Future<dynamic> forgotPasswordOtpVeryfication(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/password/reset-verify-otp/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }

  Future<dynamic> updatePassword(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/password/reset-confirm/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }
  Future<dynamic> resendForgotPasswordOtp(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/resend-otp/";
    return await NetworkApiServices.postApi(url, body, withAuth: false);
  }

// ---------- Social SignUp (Google & Apple) ----------
  Future<bool> SocialSignUpAndSetPersona({
    required String email,
    required String name,
    required String provider,
  }) async {
    try {
      final url = "${ApiConstants.baseUrl}/api/auth/social-auth/";
      final body = {
        "email": email,
        "name": name,
        "provider": provider,
      };

      print("📤 Sending social login payload: $body");

      final response = await NetworkApiServices.postApi(url, body, withAuth: false);

      final data = response['data'];
      final access = data['access'];
      final refresh = data['refresh'];
      final user = data['user'];
      final userEmail = user['email'];
      final userID = user['id'];


      userController.setUserEmail(userEmail);
      userController.setUserID(userID);

      await TokenStorage.saveLoginTokens(access, refresh);
      return true;
    } catch (e) {
      print('❌ googleSignUpAndSetPersona Error: $e');
      return false;
    }
  }

  // ---------- Profile ----------
  Future<dynamic> getUserProfile() async {
    String url = "${ApiConstants.baseUrl}/api/profile/";
    return await NetworkApiServices.getApi(url, tokenType: 'login');
  }

  Future<dynamic> updateUserProfile(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/profile/update/";
    return await NetworkApiServices.putApi(url, body, tokenType: 'login');
  }

  Future<dynamic> deleteAccount() async {
    String url = "${ApiConstants.baseUrl}/api/auth/delete/";
    return await NetworkApiServices.deleteApi(url, tokenType: 'login');
  }

  Future<dynamic> changePassword(Map<String, dynamic> body) async {
    String url = "${ApiConstants.baseUrl}/api/auth/password/change/";
    return await NetworkApiServices.postApi(
      url,
      body,
      withAuth: true,
      tokenType: 'login', // Use access token from login
    );
  }


  Future<dynamic> uploadProfileData(Map<String, dynamic> body, {File? imageFile}) async {
    String url = "${ApiConstants.baseUrl}/api/auth/profile/";

    // Remove image path from body if it exists
    Map<String, dynamic> cleanBody = Map.from(body);
    cleanBody.remove('profile_picture');

    return await NetworkApiServices.postMultipartApi(
      url,
      cleanBody,
      imageFile: imageFile,
      imageFieldName: 'profile_picture',
      withAuth: true,
      tokenType: 'login',
    );
  }
  Future<dynamic> fetchProfileData() async {
    String url = "${ApiConstants.baseUrl}/api/auth/profile/"; // This is correct!
    return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
  }

// ---------- home ----------
      //---For Chat Start
  Future<dynamic> getAllAiPersona() async {
    String url = "${ApiConstants.baseUrl}/api/aipersona/personas/";
    return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
  }


  Future<String?> createSession(int personaId) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/chat/sessions/create/";

      final body = {
        "persona_id": personaId,
      };

      final response = await NetworkApiServices.postApi(
        url,
        body,
        withAuth: true,
        tokenType: 'login',
      );

      print('✅ Session creation response: $response');

      if (response != null &&
          response['session'] != null &&
          response['session']['id'] != null) {
        return response['session']['id'].toString();
      } else {
        throw Exception('Invalid session response format');
      }
    } catch (e) {
      print('❌ Error creating session: $e');
      return null;
    }
  }

      //---For Chat end


// ---------- chat ----------
  Future<dynamic> AiSuggestions(int  personaId) async {
    String url = "${ApiConstants.baseUrl}/api/chat/suggestions/?persona_id=$personaId";
    return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
  }

  Future<dynamic> fetchPersonaChatHistory(int  personaId) async {
    String url = "${ApiConstants.baseUrl}/api/chat/personas/$personaId/sessions/";
    return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
  }


  Future<dynamic> fetchSessionsDetails(int sessionId) async {  // 👈 CHANGE TO STRING
    print("fuadAuth1");
    final url = "${ApiConstants.baseUrl}/api/chat/sessions/$sessionId/";
    print("fuadAuth2");
    print('🌐 Fetching session details for: $url');
    print("fuadAuth3");

    try {
      print("fuadAuth4");
      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
      print("fuadAuth5");
      print('✅ Session details response: $response');
      print("fuadAuth6$response");
      return response;

    } catch (e) {
      print("fuadAuth7");
      print('❌❌❌❌❌❌❌❌ Error fetching session details: $e');
      return null;
    }
  }


  Future<dynamic> deleteHistory(int  session_id) async {
    String url = "${ApiConstants.baseUrl}/api/chat/sessions/${session_id}/delete/";
    return await NetworkApiServices.deleteApi(url, withAuth: true, tokenType: 'login');
  }




// ---------- Subscription & Payment Methods ----------
  Future<dynamic> createSetupIntent() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/payment/setup-intent/";
      print('🔗 Creating setup intent at: $url');

      final response = await NetworkApiServices.postApi(url, {}, withAuth: true, tokenType: 'login');

      if (response != null) {
        print('✅ Setup intent response: $response');
      }

      return response;
    } catch (e) {
      print('❌ Error creating setup intent: $e');
      rethrow;
    }
  }


  // Add this updated method to your AuthRepository class

  Future<dynamic> cancelSubscription() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/cancel/";
      print('🔗 Cancelling subscription: $url');

      final response = await NetworkApiServices.postApi(
        url,
        {}, // Empty body or add if required
        withAuth: true,
        tokenType: 'login',
      );

      if (response != null) {
        print('✅ Cancel subscription response: $response');
        // Don't show snackbar here - let the controller handle UI feedback
        return response;
      }

      return response;
    } catch (e) {
      print('❌ Error cancelling subscription: $e');
      // Don't show snackbar here - let the controller handle error feedback
      rethrow; // Re-throw the error so controller can handle it
    }
  }


  Future<dynamic> addPaymentMethod(String paymentMethodId) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/payment/add-method/";
      final body = {
        "payment_method_id": paymentMethodId,
      };

      print('🔗 Adding payment method at: $url');
      print('📤 Request body: $body');

      final response = await NetworkApiServices.postApi(url, body, withAuth: true, tokenType: 'login');

      if (response != null) {
        print('✅ Add payment method response: $response');
      }

      return response;
    } catch (e) {
      print('❌ Error adding payment method: $e');
      rethrow;
    }
  }

  Future<dynamic> createSubscription(String planType, String paymentMethodId) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/create/";
      final body = {
        "plan_type": planType,
        "payment_method_id": paymentMethodId,
      };

      print('🔗 Creating subscription at: $url');
      print('📤 Request body: $body');

      final response = await NetworkApiServices.postApi(url, body, withAuth: true, tokenType: 'login');

      if (response != null) {
        print('✅ Create subscription response: $response');
      }

      return response;
    } catch (e) {
      print('❌ Error creating subscription: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> checkExistingPlans() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/setup/check-plans/";
      print('🔗 Checking existing plans at: $url');

      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');

      if (response != null) {
        print('✅ Check plans response: $response');
      }

      return response;
    } catch (e) {
      print('❌ Error checking existing plans: $e');
      return null;
    }
  }

  Future<dynamic> checkSubscriptionStatus() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/status/";
      print('🔗 Checking subscription status at: $url');

      final response = await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');

      if (response != null) {
        print('✅ Subscription status response: $response');
      }

      return response;
    } catch (e) {
      print('❌ Error checking subscription status: $e');
      rethrow;
    }
  }


  Future<dynamic> reactivateSubscription() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/reactivate/";
      print('🔗 Reactivating subscription: $url');

      final response = await NetworkApiServices.postApi(
        url,
        {}, // Empty body or add required parameters
        withAuth: true,
        tokenType: 'login',
      );

      if (response != null) {
        print('✅ Reactivate subscription response: $response');
        return response;
      }

      return response;
    } catch (e) {
      print('❌ Error reactivating subscription: $e');
      rethrow; // Re-throw the error so controller can handle it
    }
  }

// Payment methods management
  Future<dynamic> getPaymentMethods() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/payment/methods/";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('❌ Error getting payment methods: $e');
      return null;
    }
  }

  Future<dynamic> deletePaymentMethod(String paymentMethodId) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/subscription/payment/methods/$paymentMethodId/delete/";
      return await NetworkApiServices.deleteApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('❌ Error deleting payment method: $e');
      return null;
    }
  }


  Future<dynamic> fetchUserIsSubcribed() async {
    try {
      String url = "${ApiConstants.baseUrl}/api/aipersona/available-personas/";
      return await NetworkApiServices.getApi(url, withAuth: true, tokenType: 'login');
    } catch (e) {
      print('❌ Error is_subcribed auth method : $e');
      return null;
    }
  }

  // ---------- Terms & Conditions ----------
  Future<dynamic> getTermsAndConditions() async {
    String url = "${ApiConstants.baseUrl}/api/core/terms-and-conditions/";
    try {
      return await NetworkApiServices.getApi(url, withAuth: false);
    } catch (e) {
      print('❌ Error fetching terms and conditions: $e');
      rethrow;
    }
  }

  // ---------- Privacy Policy ----------
  Future<dynamic> getPrivacyPolicy() async {
    String url = "${ApiConstants.baseUrl}/api/core/privacy-policy/";
    try {
      return await NetworkApiServices.getApi(url, withAuth: false);
    } catch (e) {
      print('❌ Error fetching privacy policy: $e');
      rethrow;
    }
  }



// In auth_repo.dart - Replace the existing getAffiliateProducts method

  Future<Map<String, dynamic>> getAffiliateProducts({
    required String categorySlug,
    int page = 1,  // Add page parameter for pagination
  }) async {
    try {
      // Use the correct endpoint format from your API
      String url = "${ApiConstants.baseUrl}/api/affiliate/products/?category_slug=$categorySlug";

      // Add page parameter if not first page
      if (page > 1) {
        url += "&page=$page";
      }

      print('🔗 Fetching affiliate products from: $url');

      final response = await NetworkApiServices.getApi(
          url,
          withAuth: true,
          tokenType: 'login'
      );

      if (response != null) {
        print('✅ Affiliate products response: $response');
        return {
          'success': true,
          'data': response,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch affiliate products - no response',
        };
      }
    } catch (e) {
      print('❌ Error fetching affiliate products: $e');
      return {
        'success': false,
        'error': 'Error fetching affiliate products: $e',
      };
    }
  }

// Track click count
  Future<Map<String, dynamic>> trackClick(int product) async {
    try {
      String url = "${ApiConstants.baseUrl}/api/affiliate/track-click/";
      final body = {
        'product': product,
      };

      print('🔗 Tracking click for product: $product');
      print('📤 Request body: $body');

      final response = await NetworkApiServices.postApi(
          url,
          body,
          withAuth: true,
          tokenType: 'login'
      );

      if (response != null) {
        print('✅ Track click response: $response');
        return {
          'success': true,
          'data': response,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to track click',
        };
      }
    } catch (e) {
      print('❌ Error tracking click: $e');
      return {
        'success': false,
        'error': 'Error tracking click: $e',
      };
    }
  }
}
