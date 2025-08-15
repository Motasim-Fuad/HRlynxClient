import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xff1B1E28),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),

              // Header Information
              Text(
                'HRlynx – Privacy Policy (v1.3)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Effective Date: 8/15/2025',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              Text(
                'Owner: Lynxova, LLC (a Colorado limited liability company)',
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xff7D848D)),
              ),
              Text(
                'Contact: info@hrlynx.ai',
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Color(0xff7D848D)),
              ),

              SizedBox(height: 30),

              // Section 1
              Text(
                '1. Information We Collect',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'When you register or use HRlynx, we may collect:',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 10),
              Text(
                '• Personal Information: First name, last name, and email address.\n'
                    '• Usage Data: App interactions, saved chats, device type, operating system, app version, and crash/diagnostic reports.\n'
                    '• Subscription & Payment Data: Processed securely through Apple App Store or Google Play Store. We do not store or process your payment card details directly.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 2
              Text(
                '2. How We Use Your Information',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'We use your information to:\n'
                    '• Provide, operate, and improve the HRlynx service.\n'
                    '• Manage accounts, subscriptions, and billing.\n'
                    '• Personalize your app experience and saved interactions.\n'
                    '• Communicate important service updates and policy changes.\n'
                    '• Maintain compliance with applicable laws and regulations.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 3
              Text(
                '3. Subscription & Auto-Renewal Information',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'To ensure consistency with our Terms & Conditions, we disclose the following:\n'
                    '• Paid subscriptions are billed through Apple App Store or Google Play Store.\n'
                    '• Subscriptions automatically renew unless canceled at least 24 hours before the end of the current billing period.\n'
                    '• Your account will be charged for renewal within 24 hours prior to the end of the current period at the then-current subscription price.\n'
                    '• You can manage or cancel subscriptions in your App Store or Google Play account settings at any time.\n'
                    '• If you cancel, you will retain access to premium features until the end of your current billing period; no partial refunds are provided.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 4
              Text(
                '4. Data Sharing & Disclosure',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'We do not sell your personal information. We may share information with:\n'
                    '• Service providers that help operate the app (e.g., hosting, analytics, AI processing, email delivery).\n'
                    '• Apple App Store and Google Play Store for subscription processing.\n'
                    '• Law enforcement or regulators, if required by law.\n'
                    '• For future phases of HRlynx, limited data may be shared with independent HR coaches or marketplace participants strictly for facilitating booked services.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 5
              Text(
                '5. AI Content Disclaimer',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'AI-generated content provided in HRlynx is for informational purposes only and does not constitute legal, regulatory, or HR-certified professional advice. Always consult a qualified professional before making decisions with legal or compliance implications.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 6
              Text(
                '6. Intellectual Property Rights',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Trademarks: HRlynx™, HR QuickScan™, and all related logos, product names, and service marks are trademarks of Lynxova, LLC.\n\n'
                    'Copyright: All content in the app, including but not limited to text, designs, UI/UX layouts, proprietary AI interaction flows, summaries, HR QuickScan™ format, and other features, is © 2025 Lynxova, LLC.\n\n'
                    'Trade Secrets: The structure, organization, source code, algorithms, and underlying technology of the HRlynx app are valuable trade secrets of Lynxova, LLC.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 7
              Text(
                '7. Data Retention',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Policy, comply with legal obligations, resolve disputes, and enforce agreements.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 8
              Text(
                '8. Security',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'We use commercially reasonable administrative, technical, and physical safeguards to protect your information. However, no method of transmission or storage is completely secure, and we cannot guarantee absolute security.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 9
              Text(
                '9. International Data Transfers & GDPR / UK GDPR Rights',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'If you access HRlynx from outside the United States, including from the European Economic Area (EEA) or the United Kingdom:\n\n'
                    'Your GDPR / UK GDPR Rights:\n'
                    '• Access your personal data\n'
                    '• Correct inaccuracies in your personal data\n'
                    '• Request deletion of your personal data ("right to be forgotten")\n'
                    '• Restrict or object to processing of your personal data\n'
                    '• Request data portability to another provider\n\n'
                    'How to Exercise Your Rights: Email info@hrlynx.ai with "Data Request" in the subject line.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 10
              Text(
                '10. Canada (PIPEDA) Rights',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'If you are a resident of Canada, you have the right to:\n'
                    '• Access the personal information we hold about you\n'
                    '• Request corrections to ensure your data is accurate\n'
                    '• Withdraw consent to processing where applicable\n'
                    '• File a complaint with the Office of the Privacy Commissioner of Canada',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 11
              Text(
                '11. California (CCPA/CPRA) Rights',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'If you are a resident of California, you have the right to:\n'
                    '• Know what categories of personal information we collect and how we use it\n'
                    '• Request a copy of the specific pieces of personal information we hold about you\n'
                    '• Request deletion of your personal information\n'
                    '• Opt out of the sale or sharing of your personal information\n'
                    '• Not be discriminated against for exercising your privacy rights\n\n'
                    'You can exercise these rights by emailing info@hrlynx.ai with "California Privacy Request" in the subject line.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 12
              Text(
                '12. Your Rights (Other Jurisdictions)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Depending on your location, you may have additional rights under local privacy laws. We will comply with applicable legal requirements in your jurisdiction.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 13
              Text(
                '13. Children\'s Privacy',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'HRlynx is not intended for individuals under the age of 18, and we do not knowingly collect data from minors.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),

              // Section 14
              Text(
                '14. Updates to This Policy',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'We may update this Privacy Policy from time to time. If we make material changes, we will notify you through the app or by email before they take effect. Continued use after changes are posted constitutes acceptance.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 40),

              // Footer
              Text(
                '© 2025 Lynxova, LLC. All rights reserved. HRlynx™ and HR QuickScan™ are trademarks of Lynxova, LLC.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xff7D848D),
                  fontStyle: FontStyle.italic,
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}