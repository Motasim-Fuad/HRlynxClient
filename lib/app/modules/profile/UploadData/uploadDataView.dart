import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hr/app/common_widgets/button.dart';
import 'package:hr/app/common_widgets/text_field.dart';
import 'package:hr/app/modules/profile/UploadData/upload_data_controller.dart' show UploadDataController;

class UploadDataView extends StatelessWidget {
  final controller = Get.put(UploadDataController());
  final dobController = TextEditingController();

  UploadDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Your Data"),
        centerTitle: true,
      ),
      body: Obx(() {
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // SIMPLE Profile Image Picker
                  GestureDetector(
                    onTap: controller.isLoading.value ? null : controller.pickImage,
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20),
                        image: controller.selectedImage.value != null
                            ? DecorationImage(
                          image: FileImage(controller.selectedImage.value!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: controller.selectedImage.value == null
                          ? const Center(
                          child: Icon(Icons.camera_alt_outlined, size: 50)
                      )
                          : null,
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
                  const SizedBox(height: 10),

                  // Bio
                  CustomTextFormField(
                    controller: controller.bioController,
                    hintText: "Write something about you",
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  Button(
                    title: controller.isLoading.value ? "Saving..." : "Save",
                    onTap: controller.isLoading.value
                        ? null
                        : () {
                      controller.saveData();
                      dobController.clear();
                    },
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
    );
  }
}