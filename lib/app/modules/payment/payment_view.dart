import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/privacy_policy.dart';
import 'package:hr/app/modules/congratulaion_screen/congratulation_view.dart';
import 'package:hr/app/modules/payment/payment_controller.dart';
import 'package:hr/app/modules/terms_of_use/terms_of_use.dart';
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> with TickerProviderStateMixin {
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
    final controller = Get.put(PaymentController());

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
                  const SizedBox(height: 20),
                  Text(
                    'Loading plans...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // No plans available state
          if (!controller.hasPlans.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No subscription plans available',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please try again later',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => controller.fetchPlans(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Try Again',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final yearlyPlan = controller.plans.firstWhereOrNull(
                  (plan) => plan.planType == 'explorer_yearly'
          );
          final monthlyPlan = controller.plans.firstWhereOrNull(
                  (plan) => plan.planType == 'explorer_monthly'
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
                          height: 150,
                          decoration: BoxDecoration(
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
                              AppImages.splash,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Title
                        Text(
                          'Explorer Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 34,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade700.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Start your 7-day free trial',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Features list
                        Padding(
                          padding: const EdgeInsets.only(left: 58,  bottom: 0,  right: 0, top: 0),
                          child: Column(
                            children: [
                              _buildFeatureRow('Unlimited AI Persona Access', Icons.psychology),
                              const SizedBox(height: 8),
                              _buildFeatureRow('Unlimited Chat Support', Icons.chat_bubble_outline),
                              const SizedBox(height: 8),
                              _buildFeatureRow('Save Conversations', Icons.save_outlined),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Plan cards
                        if (yearlyPlan != null)
                          _buildPlanCard(
                            context,
                            controller,
                            'yearly',
                            '${yearlyPlan.name}',
                            '\$${yearlyPlan.price}/',
                            '${yearlyPlan.interval}',
                            'Save 25% - Get 3 months free',
                            true,
                          ),

                        if (monthlyPlan != null) ...[
                          const SizedBox(height: 20),
                          _buildPlanCard(
                            context,
                            controller,
                            'monthly',
                            '${monthlyPlan.name}',
                            '\$${monthlyPlan.price}/',
                            '${monthlyPlan.interval}',
                            'Less than a daily latte. Much more satisfying.',
                            false,
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Start trial button
                        _buildStartTrialButton(controller),

                        const SizedBox(height: 16),

                        // Skip trial text
                        _buildSkipTrialText(),

                        const SizedBox(height: 13),

                        // Policy links
                        _buildPolicyLinks(),
                        const SizedBox(height: 30),
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
                      padding: EdgeInsets.all(30),
                      margin: EdgeInsets.symmetric(horizontal: 40),
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
                          const SizedBox(height: 20),
                          Text(
                            'Processing payment...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Please wait',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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

  Widget _buildFeatureRow(String text, IconData icon) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade700.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
      String indivul,
      String subtitle,
      bool isPopular,
      ) {
    final isSelected = controller.selectedPlan.value == planType;

    return GestureDetector(
      onTap: () => controller.selectPlan(planType),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
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
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                          color: isSelected ? AppColors.primarycolor : Colors.white,
                        ),
                      ),
                      // Price
                      Row(
                        children: [
                          Text(
                            price,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: isSelected ? AppColors.primarycolor: Colors.white,
                            ),
                          ),

                          Text(
                            indivul,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isSelected ? AppColors.primarycolor: Colors.white,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: isSelected ? AppColors.primarycolor.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Popular badge
            if (isPopular)
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

            // Selection indicator
            // if (isSelected)
            //   Positioned(
            //     top: 15,
            //     right: 15,
            //     child: Container(
            //       padding: EdgeInsets.all(4),
            //       decoration: BoxDecoration(
            //         color: Colors.teal.shade700,
            //         shape: BoxShape.circle,
            //       ),
            //       child: Icon(
            //         Icons.check,
            //         color: Colors.white,
            //         size: 16,
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartTrialButton(PaymentController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 65,
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
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
                  const SizedBox(width: 8),
                  Text(
                    'Start Free Trial',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'No commitment. Cancel anytime during trial.',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
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

  Widget _buildSkipTrialText() {
    return GestureDetector(
      onTap: () => Get.to(() => CongratulationView()),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          'Skip trial, continue with limited free access.',
          style: TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPolicyLinks() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Get.to(() => TermsOfUse()),
            child: Text(
              'Terms of Use',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.8),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            ' and ',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => PrivacyPolicy()),
            child: Text(
              'Privacy Policy.',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.8),
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}