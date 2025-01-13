import 'dart:async';

import 'package:get/get.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/services/auth_service.dart';
import 'package:task_manager/app/services/notification_service.dart';
import 'package:task_manager/app/services/task_service.dart';

class HomeController extends GetxController {
  final TaskService _taskService = Get.put(TaskService());
  final AuthService _authService = Get.put(AuthService());

  final LocalNotificationsService _notificationsService =
      Get.put(LocalNotificationsService());

  // Observable lists for tasks
  final RxList<Task> allTasks = <Task>[].obs;
  final RxList<Task> filteredTasks = <Task>[].obs;

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

  @override
  void onInit() {
    super.onInit();
    _initializeTasksStream();
    ever(statusFilter, (_) => _updateTasksStream());
    ever(priorityFilter, (_) => _updateTasksStream());
    ever(sortBy, (_) => _updateTasksStream());
    ever(isDescending, (_) => _updateTasksStream());
  }

  void _initializeTasksStream() {
    _tasksSubscription = _taskService
        .getTasks(
          statusFilter: statusFilter.value,
          priorityFilter: priorityFilter.value,
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

  Future<void> batchUpdateTasks(
      List<String> taskIds, TaskStatus newStatus) async {
    await _taskService
        .batchUpdateTasks(taskIds, {'status': newStatus.toString()});
  }

  Future<void> batchDeleteTasks(List<String> taskIds) async {
    for (final taskId in taskIds) {
      await deleteTask(taskId);
    }
  }

  Future<void> logout() async {
    await _authService.logoutUser();
  }

  void filterByStatus(TaskStatus? status) {
    statusFilter.value = status;
  }

  void filterByPriority(TaskPriority? priority) {
    priorityFilter.value = priority;
  }

  void updateSorting(String field, bool descending) {
    sortBy.value = field;
    isDescending.value = descending;
  }

  void clearFilters() {
    statusFilter.value = null;
    priorityFilter.value = null;
    sortBy.value = 'dueDate';
    isDescending.value = false;
  }

  @override
  void onClose() {
    _tasksSubscription.cancel();
    super.onClose();
  }
}
