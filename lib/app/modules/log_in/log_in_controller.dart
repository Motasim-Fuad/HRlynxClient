import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/notification_services.dart';
import 'package:hr/app/modules/log_in/user_controller.dart' show UserController;
import '../../api_servies/repository/auth_repo.dart';
import '../../api_servies/token.dart';
import '../main_screen/main_screen_view.dart';

class LogInController extends GetxController {
  final userController = Get.put(UserController());
  final AuthRepository authRepo = AuthRepository();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isObscured = true.obs;
  final isChecked = false.obs;
  final isLoading = false.obs;

  // Generate a unique key each time
  late final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Clear form when controller is initialized
    emailController.clear();
    passwordController.clear();
    isChecked.value = false;
  }

  void toggleObscureText() {
    isObscured.value = !isObscured.value;
  }

  void toggleCheckbox(bool? value) {
    isChecked.value = value ?? false;
  }

  Future<void> loginUser() async {
    if (!formKey.currentState!.validate()) return;

    if (!isChecked.value) {
      Get.snackbar("Terms Not Accepted", "Please agree to the Terms and Privacy Policy");
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      isLoading.value = true;
      final response = await authRepo.login(email, password);

      final data = response['data'];
      final access = data?['access'];
      final refresh = data?['refresh'];

      userController.setUserEmail(email);

      if (access != null && refresh != null) {
        await TokenStorage.saveLoginTokens(access, refresh);
        await initializeNotificationService();
        Get.snackbar("Success", response['message'] ?? "Login successful");
        Get.to(() => MainScreen());
      } else {
        Get.snackbar("Failed", "Login token missing.");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initializeNotificationService() async {
    try {
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService());
      }
      final notificationService = NotificationService.instance;
      await notificationService.enableConnection();
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }
}