import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/modules/splash_screen/second_splash.dart';
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart' show AppImages;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
                SizedBox(height: h * 0.05),

                // Responsive Image
                Image.asset(
                  AppImages.splash,
                  height: h * 0.28,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: h * 0.04),

                // Title
                Column(
                  children: [
                    Text(
                      'Welcome to your AI-powered',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: h * 0.028,
                        color: AppColors.primarycolor,
                      ),
                    ),
                    Text(
                      'HR Assistant!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: h * 0.028,
                        color: AppColors.primarycolor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.04),

                // Sub Text
                Column(
                  children: [
                    Text(
                      'Tailored for your role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: h * 0.02,
                        color: const Color(0xFF7D848D),
                      ),
                    ),
                    Text(
                      'Built for your challenges.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: h * 0.02,
                        color: const Color(0xFF7D848D),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.2),

                // Indicator Dots
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
                          color: index == 0
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
                  title: 'Get Started',
                  onTap: () {
                    Get.offAll(const SecondSplash());
                  },
                ),

                SizedBox(height: h * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
