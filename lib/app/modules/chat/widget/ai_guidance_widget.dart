import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common_widgets/customtooltip.dart';

class AIGuidanceWidget extends StatelessWidget {
  final ChatTooltipController tooltipCtrl;

  const AIGuidanceWidget({super.key, required this.tooltipCtrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: tooltipCtrl.toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "AI Guidance Only — Not Legal or HR Advice. Consult professionals for critical decisions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                decoration: TextDecoration.underline,
                color: Colors.blueGrey[700],
              ),
            ),
          ),
        ),
        Obx(() {
          if (tooltipCtrl.isVisible.value) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: tooltipCtrl.hide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                      const Align(
                        alignment: Alignment.center,
                        child: ChatTooltipBubble(
                          message:
                          "AI-powered responses are provided for informational purposes only and do not constitute legal, compliance, or professional advice. Users should consult qualified HR, legal, or compliance professionals before making employment decisions. HRlynx AI Personas are not a substitute for independent judgment or expert consultation. Content may not reflect the most current regulatory or legal developments. Use of this platform is subject to the Terms of Use and Privacy Policy.",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}