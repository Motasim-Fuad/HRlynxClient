import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';

class Changepasswordcontroller extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  var isObscuredNew = true.obs;
  var isObscuredConfirm = true.obs;

  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  final isLoading = false.obs;

  void toggleObscureTextNew() => isObscuredNew.value = !isObscuredNew.value;
  void toggleObscureTextConfirm() => isObscuredConfirm.value = !isObscuredConfirm.value;

  Future<void> changePassword() async {
    if (newPassword.text != confirmPassword.text) {
      Get.snackbar("Error", "New passwords do not match");
      return;
    }

    if (newPassword.text.length < 8) {
      Get.snackbar("Error", "Password must be at least 8 characters");
      return;
    }

    isLoading.value = true;
    final body = {
      "old_password": oldPassword.text.trim(),
      "new_password": newPassword.text.trim(),
      "new_password2": confirmPassword.text.trim(),
    };

    try {
      final response = await _authRepo.changePassword(body);

      if (response['success'] == true) {
        Get.snackbar("Success", "Password changed successfully");
        oldPassword.clear();
        newPassword.clear();
        confirmPassword.clear();
      } else {
        Get.snackbar("Error", response['message'] ?? 'Failed to change password');
        print("respose error : ${response['message']}");
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
      print("error :$e");
    } finally {
      isLoading.value = false;
    }
  }
}
