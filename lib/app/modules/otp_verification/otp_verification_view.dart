import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/modules/otp_verification/otp_verification_controller.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OtpVerificationScreen extends StatelessWidget {
  OtpVerificationScreen({super.key});

  final OtpController otpController = Get.put(OtpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoints
          final isTablet = constraints.maxWidth > 600;
          final isDesktop = constraints.maxWidth > 1024;

          // Responsive values
          final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 24.0 : 8.0);
          final topSpacing = isDesktop ? 140.0 : (isTablet ? 130.0 : 120.0);
          final titleFontSize = isDesktop ? 28.0 : (isTablet ? 26.0 : 24.0);
          final subtitleFontSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
          final labelFontSize = isDesktop ? 20.0 : (isTablet ? 19.0 : 18.0);
          final otpBoxWidth = isDesktop ? 90.0 : (isTablet ? 80.0 : 70.0);
          final otpFontSize = isDesktop ? 28.0 : (isTablet ? 26.0 : 24.0);
          final textFontSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
          final resendFontSize = isDesktop ? 22.0 : (isTablet ? 21.0 : 20.0);

          // Center content on larger screens
          final maxWidth = isDesktop ? 600.0 : double.infinity;

          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: topSpacing),

                      Text(
                        'OTP Verification',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: isDesktop ? 15 : (isTablet ? 12 : 10)),

                      Obx(
                            () => Text(
                          'Please check your email ${otpController.email.value} to find the verification code',
                          style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: Colors.grey[700]
                          ),
                          softWrap: true,
                          maxLines: 4,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: isDesktop ? 50 : (isTablet ? 45 : 40)),

                      Text(
                        'OTP Code',
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: isDesktop ? 20 : (isTablet ? 18 : 15)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          return SizedBox(
                            width: otpBoxWidth,
                            child: TextField(
                              controller: otpController.otpTextControllers[index],
                              focusNode: otpController.otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                fontSize: otpFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                counterText: "",
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 20 : (isTablet ? 18 : 16),
                                ),
                              ),
                              onChanged: (value) =>
                                  otpController.onOtpDigitChanged(value, index),
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: isDesktop ? 50 : (isTablet ? 45 : 40)),

                      Obx(() => Button(
                        title: 'Verify',
                        onTap: () => otpController.verifyOtp(),
                        isLoading: otpController.isLoading.value,
                      )),

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
                            String minutes = (otpController.timerSeconds.value ~/ 60)
                                .toString()
                                .padLeft(2, '0');
                            String seconds = (otpController.timerSeconds.value % 60)
                                .toString()
                                .padLeft(2, '0');
                            return Text(
                              '$minutes:$seconds',
                              style: TextStyle(
                                fontSize: textFontSize,
                                color: otpController.timerSeconds.value == 0
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
                        onPressed: otpController.timerSeconds.value == 0
                            ? () {
                          otpController.resendCode();
                        }
                            : null,
                        child: Text(
                          'Resend code',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: resendFontSize,
                            color: otpController.timerSeconds.value == 0
                                ? AppColors.primarycolor
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
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