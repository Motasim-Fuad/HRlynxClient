import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/premium_basic_text.dart' show PremiumBasicText;
import 'package:hr/app/utils/app_colors.dart' show AppColors;
import 'package:hr/app/utils/app_images.dart';

class CongratulationView extends StatelessWidget {
  const CongratulationView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive padding and sizing
    final horizontalPadding = screenWidth * 0.08; // 8% of screen width
    final titleFontSize = screenWidth * 0.055; // Responsive title size
    final subtitleFontSize = screenWidth * 0.045; // Responsive subtitle size
    final bodyFontSize = screenWidth * 0.04; // Responsive body text size

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.17),
            Image(image: AssetImage(AppImages.coffee)),
            
            Text("Congratulations!",style: TextStyle(fontWeight: FontWeight.bold,fontSize: screenWidth *0.1),),
            SizedBox(height: screenHeight *0.05,),
            // Benefits Unlocked Title
            Text(
              'Benefits Unlocked',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: titleFontSize.clamp(18.0, 24.0),
                color: Color(0xFF2D2D2D),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
      
            SizedBox(height: screenHeight * 0.02),
      
            // Benefits List
            Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.9,
              ),
              child: Column(
                children: [
                  PremiumBasicText(tittle: 'AI-Summarized News Highlights'),
                  SizedBox(height: screenHeight * 0.015),
                  PremiumBasicText(tittle: 'Access to Expert AI HR Persona Suite'),
                  SizedBox(height: screenHeight * 0.015),
                  PremiumBasicText(tittle: 'High-Volume Chat Access'),
                  SizedBox(height: screenHeight * 0.015),
                  PremiumBasicText(tittle: 'Save Conversations'),
                  PremiumBasicText(tittle: 'Save Conversations'),
                ],
              ),
            ),
      
            SizedBox(height: screenHeight * 0.04),
      
            // Bottom motivational text
            Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.85,
              ),
              child: Text(
                "Time to perk up your HR game, you're fully unlocked!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: bodyFontSize.clamp(14.0, 18.0),
                  color: AppColors.primarycolor,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            Spacer(),
            Button(title: "home",onTap: (){
              Get.to(MiniStream());
            },),
            // Additional spacing for different screen sizes
            SizedBox(height: screenHeight * 0.01),
          ],
        ),
      ),
    );
  }
}