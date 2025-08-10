import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/text_field.dart';

import 'package:hr/app/modules/foret_password/forget_password_controller.dart' show ForgetPasswordController;

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 150),

              const Text(
                'Forgot Password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: Color(0xFF1B1E28),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Enter your email account to reset\nyour password',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF7D848D),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Your Email',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xff050505),
                ),
              ),

              const SizedBox(height: 10),

              CustomTextFormField(
                controller: emailController,
                hintText: 'Please enter your email',
                keyboardType: TextInputType.emailAddress,
                obscureText: false,
                onChanged: (val) => controller.email.value = val,
              ),

              const SizedBox(height: 30),

              Obx(() {
                return Button(
                  onTap: controller.submitForgotPassword,
                  title: 'Send Reset Link',
                  isLoading: controller.isLoading.value,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
