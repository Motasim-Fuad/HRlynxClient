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

  void pickImage() async {
    try {
      var status = await Permission.photos.request();
      if (!status.isGranted) {
        Get.snackbar("Permission", "Access to gallery denied");
        return;
      }

      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        selectedImage.value = File(picked.path);
      } else {
        Get.snackbar("Cancelled", "No image selected.");
      }
    } catch (e) {
      print("Image picking error: $e");
      Get.snackbar("Error", "Failed to pick image: $e");
    }
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
      // Format date as YYYY-MM-DD for API
      dateOfBirth.value = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void saveData() async {
    // Validation
    if (nameController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your name");
      return;
    }
    if (phoneController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your phone number");
      return;
    }
    // if (selectedGender.value.isEmpty) {
    //   Get.snackbar("Error", "Please select your gender");
    //   return;
    // }
    // if (dateOfBirth.value.isEmpty) {
    //   Get.snackbar("Error", "Please select your date of birth");
    //   return;
    // }

    try {
      isLoading.value = true;

      // Prepare form data
      Map<String, dynamic> profileData = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'bio': bioController.text.trim(),
        'date_of_birth': dateOfBirth.value,
        'gender': selectedGender.value.toLowerCase(),
      };

      print("🚀 Uploading profile data: $profileData");
      print("🖼️ Selected image: ${selectedImage.value?.path}");

      final response = await _authRepository.uploadProfileData(
        profileData,
        imageFile: selectedImage.value,
      );

      print("✅ Upload response: $response");

      if (response != null && response['success'] == true) {
     print("profile update successfull");

          nameController.clear();
          phoneController.clear();
          bioController.clear();
          selectedGender.value = ''; // <-- Clear selected radio button
          dateOfBirth.value = '';     // <-- Optionally clear date
          selectedImage.value = null; // <-- Optionally clear selected image
        // Get the ProfileController and refresh the profile data
        try {
          final ProfileController profileController = Get.find<ProfileController>();
          // FIXED: Now properly awaiting the Future<void> method
          await profileController.refreshProfile();
          print("✅ Profile refreshed successfully");
        } catch (e) {
          print("⚠️ ProfileController not found, creating new one");
          final ProfileController profileController = Get.put(ProfileController());
          // FIXED: Now properly awaiting the Future<void> method
          await profileController.refreshProfile();
        }

        // Navigate back to profile page
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
      print("❌ Error uploading profile: $e");
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