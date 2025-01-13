import 'dart:developer';
import 'package:get/get.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/services/task_service.dart';

class AddTaskController extends GetxController {
  late final TaskService _taskService;

  @override
  void onInit() {
    super.onInit();
    _taskService = Get.find<TaskService>();
  }

  Future<bool> addTask(Task task) async {
    try {
      await _taskService.addTask(task); 
      return true;
    } catch (e) {
      log('Error in AddTaskController.addTask: $e');
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      await _taskService.updateTask(task); 
      return true;
    } catch (e) {
      log('Error in AddTaskController.updateTask: $e');
      return false;
    }
  }
}
