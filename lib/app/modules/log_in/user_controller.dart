import 'package:HRlynx/app/api_servies/token.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  RxInt? userId = RxInt(0);
  RxString userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final id = await TokenStorage.getUserId();
    final email = await TokenStorage.getUserEmail();

    if (id != null) userId?.value = id;
    if (email != null) userEmail.value = email;
  }
}
