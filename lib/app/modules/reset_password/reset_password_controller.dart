import 'package:HRlynx/app/modules/log_in/log_in_view.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';

class ResetPasswordController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final newPassword = ''.obs;
  final confirmPassword = ''.obs;
  final isLoading = false.obs;

  final isObscuredNew = true.obs;
  final isObscuredConfirm = true.obs;

  void toggleObscureTextNew() => isObscuredNew.toggle();
  void toggleObscureTextConfirm() => isObscuredConfirm.toggle();

  Future<void> updatePassword() async {
    try {
      final args = Get.arguments;
      if (args == null || args['email'] == null || args['otp'] == null) {
        throw Exception('Email and OTP are required');
      }

      if (newPassword.value.isEmpty || confirmPassword.value.isEmpty) {
        throw Exception('Please enter both passwords');
      }

      if (newPassword.value != confirmPassword.value) {
        throw Exception('Passwords do not match');
      }

      if (newPassword.value.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }

      isLoading.value = true;

      final body = {
        "email": args['email'],
        "otp": args['otp'],
        "new_password": newPassword.value,
        "new_password2": confirmPassword.value,
      };

      final response = await _authRepo.updatePassword(body);

      if (response['success'] == true) {
        Get.snackbar("Success", response['message'] ?? "Password updated successfully");
        Get.off(LogInView());
      } else {
        throw Exception(response['message'] ?? "Failed to update password");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
