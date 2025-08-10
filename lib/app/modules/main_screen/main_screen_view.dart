
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/modules/home/home_view.dart';
import 'package:hr/app/modules/main_screen/main_screen_controller.dart';
import 'package:hr/app/modules/news/news_view.dart';
import 'package:hr/app/modules/profile/porfile_view.dart';
import 'package:hr/app/utils/app_colors.dart' show AppColors;

class MainScreen extends StatelessWidget {
  final BottomNavController navController = Get.put(BottomNavController());

  final List<Widget> screens = [
    HomeView(),
    // CahtView(),
    NewsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => screens[navController.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: navController.currentIndex.value,
          onTap: navController.changeTab,
          selectedItemColor: AppColors.primarycolor,
          unselectedItemColor: Color(0xFF8E8E93),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.chat_outlined),
            //   label: 'Chat',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_rounded),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_3),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
