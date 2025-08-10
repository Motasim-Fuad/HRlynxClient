import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../reset_password/reset_password_view.dart';

class ForgotPassOtpController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final email = ''.obs;
  final otpDigits = RxList<String>.filled(4, '');
  final timerSeconds = 60.obs;
  final isLoading = false.obs;

  late List<TextEditingController> otpControllers;
  late List<FocusNode> otpFocusNodes;
  Timer? _timer;

  @override
  void onInit() {
    // Receive email from Get.arguments
    email.value = Get.arguments ?? '';

    otpControllers = List.generate(4, (_) => TextEditingController());
    otpFocusNodes = List.generate(4, (_) => FocusNode());
    _startTimer();
    super.onInit();
  }

  @override
  void onClose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    super.onClose();
  }

  void _startTimer() {
    _timer?.cancel();
    timerSeconds.value = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void onOtpDigitChanged(String value, int index) {
    otpDigits[index] = value;
    if (value.isNotEmpty && index < otpControllers.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> resendCode() async {
    try {
      isLoading.value = true;

      final body = {
        "email": email.value.trim(),
        "purpose": "password_reset",
      };

      final response = await _authRepo.resendForgotPasswordOtp(body);

      if (response['success'] == true) {
        Get.snackbar("Success", response['message'] ?? "OTP resent successfully");
        _startTimer(); // 🔁 Restart the timer
      } else {
        Get.snackbar("Failed", response['message'] ?? "Failed to resend OTP");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      print("❌ Resend OTP error: $e");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> verifyOtp() async {
    String otp = otpDigits.join();
    if (otp.length != 4) {
      Get.snackbar("Error", "Please enter the 4-digit OTP");
      return;
    }

    try {
      isLoading.value = true; // 👈 Start loading

      final body = {
        "email": email.value.trim(),
        "otp": otp,
      };

      final response = await _authRepo.forgotPasswordOtpVeryfication(body);

      if (response['success'] == true) {
        Get.snackbar("Success", response['message']);
        Get.to(() => ResetPassword(), arguments: {
          "email": email.value.trim(),
          "otp": otp,
        });
      } else {
        Get.snackbar("Failed", response['message'] ?? "OTP verification failed");
        print("faild res: ${response['message']}");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      print("error :$e");
    } finally {
      isLoading.value = false; // 👈 Stop loading
    }
  }




}
