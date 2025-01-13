import 'package:get/get.dart';
import 'package:task_manager/app/services/notification_service.dart';
import 'package:task_manager/app/services/task_service.dart';
import 'package:task_manager/app/views/add_task/controller/add_task_controller.dart';

class AddTaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AddTaskController());
    Get.lazyPut(() => TaskService());
    Get.lazyPut(() => LocalNotificationsService());
  }
}
