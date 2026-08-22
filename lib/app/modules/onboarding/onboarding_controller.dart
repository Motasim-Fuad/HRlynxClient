import 'package:HRlynx/app/api_servies/repository/auth_repo.dart';
import 'package:HRlynx/app/model/onbordingModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HrRoleController extends GetxController {
  var selectedIndex = 0.obs;
  var personaList = <Data>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  final authRepo = AuthRepository();

  void select(int index) {
    if (index >= 0 && index < personaList.length) {
      selectedIndex.value = index;
    }
  }

  Future<void> fetchPersonas() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('Fetching personas...');
      final response = await authRepo.getParsonaType();

      print('Received response: $response');
      final model = OnbordingModel.fromJson(response);
      personaList.value = model.data ?? [];

      for (var p in personaList) {
        print('Avatar URL: ${p.avatar}');
      }

      if (personaList.isEmpty) {
        errorMessage.value = 'No personas available';
      }

    } catch (e) {
      print("Error fetching personas: $e");

      if (e.toString().contains('CloudFlare') ||
          e.toString().contains('523') ||
          e.toString().contains('tunnel') ||
          e.toString().contains('HTML instead of JSON')) {
        errorMessage.value = 'Server temporarily unavailable. Please try again.';
        Get.snackbar(
          "Connection Issue",
          "Please check your internet connection and try again.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      } else {
        errorMessage.value = 'Failed to load personas';
        Get.snackbar("Error", "Failed to load personas. Please try again.");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> retryFetchPersonas() async {
    await fetchPersonas();
  }

  @override
  void onInit() {
    fetchPersonas();
    super.onInit();
  }
}
