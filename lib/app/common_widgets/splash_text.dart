
import 'package:flutter/material.dart';
import 'package:hr/app/utils/app_colors.dart';

class SplashText extends StatelessWidget {
  const SplashText({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarycolor,
            ),
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF050505),
            ),
          ),
        ],
      ),
    );
  }
}
