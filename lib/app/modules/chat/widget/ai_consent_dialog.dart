
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiConsentDialog {
  static const String _consentKey = 'ai_chat_consent_given';

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyConsented = prefs.getBool(_consentKey) ?? false;

    if (alreadyConsented) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🔒 AI Chat Disclosure',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          "HRlynx uses OpenAI, Inc. to generate AI-powered responses.\n\nWhen you submit a chat message:\n• Your message is transmitted securely to OpenAI for processing\n• It is used solely to generate a response within HRlynx\n• It is not sold or used for advertising\n\nBy continuing, you consent to this processing as described in our Privacy Policy.",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarycolor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // ✅ Update ConsentController reactively
              final consentCtrl = Get.find<ConsentController>();
              await consentCtrl.giveConsent();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Agree & Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}




class ConsentController extends GetxController {
  static const String _consentKey = 'ai_chat_consent_given';

  final hasConsented = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final prefs = await SharedPreferences.getInstance();
    hasConsented.value = prefs.getBool(_consentKey) ?? false;
  }

  Future<void> giveConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    hasConsented.value = true;
  }
}