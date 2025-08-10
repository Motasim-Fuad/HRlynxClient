import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/privacy_policy.dart' show PrivacyPolicy;
import 'package:hr/app/common_widgets/text_field.dart';
import 'package:hr/app/modules/foret_password/forget_password_view.dart';
import 'package:hr/app/modules/log_in/log_in_controller.dart';
import 'package:hr/app/modules/sign_up/sign_up_view.dart' show SignUp;
import 'package:hr/app/modules/terms_of_use/terms_of_use.dart' show TermsOfUse;
import 'package:hr/app/utils/app_colors.dart' show AppColors;
import 'package:hr/app/utils/app_images.dart';

import 'googleSingUpController.dart';

class LogInView extends StatefulWidget {
  const LogInView({super.key});

  @override
  State<LogInView> createState() => _LogInViewState();
}

class _LogInViewState extends State<LogInView> {
  late LogInController controller;
  late GoogleSignUpController googleSignUpController;

  @override
  void initState() {
    super.initState();

    // Clean up existing controllers if they exist
    if (Get.isRegistered<LogInController>()) {
      Get.delete<LogInController>();
    }
    if (Get.isRegistered<GoogleSignUpController>()) {
      Get.delete<GoogleSignUpController>();
    }

    // Create fresh controllers
    controller = Get.put(LogInController(), permanent: false);
    googleSignUpController = Get.put(GoogleSignUpController(), permanent: false);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth < 500 ? double.infinity : 400,
                ),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: height * 0.1),
                      const Text(
                        'Log In',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 26),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Please log in to continue',
                        style: TextStyle(fontSize: 16, color: Color(0xFF7D848D)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      _buildLabel('Your Email'),
                      CustomTextFormField(
                        controller: controller.emailController,
                        hintText: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          } else if (!GetUtils.isEmail(value.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Password'),
                      Obx(() => CustomTextFormField(
                        controller: controller.passwordController,
                        hintText: 'Password',
                        obscureText: controller.isObscured.value,
                        keyboardType: TextInputType.text,
                        suffixIcon: IconButton(
                          icon: Icon(controller.isObscured.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: controller.toggleObscureText,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          } else if (value.length < 6) {
                            return 'Minimum 6 characters required';
                          }
                          return null;
                        },
                      )),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Get.to(() => ForgetPassword()),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primarycolor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Terms
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Obx(() => Checkbox(
                            value: controller.isChecked.value,
                            onChanged: controller.toggleCheckbox,
                            activeColor: AppColors.primarycolor,
                          )),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('I agree to the '),
                                GestureDetector(
                                  onTap: () => Get.to(() => TermsOfUse()),
                                  child: Text(
                                    'Terms of Use',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: AppColors.primarycolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Text(' and '),
                                GestureDetector(
                                  onTap: () => Get.to(() => PrivacyPolicy()),
                                  child: Text(
                                    'Privacy Policy.',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: AppColors.primarycolor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Login Button
                      Obx(() => Button(
                        title: 'Log In',
                        isLoading: controller.isLoading.value,
                        onTap: controller.loginUser,
                      )),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              // Clean up current controllers before navigating
                              Get.delete<LogInController>();
                              Get.delete<GoogleSignUpController>();
                              Get.to(() => SignUp());
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(color: AppColors.primarycolor),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        'Or connect',
                        style: TextStyle(fontSize: 14, color: Color(0xFF707B81)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => print("Apple tapped"),
                            child: Image.asset(AppImages.apple, height: 40),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => googleSignUpController.handleGoogleSignUp(),
                            child: Image.asset(AppImages.google, height: 40),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Color(0xff050505),
        ),
      ),
    );
  }
}