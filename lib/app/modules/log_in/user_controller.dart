import 'package:get/get.dart';

class UserController extends GetxController {
  var userEmail = ''.obs;

  void setUserEmail(String email) {
    userEmail.value = email;
  }
}