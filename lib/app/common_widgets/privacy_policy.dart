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
              Text(
                'Effective Date: June 27, 2025',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              Text(
                '1.Information We Collect',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Account Information: Email address, login credentials. Usage Data: AI interactions, prompt data, chat logs, feature usage. Device Data: Device type, IP address, OS version (for analytics & security). Payment Information: Processed securely via App Store / Google Play; HRlynx does not store payment data directly.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '2. How We Use Your Data',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'To provide personalized AI guidance and HR news content. To improve the performance and relevance of AI Personas. To track usage for feature optimization and safety monitoring. To comply with legal, regulatory, or audit obligations.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),

              SizedBox(height: 30),
              Text(
                '3. AI Model Use',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Your prompts and chat data may be processed by third-party AI models (e.g., OpenAI) subject to their privacy and security policies. We apply additional filtering, logging, and safety monitoring to protect against AI hallucinations or inappropriate outputs.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '4. Data Sharing',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'We do not sell or share your personal data with advertisers. Limited data may be shared with infrastructure providers necessary for AI processing (e.g., OpenAI, Firebase, Stripe, Google)',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '5. User Control',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'You may request deletion of your account and associated data at any time by contacting info@lynxova.com. You may access or export your chat history subject to reasonable processing time.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '6. Security',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'We implement appropriate administrative, technical, and physical safeguards to protect your personal information from unauthorized access or disclosure.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '7. GDPR / CCPA Compliance (if applicable)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'We honor applicable data subject rights under GDPR and CCPA for covered jurisdictions. California users may request disclosure of data collection practices and opt-out of certain data uses.',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff7D848D),
                ),
              ),
              SizedBox(height: 30),
              Text(
                '8. Contact',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xff1B1E28),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'If you have any privacy concerns, contact us at: Lynxova LLC',
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
