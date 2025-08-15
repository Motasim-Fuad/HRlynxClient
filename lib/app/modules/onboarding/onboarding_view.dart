import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/token.dart';
import 'package:hr/app/common_widgets/button.dart' show Button;
import 'package:hr/app/common_widgets/hr_select.dart';
import 'package:hr/app/modules/log_in/log_in_view.dart';
import 'package:hr/app/modules/onboarding/onboarding_controller.dart';
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';
import '../../model/onbordingModel.dart';

class OnboardingView extends StatelessWidget {
  final HrRoleController controller = Get.put(HrRoleController());

  OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double h = size.height;
    final double w = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(w * 0.03),
          child: Column(
            children: [
              // Logo / Top Image
              Image.asset(
                AppImages.splash,
                height: h * 0.20,
                fit: BoxFit.contain,
              ),

              SizedBox(height: h * 0.015),

              // Title Text
              Text(
                'Customize your experience by choosing an AI HR Assistant Persona!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: h * 0.025,
                  color: const Color(0xFF2B2323),
                ),
              ),

              SizedBox(height: h * 0.02),

              // Persona List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: h * 0.02),
                          Text(
                            "Loading personas...",
                            style: TextStyle(fontSize: h * 0.02),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.personaList.isEmpty &&
                      controller.errorMessage.value.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: h * 0.08,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: h * 0.02),
                          Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: h * 0.02,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: h * 0.03),
                          ElevatedButton.icon(
                            onPressed: controller.retryFetchPersonas,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Retry"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarycolor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.05,
                                vertical: h * 0.015,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.personaList.isEmpty) {
                    return const Center(child: Text("No personas found"));
                  }

                  return ListView.builder(
                    itemCount: controller.personaList.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      Data persona = controller.personaList[index];
                      final image = persona.avatar ?? '';

                      return Obx(
                            () => SelectableTile(
                          title: persona.title ?? 'Unknown',
                          imageUrl: image,
                          isSelected: controller.selectedIndex.value == index,
                          onTap: () => controller.select(index),
                        ),
                      );
                    },
                  );
                }),
              ),

              SizedBox(height: h * 0.01),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Padding(
                    padding: EdgeInsets.all(w * 0.02),
                    child: Container(
                      height: h * 0.015,
                      width: h * 0.015,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == 3
                            ? AppColors.primarycolor
                            : const Color(0xffE6ECEB),
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: h * 0.015),

              // Next button
              Button(
                title: 'Next',
                onTap: () async {
                  if (controller.personaList.isEmpty) {
                    Get.snackbar("Error", "Please select a persona first");
                    return;
                  }

                  if (controller.selectedIndex.value >=
                      controller.personaList.length) {
                    Get.snackbar("Error", "Invalid persona selected");
                    return;
                  }

                  final selectedPersona =
                  controller.personaList[controller.selectedIndex.value];

                  if (selectedPersona.id != null) {
                    await TokenStorage.saveSelectedPersonaId(
                        selectedPersona.id!);
                  }

                  Get.to(() => LogInView());
                },
              ),

              // SizedBox(height: h * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
