import 'package:get/get.dart';
import 'package:task_manager/app/views/login/controller/login-controller.dart';

class LoginBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => LoginController());
  }
}