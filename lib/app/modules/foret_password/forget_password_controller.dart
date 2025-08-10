import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api_servies/repository/auth_repo.dart';

class ForgetPasswordController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  RxString email = ''.obs;
  RxBool isLoading = false.obs;

  Future<void> submitForgotPassword() async {
    if (email.value.isEmpty || !GetUtils.isEmail(email.value)) {
      Get.snackbar('Error', 'Please enter a valid email address',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    try {
      final response = await _authRepository.forgotPassword({'email': email.value});

      if (response['success'] == true) {
        Get.snackbar('Success', response['message'] ?? 'Reset link sent',
            backgroundColor: Colors.green, colorText: Colors.white);
        // Optionally navigate or reset input
      } else {
        Get.snackbar('Failed', response['message'] ?? 'Something went wrong',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
