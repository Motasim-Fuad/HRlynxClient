
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(AppImages.splash,height: 250,),
              Container(
                child: Column(
                  children: [
                    Text(
                      'Welcome to your AI-powered',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 23,
                        color: Color(0xFF050505),
                      ),
                    ),
                    Text(" HR Assistant!",style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 23,
                      color: Color(0xFF050505),
                    ),),
                  ],
                ),
              ),

              const Spacer(),

              Container(
                child: Column(
                  children: [
                    const Text(
                      'Tailored for your role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF7D848D),
                      ),
                    ),

                    const Text(
                      'Built for your challenges.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF7D848D),
                      ),
                    ),

                  ],
                ),
              ),

              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 12,
                      width: 12,
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

              Button(title: 'Get Started',onTap: (){
                Get.offAll(SecondSplash());
              },),

            ],
          ),
        ),
      ),
    );
  }

}
