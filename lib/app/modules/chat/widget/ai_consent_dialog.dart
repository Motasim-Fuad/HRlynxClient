import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiConsentDialog {
  static const String _consentKey = 'ai_chat_consent_given';

  // Call this in ChatView initState or onInit
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyConsented = prefs.getBool(_consentKey) ?? false;

    if (alreadyConsented) return; // ✅ Already agreed — skip

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
         "HRlynx uses secure API to generate Al-powered responses. When users submit chat prompts,message content is transmitted securely solely to generate a response within the app. No data is sold or used for advertising.",
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
              await prefs.setBool(_consentKey, true);
              Navigator.of(context).pop();
            },
            child: const Text('Agree & Continue',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}