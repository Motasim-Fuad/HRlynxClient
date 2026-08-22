import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../api_servies/repository/auth_repo.dart';
import '../profile_controller.dart';

class UploadDataController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();

  final selectedImage = Rxn<File>();
  final networkImageUrl = Rxn<String>();

  final isLoading = false.obs;
  final isFetchingData = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExistingProfileData();
  }

  Future<void> fetchExistingProfileData() async {
    try {
      isFetchingData.value = true;

      final response =
      await _authRepository.fetchProfileData();

      if (response != null && response['success'] == true) {
        final data = response['data'];

        if (data['name'] != null) {
          nameController.text = data['name'];
        }

        if (data['phone'] != null) {
          phoneController.text = data['phone'];
        }

        if (data['profile_picture'] != null &&
            data['profile_picture'].toString().isNotEmpty) {
          networkImageUrl.value = data['profile_picture'];
        }
      }
    } catch (_) {
    } finally {
      isFetchingData.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked != null) {
        selectedImage.value = File(picked.path);
        networkImageUrl.value = null;
      }
    } catch (e) {
      if (e.toString().contains('permission')) {
        _handlePermissionError();
      }
    }
  }

  void _handlePermissionError() {
    Get.snackbar(
      "Permission Required",
      "Please enable photo access in Settings",
      mainButton: TextButton(
        onPressed: () => openAppSettings(),
        child: const Text(
          "Open Settings",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> saveData() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty) {
      Get.snackbar("Error", "All fields are required");
      return;
    }

    if (phoneController.text.length > 15) {
      Get.snackbar(
          "Error", "Phone number too long");
      return;
    }

    try {
      isLoading.value = true;

      final response =
      await _authRepository.uploadProfileData(
        {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
        imageFile: selectedImage.value,
      );

      if (response != null && response['success'] == true) {
        final profileController =
        Get.put(ProfileController());
        await profileController.refreshProfile();
        Get.back(result: true);
      } else {
        Get.snackbar("Error",
            response?['message'] ?? "Failed");
      }
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
