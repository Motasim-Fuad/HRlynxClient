import 'package:get/get.dart';
import 'upload_data_controller.dart';

class UploadDataBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UploadDataController>(
          () => UploadDataController(),
      fenix: true,
    );
  }
}
