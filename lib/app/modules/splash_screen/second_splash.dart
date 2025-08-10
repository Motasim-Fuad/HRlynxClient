
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/splash_text.dart';
import 'package:hr/app/modules/splash_screen/third_splash.dart' show ThirdSplash;
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';
import 'package:hr/app/utils/app_text.dart';

class SecondSplash extends StatelessWidget {
  const SecondSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(AppImages.splash, height: 170,),
            Text(
              'Personalized ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 32,
                color: AppColors.primarycolor,
              ),
            ),   Text(
              'News Feed',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 32,
                color: AppColors.primarycolor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              AppText.secondsplash,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF050505),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Breaking News on Important HR Topics:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(0xFF050505),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),
            SplashText(text: 'HR Strategy & Leadership'),
            SplashText(text: 'Workforce Compliance & Regulation'),
            SplashText(text: 'Talent Acquisition & Labor Trends'),
            SplashText(text: 'Compensation, Benefits & Rewards'),
            SplashText(text: 'People Development & Culture'),


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
            Button(title: 'Next',onTap: (){ Get.offAll(ThirdSplash());},),
          ],
        ),
      ),
    );
  }
}
