import 'package:HRlynx/app/api_servies/token.dart';
import 'package:get/get.dart';
import '../../api_servies/repository/auth_repo.dart';

class ProfileController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  var isLoading = false.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userPhone = ''.obs;
  var userBio = ''.obs;
  var userGender = ''.obs;
  var userDateOfBirth = ''.obs;
  var userProfilePicture = ''.obs;
  var isProfileCompleted = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;


  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';


      print("Fetching user profile...");

      final response = await _authRepository.fetchProfileData();

      print("Profile response: $response");

      if (response != null && response['success'] == true) {
        final data = response['data'];

        userName.value = data['name']?.toString() ?? '';
        userEmail.value = data['email']?.toString() ?? '';
        userPhone.value = data['phone']?.toString() ?? '';
        userBio.value = data['bio']?.toString() ?? '';
        userGender.value = data['gender']?.toString() ?? '';
        userDateOfBirth.value = data['date_of_birth']?.toString() ?? '';

        String profilePicUrl = data['profile_picture']?.toString() ?? '';
        if (profilePicUrl.isNotEmpty && _isValidUrl(profilePicUrl)) {
          userProfilePicture.value = profilePicUrl;
        } else {
          userProfilePicture.value = '';
          print("Invalid or empty profile picture URL: $profilePicUrl");
        }

        isProfileCompleted.value = data['profile_completed'] ?? false;

        print("Profile loaded successfully:");
        print("Name: ${userName.value}");
        print("Email: ${userEmail.value}");
        print("Profile Picture: ${userProfilePicture.value}");
        print("Completed: ${isProfileCompleted.value}");
      } else {
        hasError.value = true;
        errorMessage.value = response?['message'] ?? 'Failed to load profile';
        print("Failed to fetch profile: ${errorMessage.value}");
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Network error occurred';
      print("Error fetching profile: $e");

      _setDefaultValues();
    } finally {
      isLoading.value = false;
    }
  }

  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  void _setDefaultValues() {
    userName.value = '';
    userEmail.value = '';
    userPhone.value = '';
    userBio.value = '';
    userGender.value = '';
    userDateOfBirth.value = '';
    userProfilePicture.value = '';
    isProfileCompleted.value = false;
  }

  Future<void> refreshProfile() async {
    print("Refreshing profile data...");
    await fetchUserProfile();
  }

  void retryProfilePicture() {
    if (userProfilePicture.value.isNotEmpty) {
      String originalUrl = userProfilePicture.value;
      userProfilePicture.value = '';
      Future.delayed(Duration(milliseconds: 100), () {
        userProfilePicture.value = originalUrl;
      });
    }
  }

  bool get hasProfileData => userName.value.isNotEmpty || userEmail.value.isNotEmpty;

  bool get hasValidProfilePicture => userProfilePicture.value.isNotEmpty && _isValidUrl(userProfilePicture.value);
}
