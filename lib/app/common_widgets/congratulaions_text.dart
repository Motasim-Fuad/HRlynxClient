import 'package:flutter/material.dart';
import 'package:hr/app/common_widgets/premium_basic_text.dart' show PremiumBasicText;
import 'package:hr/app/utils/app_colors.dart' show AppColors;

class CongratulaionsText extends StatelessWidget {
  const CongratulaionsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Benefits Unlocked',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF333333),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        PremiumBasicText(tittle: 'AI-Summarized News Highlights'),
        SizedBox(height: 12),
        PremiumBasicText(tittle: 'Access to Expert AI HR Persona Suite'),
        SizedBox(height: 12),
        PremiumBasicText(tittle: 'High-Volume Chat Access'),
        SizedBox(height: 12),
        PremiumBasicText(tittle: 'Save Conversations'),
        SizedBox(height: 32),
        Text(
          "Time to perk up your HR game, you're fully unlocked!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: AppColors.primarycolor,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}