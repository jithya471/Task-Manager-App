import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/services/local_storage_service.dart';

class TaskService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _localStorage = Get.put(LocalStorageService());

  final RxList<Task> tasks = <Task>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadLocalTasks();
  }

  Future<void> _loadLocalTasks() async {
    final localTasks = await _localStorage.getAllTasks();
    tasks.assignAll(localTasks);
  }

  Stream<List<Task>> getTasks({
    Set<TaskStatus>? selectedStatuses,
    Set<TaskPriority>? selectedPriorities,
    String? sortBy,
    bool descending = false,
  }) {
    return tasks.stream.map((taskList) {
      var filteredTasks = taskList;

      if (selectedStatuses != null && selectedStatuses.isNotEmpty) {
        filteredTasks = filteredTasks.where((task) {
          return selectedStatuses.contains(task.status);
        }).toList();
      }

      if (selectedPriorities != null && selectedPriorities.isNotEmpty) {
        filteredTasks = filteredTasks.where((task) {
          return selectedPriorities.contains(task.priority);
        }).toList();
      }

      if (sortBy != null) {
        filteredTasks.sort((a, b) {
          final aValue = a.toMap()[sortBy];
          final bValue = b.toMap()[sortBy];
          return descending
              ? bValue.compareTo(aValue)
              : aValue.compareTo(bValue);
        });
      }

      return filteredTasks;
    });
  }

  Future<void> addTask(Task task) async {
    tasks.add(task);
    await _localStorage.saveTask(task);

    try {
      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
      task.isSynced = true;
      await _localStorage.updateTask(task);
    } catch (e) {
      task.isSynced = false;
      await _localStorage.updateTask(task);
    }
  }

  Future<void> updateTask(Task task) async {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await _localStorage.updateTask(task);

      try {
        await _firestore.collection('tasks').doc(task.id).update(task.toMap());
        task.isSynced = true;
        await _localStorage.updateTask(task);
      } catch (e) {
        task.isSynced = false;
        await _localStorage.updateTask(task);
      }
    }
  }

  Future<void> deleteTask(String taskId) async {
    tasks.removeWhere((task) => task.id == taskId);
    await _localStorage.markTaskForDeletion(taskId);

    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      await _localStorage.removeFromDeletionQueue(taskId);
    } catch (e) {
      log('Task marked for deletion: $e');
    }
  }
}
