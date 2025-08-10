import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import 'forgetPassWordOtpController.dart';
import '../../common_widgets/button.dart';

class Forgotpassotpview extends StatelessWidget {
  Forgotpassotpview({super.key});

  final ForgotPassOtpController controller = Get.put(ForgotPassOtpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Text(
              "Enter the OTP sent to your email",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    controller: controller.otpControllers[index],
                    focusNode: controller.otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onChanged: (val) =>
                        controller.onOtpDigitChanged(val, index),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Obx((){
              return Button(title: 'Verify OTP',
                onTap: controller.verifyOtp,
                isLoading: controller.isLoading.value,
              );
            }),


            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Click Resend Code after '),
                Obx(() {
                  String minutes = (controller.timerSeconds.value ~/ 60)
                      .toString()
                      .padLeft(2, '0');
                  String seconds = (controller.timerSeconds.value % 60)
                      .toString()
                      .padLeft(2, '0');
                  return Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.timerSeconds.value == 0
                          ? AppColors.primarycolor
                          : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }),
                Text(" Seconds"),
              ],

            ),
            Obx(() => TextButton(
              onPressed: controller.timerSeconds.value == 0
                  ? () {
                controller.resendCode();
              }
                  : null, // Disable button if timer is not zero
              child: Text(
                'Resend code',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  fontSize: 16,
                  color: controller.timerSeconds.value == 0
                      ? AppColors.primarycolor
                      : Colors.grey, // dim the text color when inactive
                  fontWeight: FontWeight.w400,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

