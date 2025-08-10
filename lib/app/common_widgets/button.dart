
import 'package:flutter/material.dart';
import 'package:hr/app/utils/app_colors.dart';

class Button extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isLoading; // 👈 NEW PARAMETER

  const Button({
    Key? key,
    required this.title,
    this.onTap,
    this.isLoading = false, // 👈 default false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap, // disable when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarycolor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}


