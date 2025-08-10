import 'package:flutter/material.dart';

class TermsOfUse extends StatelessWidget {
  const TermsOfUse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Terms of Use',

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
              Text(
                'Effective Date: June 27, 2025',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              Text(
                '1. Acceptance of Terms',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'By accessing or using HRlynx ("the App," "Platform," or "Service"), you agree to be bound by these Terms of Use and our Privacy Policy. If you do not agree, you may not use the Service.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '2. Nature of the Service',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'HRlynx provides AI-powered informational guidance for HR-related topics through AI Personas, curated news feeds, certification prep, and professional resources. The App does not provide legal, compliance, or employment advice. The Service is intended for informational support only and is not a substitute for consultation with qualified HR professionals, legal counsel, or regulatory experts.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),
              Text(
                '3. AI Disclaimers & Use Limitations',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'AI-generated content is based on large language models and third-party sources. Content may not reflect the most recent legal, compliance, or regulatory changes. You remain solely responsible for any HR or employment actions taken based on information provided by the Service. The Service may include links or summaries of third-party news sources, which are provided for informational purposes with attribution.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '4. User Responsibilities',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'You agree not to rely solely on the App’s responses for any HR, compliance, legal, or employment decision-making. You must validate critical advice with qualified professionals where appropriate. You agree not to misuse the Service or submit ensitive personal data (e.g., employee names, Social Security Numbers, HIPAA data).',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '5. Subscription & Payment Terms',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'HRlynx offers free and premium subscription tiers. Paid subscriptions renew automatically unless canceled according to App Store / Google Play policies. Free trials may convert to paid subscriptions unless canceled before the trial period ends. Pricing, features, and trial offers may change at our discretion.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '6. Limitation of Liability',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'HRlynx, its owners, employees, and partners shall not be liable for any direct, indirect, incidental, or consequential damages resulting from the use or inability to use the Service. The Platform is provided “as is” without warranties of any kind.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '7. Intellectual Property',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'All intellectual property rights related to HRlynx, its branding, technology, AI Personas, and UI are owned by Lynxova LLC. You may not reproduce, copy, or redistribute any portion of the Service without express written permission.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '8. Governing Law',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'These Terms shall be governed by the laws of the state of Colorado, without regard to its conflict of law provisions.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '9. Updates to Terms',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'We may update these Terms of Use at any time. Material changes will be communicated to you within the App or via email.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
