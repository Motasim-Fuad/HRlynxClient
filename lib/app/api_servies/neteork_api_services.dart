// ==========================================
// 1️⃣ UPDATED: lib/app/api_servies/neteork_api_services.dart
// Better error messages for different scenarios
// ==========================================
import 'dart:convert';
import 'dart:io';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/log_in/log_in_view.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

class NetworkApiServices {
  static Future<String?> getToken(String tokenType) async {
    switch (tokenType) {
      case 'otp':
        return await TokenStorage.getOtpAccessToken();
      case 'reset':
        return await TokenStorage.getResetAccessToken();
      case 'login':
      default:
        return await TokenStorage.getLoginAccessToken();
    }
  }

  static Future<Map<String, String>> getHeaders({
    bool withAuth = true,
    String tokenType = 'login',
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await getToken(tokenType);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// GET request
  static Future<dynamic> getApi(
      String url, {
        bool withAuth = true,
        String tokenType = 'login',
      }) async {
    try {
      final headers = await getHeaders(withAuth: withAuth, tokenType: tokenType);
      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('NETWORK_ERROR');
    } on HttpException {
      throw Exception('NETWORK_ERROR');
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  static Future<dynamic> postApi(
      String url,
      dynamic body, {
        bool withAuth = true,
        String tokenType = 'login',
      }) async {
    try {
      final headers = await getHeaders(withAuth: withAuth, tokenType: tokenType);
      final response = await http.post(
          Uri.parse(url),
          body: jsonEncode(body),
          headers: headers
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('NETWORK_ERROR');
    } on HttpException {
      throw Exception('NETWORK_ERROR');
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  static Future<dynamic> putApi(
      String url,
      dynamic body, {
        bool withAuth = true,
        String tokenType = 'login',
      }) async {
    try {
      final headers = await getHeaders(withAuth: withAuth, tokenType: tokenType);
      final response = await http.put(
          Uri.parse(url),
          body: jsonEncode(body),
          headers: headers
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('NETWORK_ERROR');
    } on HttpException {
      throw Exception('NETWORK_ERROR');
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH request
  static Future<dynamic> patchApi(
      String url,
      dynamic body, {
        bool withAuth = true,
        String tokenType = 'login',
      }) async {
    try {
      final headers = await getHeaders(withAuth: withAuth, tokenType: tokenType);
      final response = await http.patch(
          Uri.parse(url),
          body: jsonEncode(body),
          headers: headers
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('NETWORK_ERROR');
    } on HttpException {
      throw Exception('NETWORK_ERROR');
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  static Future<dynamic> deleteApi(
      String url, {
        dynamic body,
        bool withAuth = true,
        String tokenType = 'login',
      }) async {
    try {
      final headers = await getHeaders(withAuth: withAuth, tokenType: tokenType);

      print('🔍 DELETE URL: $url');
      print('📦 DELETE Body: ${body != null ? jsonEncode(body) : "null"}');
      print('🔑 DELETE Headers: $headers');

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('NETWORK_ERROR');
    } on HttpException {
      throw Exception('NETWORK_ERROR');
    } catch (e) {
      rethrow;
    }
  }

  /// Multipart request
  static Future<dynamic> postMultipartApi(
      String url,
      Map<String, dynamic> fields, {
        File? imageFile,
        String imageFieldName = 'profile_picture',
        bool withAuth = true,
        String tokenType = 'access',
      }) async {
    try {
      print('🌐 Multipart POST URL: $url');
      print('📤 Fields: $fields');
      print('🖼️ Image: ${imageFile?.path}');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      if (withAuth) {
        String? token = await TokenStorage.getLoginAccessToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      fields.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (imageFile != null && imageFile.existsSync()) {
        String fileName = imageFile.path.split('/').last;
        String fileExtension = fileName.split('.').last.toLowerCase();

        MediaType mediaType;
        switch (fileExtension) {
          case 'jpg':
          case 'jpeg':
            mediaType = MediaType('image', 'jpeg');
            break;
          case 'png':
            mediaType = MediaType('image', 'png');
            break;
          case 'gif':
            mediaType = MediaType('image', 'gif');
            break;
          case 'webp':
            mediaType = MediaType('image', 'webp');
            break;
          default:
            mediaType = MediaType('image', 'jpeg');
        }

        var multipartFile = await http.MultipartFile.fromPath(
          imageFieldName,
          imageFile.path,
          contentType: mediaType,
          filename: fileName,
        );

        request.files.add(multipartFile);
        print('✅ Image file added: $fileName (${mediaType.toString()})');
      }

      print('🚀 Sending multipart request...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('🔎 Response Code: ${response.statusCode}');
      print('📦 Raw Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        print('✅ Multipart Success: $responseData');
        return responseData;
      } else {
        var errorData = jsonDecode(response.body);
        print('❌ Multipart Error: $errorData');
        throw Exception('API Error: ${errorData['message'] ?? 'Unknown error'}');
      }
    } on SocketException {
      throw Exception('NETWORK_ERROR');
    } on HttpException {
      throw Exception('NETWORK_ERROR');
    } catch (e) {
      print('❌ Multipart Exception: $e');
      rethrow;
    }
  }

  /// Retry mechanism for CloudFlare issues
  static Future<dynamic> getApiWithRetry(
      String url, {
        bool withAuth = true,
        String tokenType = 'login',
        int maxRetries = 3,
        Duration retryDelay = const Duration(seconds: 2),
      }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final headers = await getHeaders(withAuth: withAuth, tokenType: tokenType);
        final response = await http.get(Uri.parse(url), headers: headers);
        return _handleResponse(response);
      } on SocketException {
        if (attempt == maxRetries) {
          throw Exception('NETWORK_ERROR');
        }
        print('⏳ Network error, retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      } catch (e) {
        print('🔄 Attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          rethrow;
        }

        if (e.toString().contains('CloudFlare') ||
            e.toString().contains('523') ||
            e.toString().contains('tunnel') ||
            e.toString().contains('HTML instead of JSON')) {
          print('⏳ Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
        } else {
          rethrow;
        }
      }
    }
    throw Exception('Max retries reached');
  }

  /// ✅ NEW: Force logout and navigate to login
  static Future<void> _handleUnauthorized() async {
    try {
      print('🚨 401 Unauthorized - Forcing logout...');

      await TokenStorage.clearAllTokens();
      await TokenStorage.clearAllPersonaSessions();

      Get.snackbar(
        "Session Expired",
        "Your session has expired. Please login again.",
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3),
      );

      Get.offAll(() => LogInView());

    } catch (e) {
      print('❌ Error during forced logout: $e');
    }
  }

  /// ✅ UPDATED: Handle response with proper error messages
  static dynamic _handleResponse(http.Response response) {
    print('🔎 Response Code: ${response.statusCode}');
    print('📦 Raw Response Body: ${response.body}');

    try {
      // ✅ Handle 401 Unauthorized - AUTO LOGOUT
      if (response.statusCode == 401) {
        Future.microtask(() => _handleUnauthorized());
        throw Exception('Session expired. Please login again.');
      }

      // Handle successful responses (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {'success': true, 'message': 'Request completed successfully'};
        }
        return jsonDecode(response.body);
      }

      if (response.statusCode == 400) {
        throw Exception('Validation Error or you give common password when you create account');
      }

      // ✅ Handle 429 - Rate Limit
      if (response.statusCode == 429) {
        throw Exception('AI usage limit exceeded. Please check your plan or billing.');
      }

      // ✅ Handle 500 Internal Server Error
      if (response.statusCode == 500) {
        throw Exception('SERVER_ERROR');
      }

      // ✅ Handle 503 Service Unavailable
      if (response.statusCode == 503) {
        throw Exception('SERVER_ERROR');
      }

      // ✅ Handle CloudFlare specific errors
      if (response.statusCode == 523) {
        throw Exception('SERVER_ERROR');
      }

      if (response.statusCode >= 520 && response.statusCode <= 530) {
        throw Exception('SERVER_ERROR');
      }

      // Check if response is HTML (CloudFlare error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html')) {
        throw Exception('SERVER_ERROR');
      }

      // Handle other error responses
      if (response.body.isNotEmpty) {
        try {
          final responseBody = jsonDecode(response.body);
          final errorMsg = responseBody['message'] ??
              responseBody['detail'] ??
              responseBody['error'] ??
              'Unknown error (${response.statusCode})';
          throw Exception('API Error: $errorMsg');
        } catch (jsonError) {
          throw Exception('SERVER_ERROR');
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw FormatException('Unexpected response format: ${response.body}');
    }
  }

  static bool isSuccessResponse(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static bool isTokenExpiredResponse(http.Response response) {
    return response.statusCode == 401 ||
        (response.body.contains('token') && response.body.contains('expired'));
  }
}