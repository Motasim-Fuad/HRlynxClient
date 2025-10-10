import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/modules/splash_screen/second_splash.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Top spacing
              SizedBox(height: h * 0.02),

              // Logo
              Image.asset(
                AppImages.splash,
                height: h * 0.25, // responsive height
                fit: BoxFit.contain,
              ),

              SizedBox(height: h * 0.04),

              // Title
              Text(
                'Welcome to your AI-powered\nHR Assistant!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: h * 0.028,
                  color: AppColors.primarycolor,
                ),
              ),

              SizedBox(height: h * 0.02),

              // Subtitle
              Text(
                'Tailored for your role. Built for your challenges.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: h * 0.02,
                  color: const Color(0xFF7D848D),
                ),
              ),

              Spacer(), // pushes button to bottom

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

              SizedBox(height: h * 0.01),
            ],
          ),
        ),
      ),
    );
  }
}
