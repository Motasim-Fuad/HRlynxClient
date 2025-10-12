import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/common_widgets/splash_text.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(height: h * 0.02),

              // Logo
              Image.asset(
                AppImages.splash,
                height: h * 0.25,
                fit: BoxFit.contain,
              ),

              SizedBox(height: h * 0.01),

              // Headings
              Text(
                'Get News with AI-powered HR QuickScan™',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: h * 0.028,
                  color: AppColors.primarycolor,
                ),
              ),

              SizedBox(height: h * 0.02),

              // Description
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

              SizedBox(height: h * 0.02),

              // Subheading
              Text(
                'Catch-up on Important HR Topics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: h * 0.023,
                  color: const Color(0xFF050505),
                ),
              ),

              SizedBox(height: h * 0.015),

              // Splash Text Items
              SplashText(text: 'HR Strategy & Leadership'),
              SplashText(text: 'Workforce Compliance & Regulation'),
              SplashText(text: 'Talent Acquisition & Labor Trends'),
              SplashText(text: 'Compensation, Benefits & Rewards'),
              SplashText(text: 'People Development & Culture'),

              Spacer(),

              // Page indicators
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

              // Button
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
      ),
    );
  }
}
