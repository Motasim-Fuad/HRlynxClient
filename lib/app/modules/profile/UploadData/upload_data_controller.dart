import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../api_servies/repository/auth_repo.dart';
import '../profile_controller.dart'; // Import ProfileController

class UploadDataController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();
  var selectedImage = Rxn<File>();
  var selectedGender = ''.obs;
  var dateOfBirth = ''.obs;
  var isLoading = false.obs;

  // SIMPLE image picker that works on both platforms
  void pickImage() async {
    try {
      // Just pick the image directly - let ImagePicker handle permissions
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked != null) {
        selectedImage.value = File(picked.path);
        print("✅ Image selected: ${picked.path}");
      } else {
        Get.snackbar("Cancelled", "No image selected.");
      }
    } catch (e) {
      print("❌ Error: $e");
      if (e.toString().toLowerCase().contains('permission')) {
        _handlePermissionError();
      } else {
        Get.snackbar("Error", "Failed to pick image");
      }
    }
  }

  void _handlePermissionError() {
    Get.snackbar(
      "Permission Required",
      "Please enable photo access in Settings",
      duration: Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () => openAppSettings(),
        child: Text("Open Settings", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      dateOfBirth.value = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void saveData() async {
    if (nameController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your name");
      return;
    }
    if (phoneController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your phone number");
      return;
    }

    try {
      isLoading.value = true;

      Map<String, dynamic> profileData = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'bio': bioController.text.trim(),
        'date_of_birth': dateOfBirth.value,
        'gender': selectedGender.value.toLowerCase(),
      };

      final response = await _authRepository.uploadProfileData(
        profileData,
        imageFile: selectedImage.value,
      );

      if (response != null && response['success'] == true) {
        nameController.clear();
        phoneController.clear();
        bioController.clear();
        selectedGender.value = '';
        dateOfBirth.value = '';
        selectedImage.value = null;

        try {
          final ProfileController profileController = Get.find<ProfileController>();
          await profileController.refreshProfile();
        } catch (e) {
          final ProfileController profileController = Get.put(ProfileController());
          await profileController.refreshProfile();
        }

        Get.back();
      } else {
        Get.snackbar(
          "Error",
          response?['message'] ?? "Failed to update profile",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to update profile: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    bioController.dispose();
    super.onClose();
  }
}