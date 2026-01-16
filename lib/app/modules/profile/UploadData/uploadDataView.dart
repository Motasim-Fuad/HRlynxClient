import 'dart:io';
import 'package:HRlynx/app/common_widgets/button.dart';
import 'package:HRlynx/app/common_widgets/text_field.dart';
import 'package:HRlynx/app/modules/profile/UploadData/upload_data_controller.dart';
import 'package:HRlynx/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadDataView extends GetView<UploadDataController> {
  const UploadDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Your Data"),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isFetchingData.value) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
              AlwaysStoppedAnimation(AppColors.primarycolor),
            ),
          );
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Profile Image
                Obx(() => GestureDetector(
                  onTap: controller.isLoading.value
                      ? null
                      : controller.pickImage,
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
                )),

                const SizedBox(height: 20),

                /// Name
                SizedBox(
                  width: double.infinity, // 👈 fixed width for center look
                  child: CustomTextFormField(
                    controller: controller.nameController,
                    hintText: "Enter full name",
                  ),
                ),

                const SizedBox(height: 10),

                /// Phone
                SizedBox(
                  width: double.infinity,
                  child: CustomTextFormField(
                    controller: controller.phoneController,
                    hintText: "Enter phone number",
                    keyboardType: TextInputType.phone,
                  ),
                ),

                const SizedBox(height: 20),

                /// Save Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => Button(
                    title: controller.isLoading.value
                        ? "Saving..."
                        : "Save",
                    onTap: controller.isLoading.value
                        ? null
                        : controller.saveData,
                  )),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  DecorationImage? _getImageDecoration() {
    if (controller.selectedImage.value != null) {
      return DecorationImage(
        image: FileImage(controller.selectedImage.value!),
        fit: BoxFit.cover,
      );
    } else if (controller.networkImageUrl.value != null) {
      return DecorationImage(
        image:
        NetworkImage(controller.networkImageUrl.value!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

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
