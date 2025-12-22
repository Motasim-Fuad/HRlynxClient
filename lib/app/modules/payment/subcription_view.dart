import 'package:HRlynx/app/api_servies/token.dart';
import 'package:HRlynx/app/modules/main_screen/main_screen_view.dart';
import 'package:HRlynx/app/modules/payment/payment_controller.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:HRlynx/app/utils/app_images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with TickerProviderStateMixin {
  final PaymentController controller = Get.put(PaymentController());
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primarycolor,
      body: SafeArea(
        child: Obx(() {
          // Loading state when fetching plans
          if (controller.isLoading.value && controller.plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Text(
                    'Loading plans.......',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter out free plans - only show paid plans
          final paidPlans = controller.plans.where((plan) =>
          plan.planType != 'free' &&
              plan.price != '0.00' &&
              plan.price != '0'
          ).toList();

          // No paid plans available state
          if (paidPlans.isEmpty && !controller.isLoading.value) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: screenWidth * 0.16,
                      color: Colors.white70,
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Text(
                      'No subscription plans available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Text(
                      'Please try again later',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.035,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.037),
                    ElevatedButton(
                      onPressed: () => controller.fetchPlans(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.075,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Try Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Find yearly and monthly plans from filtered paid plans
          final yearlyPlan = paidPlans.firstWhereOrNull(
                  (plan) => plan.interval == 'year'
          );
          final monthlyPlan = paidPlans.firstWhereOrNull(
                  (plan) => plan.interval == 'month'
          );

          return Stack(
            children: [
              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Header image
                        Container(
                          width: double.infinity,
                          height: screenHeight * 0.18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            child: Image.asset(
                              AppImages.subcription_logo,
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.006),

                        // Title
                        Text(
                          'Explorer Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: screenWidth * 0.085,
                            letterSpacing: 1.2,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.01),

                        // Subtitle
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade700.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Start your 7-day free trial',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.045,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.012),

                        // Features list
                        Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.145,
                            right: 0,
                            top: 0,
                            bottom: 0,
                          ),
                          child: Column(
                            children: [
                              _buildFeatureRow('HR QuickScan™ News Highlights', Icons.newspaper, screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),
                              _buildFeatureRow('Expert AI HR Persona Suite', Icons.psychology, screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),
                              _buildFeatureRow('Priority Chat Access', Icons.chat_bubble_outline, screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),
                              _buildFeatureRow('Save & Revisit Conversations', Icons.save_outlined, screenWidth, screenHeight),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.025),

                        // Plan cards - only show if not null
                        if (yearlyPlan != null)
                          _buildPlanCard(
                            context,
                            controller,
                            yearlyPlan.planType,
                            yearlyPlan.name,
                            '\$${yearlyPlan.price}/',
                            yearlyPlan.interval,
                            'Save 2+ months – Invest in your HR edge',
                            true,
                            screenWidth,
                            screenHeight,
                          ),

                        if (monthlyPlan != null) ...[
                          SizedBox(height: screenHeight * 0.025),
                          _buildPlanCard(
                            context,
                            controller,
                            monthlyPlan.planType,
                            monthlyPlan.name,
                            '\$${monthlyPlan.price}/',
                            monthlyPlan.interval,
                            'Less than a daily latte. Much more satisfying.',
                            false,
                            screenWidth,
                            screenHeight,
                          ),
                        ],

                        SizedBox(height: screenHeight * 0.02),

                        // Start trial button
                        _buildStartTrialButton(controller, screenWidth, screenHeight),

                        SizedBox(height: screenHeight * 0.02),

                        // Skip trial text
                        _buildSkipTrialText(screenWidth, screenHeight),

                        SizedBox(height: screenHeight * 0.016),

                        // Policy links
                        _buildPolicyLinks(screenWidth, screenHeight),

                        SizedBox(height: screenHeight * 0.062),
                        _buildRestorePurchasesButton(screenWidth, screenHeight),

                        SizedBox(height: screenHeight * 0.01),
                        _buildSubscriptionDisclosure(screenWidth, screenHeight),
                      ],
                    ),
                  ),
                ),
              ),

              // Payment processing overlay
              if (controller.paymentInProgress.value)
                Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.075),
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                      decoration: BoxDecoration(
                        color: AppColors.primarycolor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade700, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
                          ),
                          SizedBox(height: screenHeight * 0.025),
                          Text(
                            'Processing payment...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.012),
                          Text(
                            'Please wait',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.035,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFeatureRow(String text, IconData icon, double screenWidth, double screenHeight) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: Colors.teal.shade700.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.0375,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context,
      PaymentController controller,
      String planType,
      String title,
      String price,
      String interval,
      String subtitle,
      bool isPopular,
      double screenWidth,
      double screenHeight,
      ) {
    final isSelected = controller.selectedPlan.value == planType;

    return GestureDetector(
      onTap: () => controller.selectedPlan.value = planType,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  width: isSelected ? 3 : 2,
                  color: isSelected ? Colors.teal.shade700 : Colors.white.withOpacity(0.7),
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.teal.shade700.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Plan name
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: screenWidth * 0.0475,
                            color: isSelected ? AppColors.primarycolor : Colors.white,
                          ),
                        ),
                      ),
                      // Price
                      Row(
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.055,
                              color: isSelected ? AppColors.primarycolor : Colors.white,
                            ),
                          ),
                          Text(
                            interval,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.04,
                              color: isSelected ? AppColors.primarycolor : Colors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.015),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.0325,
                      color: isSelected ? AppColors.primarycolor.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Popular badge
            if (isPopular)
              Positioned(
                top: -screenHeight * 0.015,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.0075,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade600, Colors.teal.shade700],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.shade700.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Most Popular',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartTrialButton(PaymentController controller, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.08,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.startFreeTrial,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            disabledBackgroundColor: Colors.teal.shade700.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: Colors.teal.shade700.withOpacity(0.4),
          ),
          child: controller.isLoading.value
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Loading...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.045,
                  color: Colors.white,
                ),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: screenWidth * 0.02),
                  Flexible(
                    child: Text(
                      controller.hasUsedTrial
                          ? "Subscribe Now"
                          : "Subscribe with 7 Days Free Trial",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.045,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                child: Text(
                  'No commitment. Cancel anytime during trial.',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: screenWidth * 0.0275,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipTrialText(double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () async {
        await TokenStorage.saveSubscriptionCheckDone(true);
        Get.offAll(() => MainScreen());
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.01,
        ),
        child: Text(
          'Skip trial, continue with limited free access.',
          style: TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
            fontSize: screenWidth * 0.035,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRestorePurchasesButton(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: TextButton(
        onPressed: () async {
          try {
            await controller.restorePurchases();

            // Close loading dialog
            Get.back();

            // Check if subscription was restored
            if (controller.hasActiveSubscription) {
              Get.snackbar(
                'Success',
                'Purchases restored successfully!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                margin: EdgeInsets.all(screenWidth * 0.04),
                duration: Duration(seconds: 3),
              );

              await Future.delayed(Duration(seconds: 1));
              Get.offAll(() => MainScreen());
            } else {
              Get.snackbar(
                'No Purchases Found',
                'No active subscription found to restore.',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                margin: EdgeInsets.all(screenWidth * 0.04),
                duration: Duration(seconds: 3),
              );
            }
          } catch (error) {

            Get.snackbar(
              'Error',
              'Failed to restore purchases. Please try again.',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              margin: EdgeInsets.all(screenWidth * 0.04),
              duration: Duration(seconds: 3),
            );
          }
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
        ),
        child: Text(
          'Restore Purchases',
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.03,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDisclosure(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.075,
        vertical: screenHeight * 0.012,
      ),
      child: Text(
        'Payment will be charged to your Apple ID or Google Play account at confirmation of purchase. '
            'Subscription automatically renews unless canceled at least 24 hours before the end of the current period. '
            'Your account will be charged for renewal within 24 hours prior to the end of the current period. '
            'You can manage and cancel your subscription by going to your account settings in the App Store or Google Play after purchase.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: screenWidth * 0.025,
          color: Colors.white.withOpacity(0.6),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPolicyLinks(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _launchUrl('https://www.hrlynx.ai/terms-conditions/');
            },
            child: Text(
              'Terms of Use',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.8),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                fontSize: screenWidth * 0.0325,
              ),
            ),
          ),
          Text(
            ' and ',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
              fontSize: screenWidth * 0.0325,
            ),
          ),
          GestureDetector(
            onTap: () {
              _launchUrl('https://www.hrlynx.ai/privacy-policy/');
            },
            child: Text(
              'Privacy Policy.',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.8),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                fontSize: screenWidth * 0.0325,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}