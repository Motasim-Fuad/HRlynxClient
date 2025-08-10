import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/privacy_policy.dart';
import 'package:hr/app/modules/change_password/change_password.dart' show ChangePassword;
import 'package:hr/app/modules/home/chat_al_ai_persona_controller.dart';
import 'package:hr/app/modules/home/user_isSubcriptionController.dart';
import 'package:hr/app/modules/log_in/user_controller.dart';
import 'package:hr/app/modules/notification/notification_view.dart';
import 'package:hr/app/modules/payment/payment_view.dart';
import 'package:hr/app/modules/profile/UploadData/uploadDataView.dart';
import 'package:hr/app/modules/profile/profile_controller.dart' show ProfileController;
import 'package:hr/app/modules/terms_of_use/terms_of_use.dart';
import 'package:hr/app/utils/app_images.dart';
import 'logoutHelper.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final UserController userController = Get.put(UserController());
  final ProfileController profileController = Get.put(ProfileController());
  final LogoutController logoutController = Get.put(LogoutController());
  final UserIsSubcribedController subController = Get.put(UserIsSubcribedController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
        actions: [
          GestureDetector(
            child: SvgPicture.asset(AppImages.edit_profile),
            onTap: () async {
              await Get.to(() => UploadDataView());
              print("🔄 Refreshing profile after returning from upload page");
              await profileController.refreshProfile();
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
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading profile...'),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
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
                // Show Subscribe Button - if not subscribed
                if (!subController.isSubscribed.value && !subController.canReactivateSubscription) {
                  return Column(
                    children: [
                      Button(
                        title: 'Subscribe Now',
                        onTap: () => Get.to(PaymentView()),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }

                // Show Active Subscription Status - if fully subscribed
                else if (subController.isSubscribed.value && subController.canCancelSubscription) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade400, Colors.green.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Active Subscription',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Full access to all AI personas',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _showCancelSubscriptionDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red.shade600,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Cancel Subscription',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }

                // Show Reactivation Option - if canceled but still in grace period
                else if (subController.canReactivateSubscription) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Subscription Canceled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              subController.subscriptionDisplayMessage,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            // Replace the reactivation button onPressed handler in ProfileView

                            // Replace the reactivation button onPressed handler in your ProfileView

                            ElevatedButton(
                              onPressed: () async {
                                // Show loading dialog
                                Get.dialog(
                                  Center(
                                    child: Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('Reactivating subscription...'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  barrierDismissible: false,
                                );

                                try {
                                  // Call the reactivate subscription API
                                  bool success = await subController.reactivateSubscription();

                                  Get.back(); // Close loading dialog

                                  if (success) {
                                    // Refresh home page data
                                    try {
                                      final homeController = Get.find<ChatAllAiPersona>();
                                      await homeController.refreshAfterSubscriptionChange();
                                    } catch (e) {
                                      print("Home controller not found, data will refresh on next visit: $e");
                                    }

                                    // Show success message
                                    Get.snackbar(
                                      'Subscription Reactivated!',
                                      'Your subscription has been reactivated successfully. You now have full access to all personas.',
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                      duration: Duration(seconds: 4),
                                      icon: Icon(Icons.check_circle, color: Colors.white),
                                    );
                                  } else {
                                    // Show error message if reactivation failed
                                    Get.snackbar(
                                      'Reactivation Failed',
                                      'Failed to reactivate subscription. Please try again or contact support.',
                                      snackPosition: SnackPosition.TOP,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                      duration: Duration(seconds: 4),
                                      icon: Icon(Icons.error, color: Colors.white),
                                    );
                                  }
                                } catch (e) {
                                  Get.back(); // Close loading dialog if still open

                                  // Show error message
                                  Get.snackbar(
                                    'Error',
                                    'An error occurred while reactivating subscription. Please try again.',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                    duration: Duration(seconds: 3),
                                    icon: Icon(Icons.error, color: Colors.white),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange.shade600,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Reactivate Subscription',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }

                return SizedBox.shrink();
              }),

              // Menu Items
              _buildMenuItem(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                onTap: () => Get.to(NotificationView()),
              ),


          // _buildMenuItem(
          //       icon: Icons.notifications_active_outlined,
          //       title: 'gapay',
          //       onTap: () => Get.to(GooglePaymentScreen()),
          //     ),

              // _buildMenuItem(
              //   icon: Icons.notifications_active_outlined,
              //   title: 'fake',
              //   onTap: () => Get.to(PaymentScreen()),
              // ),

              _buildMenuItem(
                icon: Icons.insert_drive_file_outlined,
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
        );
      }),
    );
  }

// IMPROVED: Updated cancel subscription dialog method for ProfileView
  void _showCancelSubscriptionDialog(BuildContext context) {
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
              color: Colors.orange,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Cancel Subscription?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel your subscription?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
                  SizedBox(height: 8),
                  Text(
                    'After cancellation, you will only have access to your selected persona from onboarding until your current period ends.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20,),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog

                // Show loading indicator
                Get.dialog(
                  Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Cancelling subscription...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  barrierDismissible: false,
                );

                try {
                  // Cancel subscription
                  await subController.cancelSubscription();

                  // Close loading dialog

                  // ADDED: Handle persona access changes after cancellation
                  try {
                    final homeController = Get.find<ChatAllAiPersona>();
                    await homeController.handleSubscriptionCancellation();
                    await homeController.refreshAfterSubscriptionChange();
                  } catch (e) {
                    print("Home controller not found, data will refresh on next visit: $e");
                  }

                  // Show success message with more specific information
                  Get.snackbar(
                    'Subscription Cancelled',
                    'Your subscription has been cancelled. You now have access to your selected persona only until your current period ends.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                    duration: Duration(seconds: 5),
                    icon: Icon(Icons.info_outline, color: Colors.white),
                  );

                  Get.back();

                } catch (e) {
                  Get.back(); // Close loading dialog
                  Get.snackbar(
                    'Error',
                    'Failed to cancel subscription. Please try again or contact support.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    duration: Duration(seconds: 4),
                    icon: Icon(Icons.error, color: Colors.white),
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Yes, Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20,),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Keep Subscription", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ],
        ),

      ),
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                          CircularProgressIndicator(),
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