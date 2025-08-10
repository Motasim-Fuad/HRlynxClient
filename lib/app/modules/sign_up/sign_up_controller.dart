import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../otp_verification/otp_verification_controller.dart';
import '../otp_verification/otp_verification_view.dart';

class SignUpController extends GetxController {
  final AuthRepository authRepo = AuthRepository();

  var email = ''.obs;
  var password = ''.obs;
  var confirmPassword = ''.obs;
  var isChecked = false.obs;
  var isLoading = false.obs;

  // Generate a unique key each time
  late final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Clear form when controller is initialized
    email.value = '';
    password.value = '';
    confirmPassword.value = '';
    isChecked.value = false;
  }

  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
  }

  Future<void> signUpUser() async {
    if (!formKey.currentState!.validate()) return;

    if (!isChecked.value) {
      Get.snackbar("Error", "Please agree to Terms & Privacy Policy");
      return;
    }

    if (password.value != confirmPassword.value) {
      Get.snackbar("Error", "Passwords do not match");
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "email": email.value.trim(),
        "password": password.value.trim(),
        "password2": confirmPassword.value.trim(),
      };

      final response = await authRepo.signup(body);

      if (response['success'] == true) {
        Get.snackbar("Success", response['message']);
        final otpController = Get.put(OtpController());
        otpController.email.value = email.value;
        Get.to(() => OtpVerificationScreen());
      } else {
        Get.snackbar("Failed", response['message'] ?? "Signup failed");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}