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
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final width = size.width;
    final height = size.height;

    final bool isSmallScreen = width < 360;

    return Scaffold(
      backgroundColor: AppColors.primarycolor,
      body: SafeArea(
        child: Obx(() {
          // ✅ SHOW ERROR UI FIRST
          if (controller.hasError.value) {
            return _buildErrorUI(width, height);
          }

          // Show loading state
          if (controller.isLoading.value && controller.plans.isEmpty) {
            return _buildLoadingState(width, height);
          }

          final paidPlans = controller.plans.where((plan) =>
          plan.planType != 'free' &&
              plan.price != '0.00' &&
              plan.price != '0'
          ).toList();

          if (paidPlans.isEmpty && !controller.isLoading.value) {
            return _buildEmptyState(width, height);
          }

          final yearlyPlan = paidPlans.firstWhereOrNull((plan) =>
          plan.interval == 'year');
          final monthlyPlan = paidPlans.firstWhereOrNull((plan) =>
          plan.interval == 'month');

          return Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(width, height),
                        SizedBox(height: height * 0.015),
                        _buildTitle(width, isSmallScreen),
                        SizedBox(height: height * 0.012),
                        _buildSubtitle(width, height, isSmallScreen),
                        SizedBox(height: height * 0.02),
                        _buildFeaturesList(width, height, isSmallScreen),
                        SizedBox(height: height * 0.03),
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
                            width,
                            height,
                            isSmallScreen,
                          ),
                        if (monthlyPlan != null) ...[
                          SizedBox(height: height * 0.02),
                          _buildPlanCard(
                            context,
                            controller,
                            monthlyPlan.planType,
                            monthlyPlan.name,
                            '\$${monthlyPlan.price}/',
                            monthlyPlan.interval,
                            'Less than a daily latte. Much more satisfying.',
                            false,
                            width,
                            height,
                            isSmallScreen,
                          ),
                        ],
                        SizedBox(height: height * 0.025),
                        _buildStartTrialButton(controller, width, height,
                            isSmallScreen),
                        SizedBox(height: height * 0.02),
                        _buildSkipTrialText(width, height, isSmallScreen),
                        SizedBox(height: height * 0.02),
                        _buildPolicyLinks(width, height, isSmallScreen),
                        SizedBox(height: height * 0.025),
                        _buildRestorePurchasesButton(width, height,
                            isSmallScreen),
                        SizedBox(height: height * 0.015),
                        _buildSubscriptionDisclosure(width, height,
                            isSmallScreen),
                        SizedBox(height: height * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.paymentInProgress.value)
                _buildPaymentOverlay(width, height, isSmallScreen),
            ],
          );
        }),
      ),
    );
  }

  // ✅ ERROR UI WIDGET
  Widget _buildErrorUI(double width, double height) {
    final errorType = controller.errorType.value;
    final errorMessage = controller.errorMessage.value;

    final isNetworkError = errorType == 'network';
    final isServerError = errorType == 'server';

    return Container(
      color: AppColors.primarycolor,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: width * 0.3,
                height: width * 0.3,
                decoration: BoxDecoration(
                  color: isNetworkError
                      ? Colors.orange.withOpacity(0.2)
                      : isServerError
                      ? Colors.red.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNetworkError
                      ? Icons.wifi_off_rounded
                      : isServerError
                      ? Icons.cloud_off_rounded
                      : Icons.error_outline_rounded,
                  size: width * 0.15,
                  color: isNetworkError
                      ? Colors.orange
                      : isServerError
                      ? Colors.red
                      : Colors.grey[300],
                ),
              ),
              SizedBox(height: height * 0.03),

              // Error Title
              Text(
                isNetworkError
                    ? 'No Internet Connection'
                    : isServerError
                    ? 'Server Down'
                    : 'Something Went Wrong',
                style: TextStyle(
                  fontSize: width * 0.06,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: height * 0.015),

              // Error Message
              Text(
                isNetworkError
                    ? 'Please check your internet connection\nand try again.'
                    : isServerError
                    ? 'The server is temporarily unavailable.\nPlease try again later.'
                    : errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: width * 0.04,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              SizedBox(height: height * 0.04),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Go Back Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, size: width * 0.05),
                    label: Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.7), width: 2),
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.05,
                        vertical: height * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.03),

                  // Retry Button
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.clearError();
                      controller.fetchPlans();
                    },
                    icon: Icon(Icons.refresh, size: width * 0.05),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isNetworkError
                          ? Colors.orange
                          : isServerError
                          ? Colors.red
                          : Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.06,
                        vertical: height * 0.015,
                      ),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.03),

              // Skip to Free Access
              TextButton(
                onPressed: () async {
                  await TokenStorage.saveSubscriptionCheckDone(true);
                  Get.offAll(() => MainScreen());
                },
                child: Text(
                  'Skip and continue with free access',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: width * 0.035,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: height * 0.025),
          Text(
            'Loading plans.......',
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.04,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double width, double height) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: width * 0.16,
              color: Colors.white70,
            ),
            SizedBox(height: height * 0.025),
            Text(
              'No subscription plans available',
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.045,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: height * 0.012),
            Text(
              'Please try again later',
              style: TextStyle(
                color: Colors.white70,
                fontSize: width * 0.035,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: height * 0.037),
            ElevatedButton(
              onPressed: () => controller.fetchPlans(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.075,
                  vertical: height * 0.015,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.04,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double width, double height) {
    return Container(
      width: double.infinity,
      height: height * 0.18,
      margin: EdgeInsets.symmetric(horizontal: width * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          AppImages.subcription_logo,
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }

  Widget _buildTitle(double width, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: Text(
        'Explorer Pro',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: isSmall ? width * 0.075 : width * 0.085,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle(double width, double height, bool isSmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.04),
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.05,
        vertical: height * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.teal.shade700.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Start your 7-day free trial',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: isSmall ? width * 0.04 : width * 0.045,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeaturesList(double width, double height, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.08),
      child: Column(
        children: [
          _buildFeatureRow(
              'HR QuickScan™ News Highlights', Icons.newspaper, width, height,
              isSmall),
          SizedBox(height: height * 0.012),
          _buildFeatureRow(
              'Expert AI HR Persona Suite', Icons.psychology, width, height,
              isSmall),
          SizedBox(height: height * 0.012),
          _buildFeatureRow(
              'Priority Chat Access', Icons.chat_bubble_outline, width, height,
              isSmall),
          SizedBox(height: height * 0.012),
          _buildFeatureRow(
              'Save & Revisit Conversations', Icons.save_outlined, width,
              height, isSmall),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, IconData icon, double width,
      double height, bool isSmall) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.02),
          decoration: BoxDecoration(
            color: Colors.teal.shade700.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isSmall ? width * 0.04 : width * 0.045,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? width * 0.035 : width * 0.04,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context,
      PaymentController controller,
      String planType,
      String title,
      String price,
      String interval,
      String subtitle,
      bool isPopular,
      double width,
      double height,
      bool isSmall,) {
    final isSelected = controller.selectedPlan.value == planType;

    return GestureDetector(
      onTap: () => controller.selectedPlan.value = planType,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: width * 0.04),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  width: isSelected ? 3 : 2,
                  color: isSelected ? Colors.teal.shade700 : Colors.white
                      .withOpacity(0.7),
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
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? width * 0.042 : width * 0.0475,
                            color: isSelected ? AppColors.primarycolor : Colors
                                .white,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmall ? width * 0.05 : width * 0.055,
                              color: isSelected
                                  ? AppColors.primarycolor
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            interval,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmall ? width * 0.035 : width * 0.04,
                              color: isSelected
                                  ? AppColors.primarycolor
                                  : Colors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: height * 0.01),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: isSmall ? width * 0.03 : width * 0.0325,
                      color: isSelected ? AppColors.primarycolor.withOpacity(
                          0.8) : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            if (isPopular)
              Positioned(
                top: -height * 0.015,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: height * 0.0075,
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
                        fontSize: isSmall ? width * 0.028 : width * 0.03,
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

  Widget _buildStartTrialButton(PaymentController controller, double width,
      double height, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: height * 0.075),
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller
              .startFreeTrial,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            disabledBackgroundColor: Colors.teal.shade700.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: Colors.teal.shade700.withOpacity(0.4),
            padding: EdgeInsets.symmetric(vertical: height * 0.015),
          ),
          child: controller.isLoading.value
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: width * 0.05,
                height: width * 0.05,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                'Loading...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall ? width * 0.04 : width * 0.045,
                  color: Colors.white,
                ),
              ),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.hasUsedTrial
                    ? "Subscribe Now"
                    : "Subscribe with 7 Days Free Trial",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: isSmall ? width * 0.04 : width * 0.045,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: height * 0.005),
              Text(
                'No commitment. Cancel anytime during trial.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: isSmall ? width * 0.025 : width * 0.0275,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipTrialText(double width, double height, bool isSmall) {
    return GestureDetector(
      onTap: () async {
        await TokenStorage.saveSubscriptionCheckDone(true);
        Get.offAll(() => MainScreen());
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.05,
          vertical: height * 0.01,
        ),
        child: Text(
          'Skip trial, continue with limited free access.',
          style: TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
            fontSize: isSmall ? width * 0.032 : width * 0.035,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRestorePurchasesButton(double width, double height,
      bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: TextButton(
        onPressed: () async {
          try {
            await controller.restorePurchases();
            Get.back();

            if (controller.hasActiveSubscription) {
              Get.snackbar(
                'Success',
                'Purchases restored successfully!',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                margin: EdgeInsets.all(width * 0.04),
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
                margin: EdgeInsets.all(width * 0.04),
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
              margin: EdgeInsets.all(width * 0.04),
              duration: Duration(seconds: 3),
            );
          }
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: height * 0.015),
        ),
        child: Text(
          'Restore Purchases',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmall ? width * 0.028 : width * 0.03,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDisclosure(double width, double height,
      bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.06,
        vertical: height * 0.01,
      ),
      child: Text(
        'Payment will be charged to your Apple ID or Google Play account at confirmation of purchase. '
            'Subscription automatically renews unless canceled at least 24 hours before the end of the current period. '
            'Your account will be charged for renewal within 24 hours prior to the end of the current period. '
            'You can manage and cancel your subscription by going to your account settings in the App Store or Google Play after purchase.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isSmall ? width * 0.023 : width * 0.025,
          color: Colors.white.withOpacity(0.6),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPolicyLinks(double width, double height, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _launchUrl('https://api.hrlynx.ai/terms-conditions/'),
            child: Text(
              'Terms of Use',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.8),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                fontSize: isSmall ? width * 0.03 : width * 0.0325,
              ),
            ),
          ),
          Text(
            ' and ',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
              fontSize: isSmall ? width * 0.03 : width * 0.0325,
            ),
          ),
          GestureDetector(
            onTap: () => _launchUrl('https://api.hrlynx.ai/privacy-policy/'),
            child: Text(
              'Privacy Policy.',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.8),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                fontSize: isSmall ? width * 0.03 : width * 0.0325,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPaymentOverlay(double width, double height, bool isSmall) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(width * 0.075),
          margin: EdgeInsets.symmetric(horizontal: width * 0.1),
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
              SizedBox(height: height * 0.025),
              Text(
                'Processing payment...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? width * 0.04 : width * 0.045,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: height * 0.012),
              Text(
                'Please wait',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isSmall ? width * 0.032 : width * 0.035,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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