import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/splash_text.dart';
import 'package:hr/app/modules/splash_screen/third_splash.dart';
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.05,
              vertical: h * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // SizedBox(height: h * 0.05),

                // Responsive Image
                Image.asset(
                  AppImages.splash,
                  height: h * 0.22,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: h * 0.03),

                // Headings
                Text(
                  'Breaking News with',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: h * 0.03,
                    color: AppColors.primarycolor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'AI-powered HR QuickScan™',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: h * 0.03,
                    color: AppColors.primarycolor,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: h * 0.03),

                // Description
                Text(
                  'Overwhelmed by HR news? HR QuickScan™ gives you the essentials in seconds so you can move from reading to doing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: h * 0.02,
                    color: const Color(0xFF050505),
                  ),
                ),

                SizedBox(height: h * 0.03),

                // Subheading
                Text(
                  'Breaking News on Important HR Topics:',
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
                SizedBox(height: h * 0.008),
                SplashText(text: 'Workforce Compliance & Regulation'),
                SizedBox(height: h * 0.008),
                SplashText(text: 'Talent Acquisition & Labor Trends'),
                SizedBox(height: h * 0.008),
                SplashText(text: 'Compensation, Benefits & Rewards'),
                SizedBox(height: h * 0.008),
                SplashText(text: 'People Development & Culture'),

                SizedBox(height: h * 0.01),

                // Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = index == 1;
                    return Padding(
                      padding: EdgeInsets.all(w * 0.015),
                      child: Container(
                        height: h * 0.015,
                        width: h * 0.015,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
