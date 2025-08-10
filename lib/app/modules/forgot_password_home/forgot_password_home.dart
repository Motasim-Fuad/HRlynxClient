
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart' show Button;
import 'package:hr/app/modules/main_screen/main_screen_view.dart';

class ForgotPasswordHome extends StatelessWidget {
  const ForgotPasswordHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Password Reset",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 26,
              color: Color(0xff1B1E28),
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Text(
              'Your password has been successfully reset.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xff7D848D),
              ),
            ),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Get.to(MainScreen());
            },
            child: Button(title: 'Home'),
          ),
        ],
      ),
    );
  }
}
