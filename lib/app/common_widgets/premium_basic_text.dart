import 'package:flutter/material.dart';
import 'package:hr/app/utils/app_colors.dart' show AppColors;

class PremiumBasicText extends StatelessWidget {
  const PremiumBasicText({super.key, required this.tittle});
  final String tittle;

  @override
  Widget build(BuildContext context) {
    // Get screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            color: AppColors.primarycolor,
            size: screenWidth * 0.05, // responsive icon size
          ),
          SizedBox(width: screenWidth * 0.02), // responsive spacing
          Expanded(
            child: Text(
              tittle,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: screenWidth * 0.04, // responsive font size
                color: const Color(0xFF050505),
              ),
              overflow: TextOverflow.ellipsis, // prevents overflow
            ),
          ),
        ],
      ),
    );
  }
}
