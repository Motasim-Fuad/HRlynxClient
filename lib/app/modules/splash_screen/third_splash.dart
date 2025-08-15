import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart' show Button;
import 'package:hr/app/common_widgets/splash_text.dart';
import 'package:hr/app/modules/onboarding/onboarding_view.dart' show OnboardingView;
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';

class ThirdSplash extends StatelessWidget {
  const ThirdSplash({super.key});

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
                // Image
                Image.asset(
                  AppImages.splash,
                  height: h * 0.25,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: h * 0.02),

                // Title
                Text(
                  'Interactive \nAI HR Assistants',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: h * 0.03,
                    color: AppColors.primarycolor,
                  ),
                ),

                SizedBox(height: h * 0.02),

                // Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: Text(
                    "Supportive, insightful HR guidance - powered by AI, designed for you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: h * 0.022,
                      color: const Color(0xFF393636),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.04),

                // Example Prompts Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Example Prompts',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: h * 0.023,
                      color: const Color(0xFF050505),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.015),

                // Prompt Examples
                SplashText(text: 'Prepare for a difficult conversation'),
                SizedBox(height: h * 0.008),
                SplashText(text: "What's new in California labor law?"),

                SizedBox(height: h * 0.03),

                // Footer text
                Text(
                  'Tailored by role (HRBP, TA, etc)',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: h * 0.02,
                    color: const Color(0xFF050505),
                  ),
                ),

                SizedBox(height: h * 0.1),

                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = index == 2;
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

                // Next button
                Button(
                  title: 'Next',
                  onTap: () {
                    Get.offAll( OnboardingView());
                  },
                ),

                SizedBox(height: h * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
