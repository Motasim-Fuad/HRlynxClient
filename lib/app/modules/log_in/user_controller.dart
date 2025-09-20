import 'package:get/get.dart';

class UserController extends GetxController {
  var userEmail = ''.obs;
  var userID = 0.obs;

  void setUserEmail(String email) {
    userEmail.value = email;
  }

  void setUserID(int id) {
    userID.value = id;
  }
}