import 'package:HRlynx/app/modules/home/home_view.dart';
import 'package:HRlynx/app/modules/main_screen/main_screen_controller.dart';
import 'package:HRlynx/app/modules/news/news_view.dart';
import 'package:HRlynx/app/modules/profile/porfile_view.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainScreen extends StatelessWidget {
  final BottomNavController navController = Get.put(BottomNavController());

  final List<Widget> screens = [
    HomeView(),
    NewsView(),
    ProfileView(),
  ];

  // Keep tab screens in memory.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() => IndexedStack(
        index: navController.currentIndex.value,
        children: screens,
      )),
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: navController.currentIndex.value,
          onTap: navController.changeTab,
          selectedItemColor: AppColors.primarycolor,
          unselectedItemColor: Color(0xFF8E8E93),
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
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
