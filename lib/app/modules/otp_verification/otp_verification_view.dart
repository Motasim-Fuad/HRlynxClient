
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/modules/otp_verification/otp_verification_controller.dart';
import 'package:hr/app/utils/app_colors.dart';


class OtpVerificationScreen extends StatelessWidget {
  OtpVerificationScreen({super.key, });

  final OtpController otpController = Get.put(OtpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 120),
              const Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => Text(
                  'Please check your email ${otpController.email.value} to find the verification code',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  softWrap: true,
                  maxLines: 4,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'OTP Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 70,
                    child: TextField(
                      controller: otpController.otpTextControllers[index],
                      focusNode: otpController.otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        counterText: "",
                      ),
                      onChanged: (value) =>
                          otpController.onOtpDigitChanged(value, index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              // Wrapped your Button widget with InkWell
              Obx(() => Button(
                title: 'Verify',
                onTap: () => otpController.verifyOtp(),
                isLoading: otpController.isLoading.value,
              )),//

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Click Resend Code after '),
                  Obx(() {
                    String minutes = (otpController.timerSeconds.value ~/ 60)
                        .toString()
                        .padLeft(2, '0');
                    String seconds = (otpController.timerSeconds.value % 60)
                        .toString()
                        .padLeft(2, '0');
                    return Text(
                      '$minutes:$seconds',
                      style: TextStyle(
                        fontSize: 16,
                        color: otpController.timerSeconds.value == 0
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
                onPressed: otpController.timerSeconds.value == 0
                    ? () {
                  otpController.resendCode();
                }
                    : null, // Disable button if timer is not zero
                child: Text(
                  'Resend code',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 20,
                    color: otpController.timerSeconds.value == 0
                        ? AppColors.primarycolor
                        : Colors.grey, // dim the text color when inactive
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
