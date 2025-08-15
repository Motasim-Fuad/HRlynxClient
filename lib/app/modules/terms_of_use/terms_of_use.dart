import 'package:flutter/material.dart';

class TermsOfUse extends StatelessWidget {
  const TermsOfUse({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle headingStyle = const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 18,
      color: Color(0xff1B1E28),
    );

    TextStyle bodyStyle = const TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: Color(0xff7D848D),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xff1B1E28),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HRlynx – Terms & Conditions (v1.3)', style: headingStyle),
              const SizedBox(height: 8),
              Text('Effective Date: 8/15/2025', style: bodyStyle),
              Text('Owner: Lynxova, LLC (a Colorado limited liability company)', style: bodyStyle),
              Text('Contact: info@hrlynx.ai', style: bodyStyle),

              const SizedBox(height: 30),
              Text('1. Acceptance of Terms', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'By downloading, registering, or using the HRlynx app (“Service”), you agree to these Terms & Conditions, our Privacy Policy, and any future updates. If you do not agree, you must discontinue use of the Service.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('2. Description of Service', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'HRlynx provides:\n'
                    '• Access to curated HR news and information.\n'
                    '• AI-generated guidance through role-based personas.\n'
                    '• Ability to save chats, track interactions, and access subscription-based features.\n\n'
                    'Important: AI-generated content is not legal advice and is intended for informational purposes only. Always consult a qualified HR or legal professional before making decisions that have legal, regulatory, or employment impacts.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('3. User Responsibilities', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'You agree to:\n'
                    '• Provide accurate and current information during registration.\n'
                    '• Use the Service for lawful purposes only.\n'
                    '• Not rely solely on AI-generated responses for legally binding decisions.\n'
                    '• Maintain the confidentiality of your account credentials.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('4. Subscription Terms, Auto-Renewal & Cancellation', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'HRlynx offers free, monthly, and annual subscription plans.\n\n'
                    'Paid subscriptions are processed securely through the Apple App Store or Google Play Store using their respective billing systems.\n\n'
                    'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current billing period.\n\n'
                    'Your account will be charged for renewal within 24 hours prior to the end of the current period at the price of your chosen plan.\n\n'
                    'You can manage and cancel your subscription at any time in your Apple App Store or Google Play Store account settings.\n\n'
                    'If you cancel, you will retain access until the end of the current billing period; no refunds are issued for unused time.\n\n'
                    'Prices may change for future subscription periods; if they do, you will be notified in advance and given the option to cancel before renewal.\n\n'
                    'Apple-required disclosure: Payment will be charged to your Apple ID account at the time of purchase. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current subscription period. You can manage or cancel your subscription in your account settings on the App Store after purchase.\n\n'
                    'Google Play-required disclosure: Payment will be charged to your Google Play account at confirmation of purchase. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the subscription period. You can manage or cancel your subscription in your Google Play account settings at any time.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('5. Limitation of Liability', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'Lynxova, LLC, HRlynx, and their affiliates are not liable for:\n'
                    '• Damages from reliance on AI-generated content or curated news.\n'
                    '• Losses related to employment decisions or HR policy execution.\n'
                    '• Errors, omissions, or unavailability of third-party content or links.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('6. Intellectual Property Rights', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'Trademarks: HRlynx™, HR QuickScan™, and all related logos, product names, and service marks are trademarks of Lynxova, LLC. Unauthorized use of these marks is strictly prohibited.\n\n'
                    'Copyright: All content in the app, including but not limited to text, designs, UI/UX layouts, proprietary AI interaction flows, summaries, HR QuickScan™ format, and other features, is © 2025 Lynxova, LLC. All rights reserved.\n\n'
                    'Trade Secrets: The structure, organization, source code, algorithms, and underlying technology of the HRlynx app are valuable trade secrets of Lynxova, LLC. You may not reverse engineer, decompile, disassemble, or otherwise attempt to derive the source code or underlying ideas of the Service without our express written consent.\n\n'
                    'Third-Party Work Product: Any work performed by contractors, developers, or contributors for the HRlynx app is deemed “work made for hire” and is fully assigned to Lynxova, LLC.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('7. Content Ownership & Usage', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'All AI responses, chat transcripts, and user interactions are the intellectual property of Lynxova, LLC.\n'
                    'We may use anonymized and aggregated data to improve the Service, train AI models, and develop new features.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('8. Modifications to Terms', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'We may update these Terms at any time. Continued use after changes are posted constitutes acceptance.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('9. Account Suspension or Termination', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'We reserve the right to suspend or terminate accounts for violations of these Terms, including but not limited to impersonation, misinformation, or illegal activity.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('10. Jurisdiction', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                'These Terms are governed by the laws of the State of Colorado, without regard to conflict-of-law principles.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text('11. Future Phase Disclaimers (Pre-Release)', style: headingStyle),
              const SizedBox(height: 8),
              Text(
                '• Certification Prep Content: Not endorsed by, affiliated with, or representative of any official HR certification body.\n'
                    '• Marketplace & Consulting Services: All third-party providers are independent contractors; Lynxova, LLC assumes no liability for their actions or omissions.\n'
                    '• Affiliate & Monetization: Future features may include affiliate links or sponsored content, disclosed in accordance with FTC guidelines.',
                style: bodyStyle,
              ),

              const SizedBox(height: 30),
              Text(
                '© 2025 Lynxova, LLC. All rights reserved. HRlynx™ and HR QuickScan™ are trademarks of Lynxova, LLC.',
                style: bodyStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
