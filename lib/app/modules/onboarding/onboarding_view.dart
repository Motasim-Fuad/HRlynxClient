
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/api_servies/token.dart';
import 'package:hr/app/common_widgets/button.dart' show Button;
import 'package:hr/app/common_widgets/hr_select.dart';
import 'package:hr/app/modules/log_in/log_in_view.dart';
import 'package:hr/app/modules/onboarding/onboarding_controller.dart';
import 'package:hr/app/utils/app_colors.dart';
import 'package:hr/app/utils/app_images.dart';
import '../../model/onbordingModel.dart'; // <-- import model

class OnboardingView extends StatelessWidget {
  final HrRoleController controller = Get.put(HrRoleController());

  OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Image.asset(AppImages.splash, height: 170, ),
            const Text(
              'Customize your experience by choosing an AI HR Assistant Persona!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 23,
                color: Color(0xFF2B2323),
              ),
            ),
            // Update your OnboardingView build method
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Loading personas..."),
                      ],
                    ),
                  );
                }

                if (controller.personaList.isEmpty && controller.errorMessage.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: controller.retryFetchPersonas,
                          icon: Icon(Icons.refresh),
                          label: Text("Retry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primarycolor,
                            foregroundColor: Colors.white,
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
                  shrinkWrap: true,
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

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 12,
                    width: 12,
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


            Button(
              title: 'Next',
              onTap: () async {
                if (controller.personaList.isEmpty) {
                  Get.snackbar("Error", "Please select a persona first");
                  return;
                }

                if (controller.selectedIndex.value >= controller.personaList.length) {
                  Get.snackbar("Error", "Invalid persona selected");
                  return;
                }

                final selectedPersona = controller.personaList[controller.selectedIndex.value];

                print(" ########Selected ai persona ### : ${selectedPersona.title}");
                print(" ########Selected ai persona ### : ${selectedPersona.id}");

                if (selectedPersona.id != null) {
                  await TokenStorage.saveSelectedPersonaId(selectedPersona.id!);
                  print("✅ Saved persona ID ${selectedPersona.id} to storage");
                }

                Get.to(() => LogInView());
              },
            ),


          ],
        ),
      ),
    );
  }
}
