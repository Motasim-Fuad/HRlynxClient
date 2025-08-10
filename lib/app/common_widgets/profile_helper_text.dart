import 'package:flutter/material.dart';

class ProfileHelp extends StatelessWidget {
  const ProfileHelp({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xff7D848D)),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
            ],
          ),
          Icon(Icons.arrow_forward_ios_outlined, size: 16),
        ],
      ),
    );
  }
}
