
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/modules/reset_password/reset_password_controller.dart' show ResetPasswordController;

class ResetPassword extends StatelessWidget {
  final ResetPasswordController controller = Get.put(ResetPasswordController());

  ResetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Reset password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: Color(0xFF1B1E28),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'The password must be different than previous',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF7D848D),
                ),
              ),
              const SizedBox(height: 30),

              // New Password Field
              Obx(() => TextFormField(
                obscureText: controller.isObscuredNew.value,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  suffixIcon: IconButton(
                    icon: Icon(controller.isObscuredNew.value
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: controller.toggleObscureTextNew,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.newPassword.value = value,
              )),

              const SizedBox(height: 20),

              // Confirm Password Field
              Obx(() => TextFormField(
                obscureText: controller.isObscuredConfirm.value,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter password',
                  suffixIcon: IconButton(
                    icon: Icon(controller.isObscuredConfirm.value
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: controller.toggleObscureTextConfirm,
                  ),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.confirmPassword.value = value,
              )),

              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Password must be at least 8 characters'),
              ),

              const SizedBox(height: 30),

              Obx(() =>  Button(
                title: "Update Password",
                isLoading: controller.isLoading.value,
                onTap: (){
                  controller.updatePassword();
                },),
              )
            ],
          ),
        ),
      ),
    );
  }
}


