import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/payment/payment_view.dart';
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';
import '../../model/onbordingModel.dart';
import '../log_in/log_in_view.dart';

class OtpController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final RxList<String> otpDigits = RxList<String>.filled(4, '');
  final RxString email = ''.obs;
  final RxInt timerSeconds = 86.obs;

  // Persona-related
  final RxList<Data> personaList = <Data>[].obs;
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = false.obs;

  late List<TextEditingController> otpTextControllers;
  late List<FocusNode> otpFocusNodes;
  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    otpTextControllers = List.generate(4, (_) => TextEditingController());
    otpFocusNodes = List.generate(4, (_) => FocusNode());
    _startTimer();
    fetchPersonas();
  }

  @override
  void onClose() {
    for (var controller in otpTextControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    _countdownTimer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void onOtpDigitChanged(String value, int index) {
    otpDigits[index] = value;
    if (value.length == 1 && index < otpTextControllers.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  void selectPersona(int index) {
    selectedIndex.value = index;
  }


  Future<void> fetchPersonas() async {
    try {
      isLoading.value = true;
      final response = await _authRepo.getParsonaType();
      print("📥 Raw persona response: $response");

      final model = OnbordingModel.fromJson(response);
      personaList.value = model.data ?? [];

      if (personaList.isEmpty) {
        print("⚠️ Persona list is empty after parsing");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      print("❌ fetchPersonas error: $e");
    } finally {
      isLoading.value = false;
    }
  }



  Future<void> submitSelectedPersona() async {
    try {
      isLoading.value = true;

      // Get the stored persona ID from onboarding
      final storedPersonaId = await TokenStorage.getSelectedPersonaId();

      if (storedPersonaId == null) {
        Get.snackbar("Error", "No persona selected in onboarding.");
        return;
      }

      final body = {
        "persona": storedPersonaId, // Use stored ID instead of current selection
      };

      print("📤 Sending stored persona ID to API: $body");

      final response = await _authRepo.setParsonaType(body);

      if (response['status'] == true || response['success'] == true) {
        print("✅ Persona selection success: ${response['message']}");
        Get.offAll(() => PaymentView());
      } else {
        print("❌ Persona API error: ${response['message']}");
        Get.snackbar("Error", response['message'] ?? "Failed to select persona");
      }
    } catch (e) {
      print("❌ Persona API exception: $e");
      Get.snackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> verifyOtp() async {
    final otp = otpDigits.join();
    if (otp.length != 4) {
      Get.snackbar("Error", "Enter 4-digit OTP");
      return;
    }

    try {
      isLoading.value = true;

      final body = {
        "email": email.value.trim(),
        "otp": otp,
      };

      final response = await _authRepo.singUpOtp(body);
      final message = response['message']?.toString().toLowerCase() ?? '';

      if (message.contains("success") || message.contains("verified")) {
        if (response.containsKey("access") && response.containsKey("refresh")) {
          await TokenStorage.saveOtpTokens(response["access"], response["refresh"]);
          await TokenStorage.saveLoginTokens(response["access"], response["refresh"]);
        }

        Get.snackbar("Success", response['message']);
        await submitSelectedPersona();
      } else {
        Get.snackbar("Failed", response['message'] ?? "OTP verification failed");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false; // ✅ Ensure this always runs
    }
  }

  void resendCode() async {
    if (timerSeconds.value == 0) {
      try {
        final resendBody = {
          "email": email.value.trim(),
          "purpose": "verification",
        };

        final response = await _authRepo.resendOtp(resendBody);

        if (response['success'] == true ||
            (response['message']?.toString().toLowerCase().contains('sent') ?? false)) {
          Get.snackbar("OTP Resent", response['message']);
          print("✅ Resend success: ${response['message']}");
        } else {
          Get.snackbar("Failed", response['message'] ?? "Failed to resend OTP");
          print("❌ Resend error: ${response['message']}");
        }
      } catch (e) {
        Get.snackbar("Error", "Failed to resend OTP: ${e.toString()}");
        print("❌ Resend exception: $e");
      }

      timerSeconds.value = 86;
      _startTimer();
      for (var controller in otpTextControllers) {
        controller.clear();
      }
      otpDigits.assignAll(List.filled(4, ''));
      otpFocusNodes[0].requestFocus();
    }
  }
}
