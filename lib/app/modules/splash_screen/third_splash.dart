import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/modules/onboarding/onboarding_view.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                padding: EdgeInsets.symmetric(horizontal: w * 0.08),
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

              SizedBox(height: h * 0.03),






              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 300), // Controls width, keeps center
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Left align each bullet line
                    children: [
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
                      buildSplashText('Prepare for a difficult conversation'),
                      buildSplashText("What's new in California labor law?"),


                    ],
                  ),
                ),
              ),
              // Prompt Examples


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
                        color: index == 2
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
                  Get.offAll(OnboardingView());
                },
              ),

              SizedBox(height: h * 0.01),
            ],
          ),
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
