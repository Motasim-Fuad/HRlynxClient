import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/modules/splash_screen/third_splash.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SecondSplash extends StatelessWidget {
  const SecondSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double h = size.height;
    final double w = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(height: h * 0.02),
                  Image.asset(
                    AppImages.splash,
                    height: h * 0.25,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Text(
                      'Get News with AI-powered HR QuickScan™',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: h * 0.028,
                        color: AppColors.primarycolor,
                      ),
                    ),

                    SizedBox(height: h * 0.01),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                      child: Text(
                        'Who has time to read everything these days? HR QuickScan™ cuts through the noise, providing critical and useful HR news insights - stay informed and increase your impact.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: h * 0.02,
                          color: const Color(0xFF050505),
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.015),

                    Text(
                      'Catch-up on Important HR Topics',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: h * 0.023,
                        color: const Color(0xFF050505),
                      ),
                    ),

                    SizedBox(height: h * 0.01),

                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSplashText('HR Strategy & Leadership'),
                            buildSplashText('Workforce Compliance & Regulation'),
                            buildSplashText('Talent Acquisition & Labor Trends'),
                            buildSplashText('Compensation, Benefits & Rewards'),
                            buildSplashText('People Development & Culture'),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: h * 0.02),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Padding(
                        padding: EdgeInsets.all(w * 0.015),
                        child: Container(
                          height: h * 0.015,
                          width: h * 0.015,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == 1
                                ? AppColors.primarycolor
                                : const Color(0xffE6ECEB),
                          ),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: h * 0.03),

                  Button(
                    title: 'Next',
                    onTap: () {
                      Get.offAll(const ThirdSplash());
                    },
                  ),

                  SizedBox(height: h * 0.01),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSplashText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarycolor,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF050505),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
