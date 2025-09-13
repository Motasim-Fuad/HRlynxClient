import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/modules/payment/payment_controller.dart';

class SubscriptionScreen extends StatelessWidget {
  final PaymentController controller = Get.put(PaymentController());

  SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer Pro Subscription'),
        centerTitle: true,
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(),

                  const SizedBox(height: 24),

                  // Plan Selection
                  _buildPlanSelection(),

                  const SizedBox(height: 24),

                  // Features List
                  _buildFeaturesList(),

                  const SizedBox(height: 32),

                  // Google Play Info
                  _buildGooglePlayInfo(),

                  const SizedBox(height: 32),

                  // Start Trial Button
                  _buildTrialButton(),

                  const SizedBox(height: 16),

                  // Terms and Conditions
                  _buildTermsAndConditions(),
                ],
              ),
            ),

            // Loading Overlay
            if (controller.isLoading.value || controller.paymentInProgress.value)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.paymentInProgress.value
                              ? 'Processing payment...'
                              : 'Loading plans...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal[100]!),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outlined,
            size: 48,
            color: Colors.teal,
          ),
          SizedBox(height: 12),
          Text(
            'Upgrade to Explorer Pro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Unlock all premium features with a 7-day free trial',
            style: TextStyle(
              fontSize: 16,
              color: Colors.teal.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your plan:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (controller.plans.isEmpty && !controller.isLoading.value)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No subscription plans available. Please try again later.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: controller.plans.map((plan) {
              final isSelected = controller.selectedPlan.value == plan.planType;
              final isMonthly = plan.interval == 'month';

              return GestureDetector(
                onTap: () => controller.selectedPlan.value = plan.planType,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.teal : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio(
                        value: plan.planType,
                        groupValue: controller.selectedPlan.value,
                        onChanged: (value) => controller.selectedPlan.value = value.toString(),
                        activeColor: Colors.teal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${plan.price}/${plan.interval}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (isMonthly)
                              const SizedBox(height: 4),
                            if (isMonthly)
                              Text(
                                'Billed monthly',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.teal,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What you get:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem('Unlimited job searches and applications'),
        _buildFeatureItem('Advanced resume builder with AI suggestions'),
        _buildFeatureItem('Priority support from our career experts'),
        _buildFeatureItem('Exclusive networking events and webinars'),
        _buildFeatureItem('Personalized career path recommendations'),
        _buildFeatureItem('No ads - clean, distraction-free experience'),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.teal[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGooglePlayInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/google.png', // Make sure to add this asset
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Payment will be processed through Google Play. Subscriptions automatically renew unless canceled.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialButton() {
    final selectedPlan = controller.selectedPlanData;
    final isYearly = selectedPlan?.interval == 'year';

    return Column(
      children: [
        if (selectedPlan != null)
          Text(
            'Start your 7-day free trial, then \$${selectedPlan.price}/${selectedPlan.interval}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Button(
            title: 'Start 7-Day Free Trial',
            onTap: controller.plans.isEmpty || controller.isLoading.value
                ? null
                : () => controller.startFreeTrial(),
            // backgroundColor: Colors.teal,
            // textColor: Colors.white,
            // height: 50,
            // borderRadius: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to terms screen
              },
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.teal[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to privacy policy screen
              },
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.teal[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to restore purchases
                _restorePurchases();
              },
              child: Text(
                'Restore Purchases',
                style: TextStyle(
                  color: Colors.teal[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _restorePurchases() {
    // Implement restore purchases functionality
    Get.snackbar(
      'Restore Purchases',
      'Checking for existing subscriptions...',
      backgroundColor: Colors.teal,
      colorText: Colors.white,
    );

    // You would typically call a method to check subscription status
    controller.checkSubscriptionStatus();
  }
}