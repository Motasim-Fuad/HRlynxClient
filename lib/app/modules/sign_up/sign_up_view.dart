import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart' show Button;
import 'package:hr/app/common_widgets/text_field.dart';
import 'package:hr/app/modules/log_in/log_in_view.dart';
import 'package:hr/app/modules/sign_up/sign_up_controller.dart' show SignUpController;

import '../../utils/app_colors.dart' show AppColors;

class PasswordController extends GetxController {
  var isObscured = true.obs;

  void toggleObscureText() {
    isObscured.value = !isObscured.value;
  }
}

class SignUp extends StatefulWidget {
  SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  late PasswordController passwordcontroller;
  late SignUpController signUpController;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Clean up existing controllers if they exist
    if (Get.isRegistered<PasswordController>()) {
      Get.delete<PasswordController>();
    }
    if (Get.isRegistered<SignUpController>()) {
      Get.delete<SignUpController>();
    }

    // Create fresh controllers
    passwordcontroller = Get.put(PasswordController(), permanent: false);
    signUpController = Get.put(SignUpController(), permanent: false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Obx(() {
        return Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: signUpController.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: screenWidth < 600 ? 60 : 90),
                          const Center(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 26,
                                color: Color(0xFF1B1E28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              'Please complete and create account',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF7D848D),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),

                          _label("Your Email"),
                          CustomTextFormField(
                            controller: emailController,
                            hintText: 'arraihan815@gmail.com',
                            keyboardType: TextInputType.emailAddress,
                            obscureText: false,
                            onChanged: (value) => signUpController.email.value = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              } else if (!GetUtils.isEmail(value.trim())) {
                                return 'Invalid email format';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _label("Password"),
                          Obx(() => CustomTextFormField(
                            controller: passwordController,
                            hintText: 'Enter your new Password',
                            keyboardType: TextInputType.text,
                            obscureText: passwordcontroller.isObscured.value,
                            suffixIcon: IconButton(
                              icon: Icon(passwordcontroller.isObscured.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: passwordcontroller.toggleObscureText,
                            ),
                            onChanged: (value) =>
                            signUpController.password.value = value,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              } else if (value.length < 8) {
                                return 'Minimum 8 characters required';
                              }
                              return null;
                            },
                          )),

                          const SizedBox(height: 20),

                          _label("Confirm Password"),
                          Obx(() => CustomTextFormField(
                            controller: confirmPasswordController,
                            hintText: 'Re-enter Password',
                            keyboardType: TextInputType.text,
                            obscureText: passwordcontroller.isObscured.value,
                            suffixIcon: IconButton(
                              icon: Icon(passwordcontroller.isObscured.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: passwordcontroller.toggleObscureText,
                            ),
                            onChanged: (value) =>
                            signUpController.confirmPassword.value = value,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              return null;
                            },
                          )),

                          const SizedBox(height: 10),
                          const Text('Password must be 8 characters'),

                          const SizedBox(height: 20),

                          // Terms
                          Row(
                            children: [
                              Obx(() => Checkbox(
                                value: signUpController.isChecked.value,
                                onChanged: signUpController.toggleCheckbox,
                              )),
                              const Flexible(
                                child: Wrap(
                                  children: [
                                    Text('I agree to the '),
                                    Text(
                                      'Terms of Use',
                                      style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: AppColors.primarycolor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(' and '),
                                    Text(
                                      'Privacy Policy.',
                                      style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          color: AppColors.primarycolor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Button(
                            title: 'Sign Up',
                            onTap: signUpController.signUpUser,
                            isLoading: signUpController.isLoading.value,
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () {
                                  // Clean up current controllers before navigating
                                  Get.delete<PasswordController>();
                                  Get.delete<SignUpController>();
                                  Get.to(() => LogInView());
                                },
                                child: Text(
                                  'Log In',
                                  style: TextStyle(color: AppColors.primarycolor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _label(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xff050505),
          ),
        ),
      ],
    );
  }
}