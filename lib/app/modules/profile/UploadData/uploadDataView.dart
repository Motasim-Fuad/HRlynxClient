import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/common_widgets/text_field.dart';
import 'package:HRlynx/app/modules/profile/UploadData/upload_data_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadDataView extends StatelessWidget {
  final controller = Get.put(UploadDataController());

  UploadDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Your Data"),
        centerTitle: true,
      ),
      body: Center(
        child: Obx(() {
          // Show loading spinner while fetching existing data
          if (controller.isFetchingData.value) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Image Picker with Network Image Support
                    GestureDetector(
                      onTap: controller.isLoading.value ? null : controller.pickImage,
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                          image: _getImageDecoration(),
                        ),
                        child: _getImageChild(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Full Name
                    CustomTextFormField(
                      controller: controller.nameController,
                      hintText: "Enter full name",
                    ),
                    const SizedBox(height: 10),

                    // Phone Number
                    CustomTextFormField(
                      controller: controller.phoneController,
                      hintText: "Enter phone number",
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    // Save Button
                    Button(
                      title: controller.isLoading.value ? "Saving..." : "Save",
                      onTap: controller.isLoading.value ? null : controller.saveData,
                    ),
                  ],
                ),
              ),

              // Loading Overlay
              if (controller.isLoading.value)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.blue),
                            SizedBox(height: 16),
                            Text(
                              "Uploading profile data...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  // Helper method to determine which image to show
  DecorationImage? _getImageDecoration() {
    // Priority: Local file > Network image > null
    if (controller.selectedImage.value != null) {
      return DecorationImage(
        image: FileImage(controller.selectedImage.value!),
        fit: BoxFit.cover,
      );
    } else if (controller.networkImageUrl.value != null) {
      return DecorationImage(
        image: NetworkImage(controller.networkImageUrl.value!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  // Helper method to show camera icon when no image
  Widget? _getImageChild() {
    if (controller.selectedImage.value == null &&
        controller.networkImageUrl.value == null) {
      return const Center(
        child: Icon(Icons.camera_alt_outlined, size: 50),
      );
    }
    return null;
  }
}