import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/services/auth_service.dart';
import 'package:task_manager/app/services/connectivity_service.dart';
import 'package:task_manager/app/services/notification_service.dart';
import 'package:task_manager/app/services/task_service.dart';
import 'package:task_manager/app/utils/color.dart';

class HomeController extends GetxController {
  final TaskService _taskService = Get.put(TaskService());
  final AuthService _authService = Get.put(AuthService());
  final ConnectivityService _connectivityService =
      Get.put(ConnectivityService());

  final LocalNotificationsService _notificationsService =
      Get.put(LocalNotificationsService());

  // Observable lists for tasks
  final RxList<Task> allTasks = <Task>[].obs;
  final RxList<Task> filteredTasks = <Task>[].obs;

  final RxSet<TaskStatus> selectedStatuses = <TaskStatus>{}.obs;
  final RxSet<TaskPriority> selectedPriorities = <TaskPriority>{}.obs;

  // Statistics
  RxInt pendingTasks = 0.obs;
  RxInt inProgressTasks = 0.obs;
  RxInt completedTasks = 0.obs;
  RxInt overdueTasks = 0.obs;

  // Filters
  Rx<TaskStatus?> statusFilter = Rx<TaskStatus?>(null);
  Rx<TaskPriority?> priorityFilter = Rx<TaskPriority?>(null);
  RxString sortBy = 'dueDate'.obs;
  RxBool isDescending = false.obs;

  late StreamSubscription<List<Task>> _tasksSubscription;
  Future<void> syncTask(Task task) async {
    if (!task.isSynced) {
      try {
        Get.snackbar(
          'Syncing',
          'Syncing task "${task.title}"...',
          backgroundColor: Appcolors.lightBlue,
          colorText: Appcolors.white,
          duration: const Duration(seconds: 1),
        );

        await _taskService.updateTask(task);

        Get.snackbar(
          'Success',
          'Task synced successfully',
          backgroundColor: Appcolors.green,
          colorText: Appcolors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to sync task',
          backgroundColor: Appcolors.red,
          colorText: Appcolors.white,
        );
      }
    }
  }

  Future<void> syncAllTasks() async {
    try {
      Get.snackbar(
        'Syncing',
        'Syncing all tasks...',
        backgroundColor: Appcolors.lightBlue,
        colorText: Appcolors.white,
        duration: const Duration(seconds: 1),
      );

      await _connectivityService.syncUnsynedTasks();

      Get.snackbar(
        'Success',
        'All tasks synced successfully',
        backgroundColor: Appcolors.green,
        colorText: Appcolors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sync tasks',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeTasksStream();
    ever(selectedStatuses, (_) => _updateTasksStream());
    ever(selectedPriorities, (_) => _updateTasksStream());
    ever(sortBy, (_) => _updateTasksStream());
    ever(isDescending, (_) => _updateTasksStream());
  }

  void _initializeTasksStream() {
    _tasksSubscription = _taskService
        .getTasks(
          selectedStatuses:
              selectedStatuses.isNotEmpty ? selectedStatuses : null,
          selectedPriorities:
              selectedPriorities.isNotEmpty ? selectedPriorities : null,
          sortBy: sortBy.value,
          descending: isDescending.value,
        )
        .listen(_updateTaskStats);
  }

  void _updateTasksStream() {
    _tasksSubscription.cancel();
    _initializeTasksStream();
  }

  void _updateTaskStats(List<Task> tasks) {
    allTasks.value = tasks;
    filteredTasks.value = tasks;

    pendingTasks.value =
        tasks.where((t) => t.status == TaskStatus.pending).length;
    inProgressTasks.value =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    completedTasks.value =
        tasks.where((t) => t.status == TaskStatus.completed).length;

    final now = DateTime.now();
    overdueTasks.value = tasks
        .where(
            (t) => t.status != TaskStatus.completed && t.dueDate.isBefore(now))
        .length;
  }

  List<Task> getTasksForDay(DateTime day) {
    return allTasks.where((task) => isSameDay(task.dueDate, day)).toList();
  }

  void filterTasksByDate(DateTime date) {
    filteredTasks.value =
        allTasks.where((task) => isSameDay(task.dueDate, date)).toList();
  }

  // Helper method for date comparison
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
    await _notificationsService.cancelTaskReminder(taskId);
  }

  

  Future<void> logout() async {
    final confirm = await Get.dialog(
      AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logoutUser();
      Get.offAll(
          () => AppRoutes.loginView); 
      Get.snackbar(
        'Logged Out',
        'You have successfully logged out.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Appcolors.green,
        colorText: Appcolors.white,
      );
    }
  }

  void filterByStatus(TaskStatus? status) {
    statusFilter.value = status;
    _updateFilteredTasks();
  }

  void filterByPriority(TaskPriority? priority) {
    priorityFilter.value = priority;
    _updateFilteredTasks();
  }

  Future<void> updateTaskStatus(Task task, TaskStatus newStatus) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      status: newStatus,
      userId: task.userId,
      isSynced: task.isSynced,
    );

    try {
      await _taskService.updateTask(updatedTask);
      Get.snackbar(
        'Success',
        'Task status updated successfully',
        backgroundColor: Appcolors.green,
        colorText: Appcolors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update task status',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.white,
      );
    }
  }

  void toggleStatusFilter(TaskStatus status) {
    if (selectedStatuses.contains(status)) {
      selectedStatuses.remove(status);
    } else {
      selectedStatuses.add(status);
    }
    _updateFilteredTasks();
  }

  void togglePriorityFilter(TaskPriority priority) {
    if (selectedPriorities.contains(priority)) {
      selectedPriorities.remove(priority);
    } else {
      selectedPriorities.add(priority);
    }
    _updateFilteredTasks();
  }

  int get appliedFiltersCount {
    return selectedStatuses.length + selectedPriorities.length;
  }

  void _updateFilteredTasks() {
    filteredTasks.value = allTasks.where((task) {
      final matchesStatus =
          selectedStatuses.isEmpty || selectedStatuses.contains(task.status);
      final matchesPriority = selectedPriorities.isEmpty ||
          selectedPriorities.contains(task.priority);
      return matchesStatus && matchesPriority;
    }).toList();
  }

  void clearFilters() {
    selectedStatuses.clear();
    selectedPriorities.clear();
    sortBy.value = 'dueDate';
    isDescending.value = false;
  }

  void updateSorting(String field, bool descending) {
    sortBy.value = field;
    isDescending.value = descending;
  }

  @override
  void onClose() {
    _tasksSubscription.cancel();
    super.onClose();
  }
}
