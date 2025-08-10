
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(AppImages.splash, height: 200, ),
            Text(
              textAlign: TextAlign.center,
              'Interactive \nAI HR Assistants',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 25,
                color: AppColors.primarycolor,
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 0),
              child: Text(
                "Supportive, insightful HR guidance - powered by AI, designed for you.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                  color: Color(0xFF393636),
                ),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Example Prompts',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Color(0xFF050505),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            SplashText(text: 'Prepare for a difficult conversation'),
            SplashText(text: "What's new in California labor law?"),

            SizedBox(height: 30),
            Text(
              'Tailored by role (HRBP, TA, etc)',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF050505),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffE6ECEB),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffE6ECEB),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primarycolor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffE6ECEB),
                    ),
                  ),
                ),
              ],
            ),
            Button(title: 'Next',onTap: (){
              Get.offAll(OnboardingView());
            },),

          ],
        ),
      ),
    );
  }
}
