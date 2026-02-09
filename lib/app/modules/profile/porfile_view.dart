import 'dart:io';
import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/modules/privacy_policy/privacy_policy.dart';
import 'package:HRlynx/app/modules/change_password/change_password.dart';
import 'package:HRlynx/app/modules/home/user_isSubcriptionController.dart';
import 'package:HRlynx/app/modules/log_in/user_controller.dart';
import 'package:HRlynx/app/modules/notification/notification_view.dart';
import 'package:HRlynx/app/modules/payment/subcription_view.dart';
import 'package:HRlynx/app/modules/profile/deleteAccountHepler.dart';
import 'package:HRlynx/app/modules/profile/profile_controller.dart';
import 'package:HRlynx/app/modules/terms_of_use/terms_of_use.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'UploadData/uploadDataView.dart';
import 'UploadData/upload_data_binding.dart';
import 'logoutHelper.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final UserController userController = Get.put(UserController());
  final ProfileController profileController = Get.put(ProfileController(),);
  final LogoutController logoutController = Get.put(LogoutController());
  final DeleteAccountController deleteAccountController = Get.put(DeleteAccountController()); // 👈 Add this
  final UserIsSubcribedController subController = Get.put(UserIsSubcribedController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile',style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          GestureDetector(
            child: SvgPicture.asset(AppImages.edit_profile),
            onTap: () async {
              final result = await Get.to(
                    () => UploadDataView(),
                binding: UploadDataBinding(),
              );

              if (result == true) {
                await profileController.refreshProfile();
              }

            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Obx(() {
        if (profileController.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarycolor),
                ),
                SizedBox(height: 16),
                Text('Loading profile...'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            print("🔄 Pull-to-refresh triggered");
            await profileController.refreshProfile();
          },
          color: Colors.blue,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 16),
              children: [
                SizedBox(height: 10),

                // Profile Picture
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildProfilePicture(),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Name
                Center(
                  child: Text(
                    profileController.userName.value.isNotEmpty
                        ? profileController.userName.value
                        : 'Your Name',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: profileController.userName.value.isNotEmpty
                          ? Color(0xFF1B1E28)
                          : Colors.grey,
                    ),
                  ),
                ),

                SizedBox(height: 4),
                // Email
                Center(
                  child: Text(
                    profileController.userEmail.value.isNotEmpty
                        ? profileController.userEmail.value
                        : userController.userEmail.string.isNotEmpty
                        ? userController.userEmail.string
                        : "email@example.com",
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Subscription Status Section
                Obx(() {
                  if (subController.isSubscribed.value) {
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0F5351), Color(0xFF02A69D)],

                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'To manage or cancel your subscription, please visit:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      Platform.isIOS ? 'App Store → Subscriptions' : 'Play Store → Subscriptions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Button(
                          title: 'Subscribe Now',
                          onTap: () => Get.to(SubscriptionScreen()),
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  }
                }),

                // Menu Items
                _buildMenuItem(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  onTap: () => Get.to(NotificationView()),
                ),

                _buildMenuItem(
                  icon: Icons.local_police_outlined,
                  title: 'Privacy Policy',
                  onTap: () => Get.to(PrivacyPolicy()),
                ),

                _buildMenuItem(
                  icon: Icons.insert_drive_file_outlined,
                  title: 'Terms of Use',
                  onTap: () => Get.to(TermsOfUse()),
                ),

                _buildMenuItem(
                  icon: Icons.lock_outline_sharp,
                  title: 'Change Password',
                  onTap: () => Get.to(ChangePassword()),
                ),

                // Delete Account - 👈 Updated this
                _buildMenuItem(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  titleColor: Color(0xffD40606),
                  iconColor: Color(0xffD40606),
                  onTap: () {
                    if(subController.isSubscribed.value == true){
                      Get.snackbar('Delete Account', 'You can not delete your account because you are subscribed to our service. Please unsubscribe first.');
                    }else{
                      _showDeleteAccountDialog(context);
                    }
                  }  // 👈 Changed function
                ),

                // Logout Item
                _buildMenuItem(
                  icon: Icons.logout_outlined,
                  title: 'Log out',
                  titleColor: Color(0xffD40606),
                  iconColor: Color(0xffD40606),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Build Profile Picture with CachedNetworkImage
  Widget _buildProfilePicture() {
    if (profileController.userProfilePicture.value.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: profileController.userProfilePicture.value,
      width: 120,
      height: 120,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarycolor),
              ),
              SizedBox(height: 8),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('❌ Failed to load profile image: $error');
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: Colors.red.shade400,
              ),
              SizedBox(height: 4),
              Text(
                'Failed to\nload image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  profileController.refreshProfile();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      fadeInDuration: Duration(milliseconds: 300),
      fadeOutDuration: Duration(milliseconds: 100),
    );
  }

  // Build Menu Item Widget
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Colors.black87,
            fontWeight: titleColor != null ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // 👇 NEW: Delete Account Dialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,

      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading dialog
              Get.dialog(
                Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                          SizedBox(height: 16),
                          Text('Deleting account...'),
                        ],
                      ),
                    ),
                  ),
                ),
                barrierDismissible: false,
              );

              // Call delete account function
              await deleteAccountController.deleteAccount();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show Logout Confirmation Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Column(
          children: [
            Icon(
              Icons.logout_outlined,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Log Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              Get.dialog(
                Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarycolor),
                          ),
                          SizedBox(height: 16),
                          Text('Logging out...'),
                        ],
                      ),
                    ),
                  ),
                ),
                barrierDismissible: false,
              );

              await logoutController.logout();
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Log Out",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}