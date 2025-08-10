
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/text_field.dart';
import 'package:hr/app/modules/change_password/changePasswordController.dart';

class ChangePassword extends StatelessWidget {
   ChangePassword({super.key});
  final Changepasswordcontroller controller = Get.put(Changepasswordcontroller());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 120),
              Text(
                'Change Password',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  color: Color(0xFF1B1E28),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'The password must be different than previous',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF7D848D),
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Enter your old password'),
                ],
              ),
              SizedBox(height: 5,),
              Obx(
                () => CustomTextFormField(
                  controller: controller.oldPassword,
                  hintText: 'Old Password',
                  keyboardType: TextInputType.text,
                  obscureText: controller.isObscuredNew.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isObscuredNew.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: controller.toggleObscureTextNew,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Enter your new password'),
                ],
              ),
              SizedBox(height: 5,),
              Obx(
                () => CustomTextFormField(
                  controller: controller.newPassword,
                  hintText: 'New Password',
                  keyboardType: TextInputType.text,
                  obscureText: controller.isObscuredConfirm.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isObscuredConfirm.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: controller.toggleObscureTextConfirm,
                  ),
                ),
              ),

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Confirm enter your  new password'),
                ],
              ),
              SizedBox(height: 5,),
              Obx(
                () => CustomTextFormField(
                  controller: controller.confirmPassword,
                  hintText: 'Confirm Password',
                  keyboardType: TextInputType.text,
                  obscureText: controller.isObscuredConfirm.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isObscuredConfirm.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: controller.toggleObscureTextConfirm,
                  ),
                ),
              ),

              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Password must be 8 character'),
                ],
              ),
              SizedBox(height: 30),
              Obx(() => Button(
                title: controller.isLoading.value ? 'Loading...' : 'Continue',
                onTap: controller.isLoading.value ? null : controller.changePassword,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
