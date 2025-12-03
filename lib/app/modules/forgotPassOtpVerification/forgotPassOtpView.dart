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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoints
          final isTablet = constraints.maxWidth > 600;
          final isDesktop = constraints.maxWidth > 1024;

          // Responsive values
          final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 32.0 : 24.0);
          final topSpacing = isDesktop ? 100.0 : (isTablet ? 90.0 : 80.0);
          final titleFontSize = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);
          final otpBoxWidth = isDesktop ? 80.0 : (isTablet ? 70.0 : 60.0);
          final otpBoxSpacing = isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0);
          final textFontSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);

          // Center content on larger screens
          final maxWidth = isDesktop ? 600.0 : double.infinity;

          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      SizedBox(height: topSpacing),

                      Text(
                        "Enter the OTP sent to your email",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: titleFontSize,
                            color: Colors.grey[700]
                        ),
                      ),

                      SizedBox(height: isDesktop ? 50 : (isTablet ? 45 : 40)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: otpBoxSpacing / 2
                            ),
                            child: SizedBox(
                              width: otpBoxWidth,
                              child: TextField(
                                controller: controller.otpControllers[index],
                                focusNode: controller.otpFocusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                                  fontWeight: FontWeight.bold,
                                ),
                                onChanged: (val) =>
                                    controller.onOtpDigitChanged(val, index),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: isDesktop ? 20 : (isTablet ? 18 : 16),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: isDesktop ? 40 : (isTablet ? 35 : 30)),

                      Obx(() {
                        return Button(
                          title: 'Verify OTP',
                          onTap: controller.verifyOtp,
                          isLoading: controller.isLoading.value,
                        );
                      }),

                      SizedBox(height: isDesktop ? 30 : (isTablet ? 25 : 20)),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            'Click Resend Code after ',
                            style: TextStyle(fontSize: textFontSize),
                          ),
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
                                fontSize: textFontSize,
                                color: controller.timerSeconds.value == 0
                                    ? AppColors.primarycolor
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }),
                          Text(
                            ' Seconds',
                            style: TextStyle(fontSize: textFontSize),
                          ),
                        ],
                      ),

                      Obx(() => TextButton(
                        onPressed: controller.timerSeconds.value == 0
                            ? () {
                          controller.resendCode();
                        }
                            : null,
                        child: Text(
                          'Resend code',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: textFontSize,
                            color: controller.timerSeconds.value == 0
                                ? AppColors.primarycolor
                                : Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )),

                      SizedBox(height: isDesktop ? 40 : (isTablet ? 30 : 20)),
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
}