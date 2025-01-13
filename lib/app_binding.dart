import 'package:get/get.dart';
import 'package:task_manager/app/services/auth_service.dart';
import 'package:task_manager/app/services/local_storage_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<LocalStorageService>(() => LocalStorageService());
  }
}
