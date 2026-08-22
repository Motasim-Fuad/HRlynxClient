import 'package:HRlynx/app/api_servies/api_Constant.dart';
import 'package:HRlynx/app/api_servies/neteork_api_services.dart';
import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/model/tarmsAndConditionModel.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class TermsController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  var termsData = Rxn<TermsandConditionsModel>();
  var isLoading = true.obs;
  var errorMessage = Rxn<String>();
  var parsedContent = <Widget>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTermsAndConditions();
  }

  Future<void> fetchTermsAndConditions() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final response = await _authRepo.getTermsAndConditions();

      if (response != null) {
        termsData.value = TermsandConditionsModel.fromJson(response);
        if (termsData.value?.data?.content != null) {
          parsedContent.value = _parseHtmlContent(termsData.value!.data!.content!);
        }
        isLoading.value = false;
      } else {
        errorMessage.value = 'Failed to load terms and conditions';
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
      fontSize: 16,
      color: Color(0xff7D848D),
    );

    TextStyle copyrightStyle = const TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: Color(0xff7D848D),
      fontStyle: FontStyle.italic,
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

      bool isHeading = _isHeading(trimmedSection);
      bool isCopyright = _isCopyright(trimmedSection);
      bool isContact = _isContact(trimmedSection);

      if (isHeading && !isContact) {
        if (!isFirstSection) {
          widgets.add(const SizedBox(height: 30));
        }

        widgets.add(Text(trimmedSection, style: headingStyle));
        widgets.add(const SizedBox(height: 8));
        isFirstSection = false;
      } else if (isCopyright) {
        widgets.add(Text(trimmedSection, style: copyrightStyle));

        if (sections.indexOf(section) < sections.length - 1) {
          widgets.add(const SizedBox(height: 12));
        }
      } else if (isContact) {
        widgets.add(Text(trimmedSection, style: contactStyle));

        if (sections.indexOf(section) < sections.length - 1) {
          widgets.add(const SizedBox(height: 12));
        }
      } else {
        widgets.add(Text(trimmedSection, style: bodyStyle));

        if (sections.indexOf(section) < sections.length - 1) {
          widgets.add(const SizedBox(height: 12));
        }
      }
    }

    return widgets;
  }

  bool _isHeading(String text) {
    return (text.startsWith(RegExp(r'\d+\.\s')) && !_isContact(text)) ||
        (text.contains('Terms & Conditions') && !text.contains('©')) ||
        text.contains('Effective Date:') ||
        text.startsWith('Acceptance of Terms') ||
        text.startsWith('Description of Service') ||
        text.startsWith('User Responsibilities') ||
        text.startsWith('Subscription Terms') ||
        text.startsWith('Limitation of Liability') ||
        text.startsWith('Intellectual Property') ||
        text.startsWith('Content Ownership') ||
        text.startsWith('Modifications to Terms') ||
        text.startsWith('Account Suspension') ||
        text.startsWith('Jurisdiction') ||
        text.startsWith('Future Phase') ||
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

class TermsOfUse extends StatelessWidget {
  const TermsOfUse({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TermsController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return  Center(child: CircularProgressIndicator(color: AppColors.primarycolor,));
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
                  onPressed: controller.fetchTermsAndConditions,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.parsedContent.isNotEmpty) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.parsedContent,
              ),
            ),
          );
        }

        return const Center(
          child: Text(
            'No terms and conditions available',
            style: TextStyle(fontSize: 16),
          ),
        );
      }),
    );
  }
}

extension TermsExtension on AuthRepository {
  Future<dynamic> getTermsAndConditions() async {
    String url = "${ApiConstants.baseUrl}/api/core/terms-and-conditions/";
    try {
      return await NetworkApiServices.getApi(url, withAuth: false);
    } catch (e) {
      print('Error fetching terms and conditions: $e');
      rethrow;
    }
  }
}
