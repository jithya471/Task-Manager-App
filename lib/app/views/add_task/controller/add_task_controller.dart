import 'dart:developer';

import 'package:get/get.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/services/notification_service.dart';
import 'package:task_manager/app/services/task_service.dart';

class AddTaskController extends GetxController {
  final TaskService _taskService = Get.put(TaskService());
  final LocalNotificationsService _notificationsService =
      Get.put(LocalNotificationsService());
  Future<void> addTask(Task task) async {
    try {
      await _taskService.addTask(task);
      Get.toNamed(AppRoutes.homeView);
    } catch (e) {
      // Log the error for debugging
      log('Error in HomeController.addTask: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    await _taskService.updateTask(task);
    await _notificationsService.updateTaskReminder(task);
  }
}
