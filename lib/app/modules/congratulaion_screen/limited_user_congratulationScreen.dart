import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/modules/main_screen/main_screen_view.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class LimitedUserCongratulationScreen extends StatelessWidget {
  const LimitedUserCongratulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Close, but not quite unlocked…",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.brown.shade800,
                  ),
                ),

                const SizedBox(height: 30),


                Container(
                  child: Image(image: AssetImage(AppImages.limitated_Congratulation,),height: size.height * 0.25,),
                ),

                const SizedBox(height: 20),

                const Text(
                  "No worries, happy to serve you a\nless caffeinated experience!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "What leading professionals are\nleveraging to stay at the top of\ntheir HR game:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    BulletItem("HR QuickScan™ News Highlights"),
                    BulletItem("Expert AI HR Persona Suite"),
                    BulletItem("Priority Chat Access"),
                    BulletItem("Save & Revisit Conversations"),
                  ],
                ),

                const SizedBox(height: 40),

                const Text(
                  "Oops, take me back to unlock HRlynx",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 15),


                Button(title: "Continue with Limited Free Access",onTap: (){
                  Get.offAll(MainScreen());
                },),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BulletItem extends StatelessWidget {
  final String text;
  const BulletItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
