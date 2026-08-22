import 'package:HRlynx/app/api_servies/api_Constant.dart';
import 'package:HRlynx/app/api_servies/neteork_api_services.dart';
import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/model/privacy_policy_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class PrivacyController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  var privacyData = Rxn<PrivacyPolicyModel>();
  var isLoading = true.obs;
  var errorMessage = Rxn<String>();
  var parsedContent = <Widget>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPrivacyPolicy();
  }

  Future<void> fetchPrivacyPolicy() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final response = await _authRepo.getPrivacyPolicy();

      if (response != null) {
        privacyData.value = PrivacyPolicyModel.fromJson(response);
        if (privacyData.value?.data?.content != null) {
          parsedContent.value = _parseHtmlContent(privacyData.value!.data!.content!);
        }
        isLoading.value = false;
      } else {
        errorMessage.value = 'Failed to load privacy policy';
        isLoading.value = false;
      }
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString()}';
      isLoading.value = false;
    }
  }

  List<Widget> _parseHtmlContent(String htmlContent) {
    List<Widget> widgets = [];

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

    TextStyle contactStyle = const TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: Color(0xff7D848D),
    );

    TextStyle copyrightStyle = const TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: Color(0xff7D848D),
      fontStyle: FontStyle.italic,
    );

    TextStyle titleStyle = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      color: Color(0xff1B1E28),
    );

    TextStyle effectiveDateStyle = const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
    );

    String cleanContent = htmlContent
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');

    List<String> sections = cleanContent.split('\n');

    bool isFirstSection = true;

    for (String section in sections) {
      String trimmedSection = section.trim();

      if (trimmedSection.isEmpty) {
        continue;
      }

      bool isMainTitle = _isMainTitle(trimmedSection);
      bool isHeading = _isHeading(trimmedSection);
      bool isCopyright = _isCopyright(trimmedSection);
      bool isContact = _isContact(trimmedSection);
      bool isEffectiveDate = _isEffectiveDate(trimmedSection);

      if (isMainTitle) {
        if (!isFirstSection) {
          widgets.add(const SizedBox(height: 30));
        }
        widgets.add(Text(trimmedSection, style: titleStyle));
        widgets.add(const SizedBox(height: 10));
        isFirstSection = false;
      } else if (isEffectiveDate) {
        widgets.add(Text(trimmedSection, style: effectiveDateStyle));
        widgets.add(const SizedBox(height: 8));
      } else if (isHeading && !isContact) {
        if (!isFirstSection) {
          widgets.add(const SizedBox(height: 30));
        }

        widgets.add(Text(trimmedSection, style: headingStyle));
        widgets.add(const SizedBox(height: 15));
        isFirstSection = false;
      } else if (isCopyright) {
        widgets.add(const SizedBox(height: 40));
        widgets.add(Text(trimmedSection, style: copyrightStyle));
        widgets.add(const SizedBox(height: 30));
      } else if (isContact) {
        widgets.add(Text(trimmedSection, style: contactStyle));

        if (sections.indexOf(section) < sections.length - 1) {
          widgets.add(const SizedBox(height: 5));
        }
      } else {
        widgets.add(Text(trimmedSection, style: bodyStyle));

        if (sections.indexOf(section) < sections.length - 1) {
          widgets.add(const SizedBox(height: 10));
        }
      }
    }

    return widgets;
  }

  bool _isMainTitle(String text) {
    return text.contains('Privacy Policy') && text.contains('(v');
  }

  bool _isEffectiveDate(String text) {
    return text.startsWith('Effective Date:');
  }

  bool _isHeading(String text) {
    return (text.startsWith(RegExp(r'\d+\.\s')) && !_isContact(text)) ||
        text.startsWith('Information We Collect') ||
        text.startsWith('How We Use Your Information') ||
        text.startsWith('Subscription & Auto-Renewal') ||
        text.startsWith('Data Sharing & Disclosure') ||
        text.startsWith('AI Content Disclaimer') ||
        text.startsWith('Intellectual Property Rights') ||
        text.startsWith('Data Retention') ||
        text.startsWith('Security') ||
        text.startsWith('International Data Transfers') ||
        text.startsWith('Canada (PIPEDA)') ||
        text.startsWith('California (CCPA/CPRA)') ||
        text.startsWith('Your Rights (Other Jurisdictions)') ||
        text.startsWith('Children\'s Privacy') ||
        text.startsWith('Updates to This Policy') ||
        (text.length < 60 && text.endsWith(':') && !_isContact(text));
  }

  bool _isCopyright(String text) {
    return text.contains('©') ||
        text.contains('All rights reserved') ||
        text.contains('™') ||
        text.contains('trademark');
  }

  bool _isContact(String text) {
    return text.toLowerCase().contains('owner:') ||
        text.toLowerCase().contains('contact:') ||
        text.toLowerCase().contains('info@') ||
        text.toLowerCase().contains('email:');
  }
}

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PrivacyController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xff1B1E28),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchPrivacyPolicy,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.parsedContent.isNotEmpty) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  ...controller.parsedContent,
                ],
              ),
            ),
          );
        }

        return const Center(
          child: Text(
            'No privacy policy available',
            style: TextStyle(fontSize: 16),
          ),
        );
      }),
    );
  }
}

extension PrivacyExtension on AuthRepository {
  Future<dynamic> getPrivacyPolicy() async {
    String url = "${ApiConstants.baseUrl}/api/core/privacy-policy/";
    try {
      return await NetworkApiServices.getApi(url, withAuth: false);
    } catch (e) {
      print('Error fetching privacy policy: $e');
      rethrow;
    }
  }
}
