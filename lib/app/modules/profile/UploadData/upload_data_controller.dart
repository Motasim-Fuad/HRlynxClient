import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../api_servies/repository/auth_repo.dart';
import '../profile_controller.dart';

class UploadDataController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();
  var selectedImage = Rxn<File>();
  var networkImageUrl = Rxn<String>(); // Store existing profile picture URL

  var isLoading = false.obs;
  var isFetchingData = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExistingProfileData(); // Load existing data when page opens
  }

  // Fetch existing profile data from API
  void fetchExistingProfileData() async {
    try {
      isFetchingData.value = true;

      final response = await _authRepository.fetchProfileData();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // Pre-fill text fields if data exists
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          nameController.text = data['name'];
        }

        if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
          phoneController.text = data['phone'];
        }

        // Store the profile picture URL if exists
        if (data['profile_picture'] != null &&
            data['profile_picture'].toString().isNotEmpty) {
          networkImageUrl.value = data['profile_picture'];
        }

        print("✅ Profile data loaded successfully");
      }
    } catch (e) {
      print("❌ Error fetching profile data: $e");
      // Don't show error snackbar - just leave fields empty
    } finally {
      isFetchingData.value = false;
    }
  }

  // SIMPLE image picker that works on both platforms
  void pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked != null) {
        selectedImage.value = File(picked.path);
        networkImageUrl.value = null; // Clear network image when new image selected
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

  void saveData() async {
    if (nameController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your name");
      return;
    }
    if (phoneController.text.isEmpty) {
      Get.snackbar("Error", "Please enter your phone number");
      return;
    }
    if (phoneController.text.trim().length > 15) {
      Get.snackbar("Error", "Phone number cannot be more than 15 characters");
      return;
    }

    try {
      isLoading.value = true;

      Map<String, dynamic> profileData = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      };

      final response = await _authRepository.uploadProfileData(
        profileData,
        imageFile: selectedImage.value,
      );

      if (response != null && response['success'] == true) {
        // Refresh ProfileController
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
    super.onClose();
  }
}