import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/services/auth_service.dart';
import 'package:task_manager/app/services/local_storage_service.dart';
import 'package:task_manager/app/utils/color.dart';

class TaskService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _localStorage = Get.put(LocalStorageService());
  final _authService = Get.put(AuthService());

  Stream<List<Task>> getTasks({
    TaskStatus? statusFilter,
    TaskPriority? priorityFilter,
    String? sortBy,
    bool descending = false,
  }) {
    Query query = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _authService.user.value?.uid);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.toString());
    }

    if (priorityFilter != null) {
      query = query.where('priority', isEqualTo: priorityFilter.toString());
    }

    if (sortBy != null) {
      query = query.orderBy(sortBy, descending: descending);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addTask(Task task) async {
    try {
      // Try Firebase first
      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
      await _localStorage.saveTask(task);
      return;
    } catch (e) {
      // Handle offline case
      try {
        task.isSynced = false;
        await _localStorage.saveTask(task);
        return;
      } catch (localError) {
        // Only throw if both Firebase and local storage fail
        throw Exception('Failed to save task: ${localError.toString()}');
      }
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toMap());
      await _localStorage.updateTask(task);
    } catch (e) {
      task.isSynced = false;
      await _localStorage.updateTask(task);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      await _localStorage.deleteTask(taskId);
    } catch (e) {
      await _localStorage.markTaskForDeletion(taskId);
      rethrow;
    }
  }

  Future<void> batchUpdateTasks(
      List<String> taskIds, Map<String, dynamic> updates) async {
    final batch = _firestore.batch();

    for (final taskId in taskIds) {
      final taskRef = _firestore.collection('tasks').doc(taskId);
      batch.update(taskRef, updates);
    }

    try {
      await batch.commit();
    } catch (e) {
      // Handle offline case - save updates locally
      for (final taskId in taskIds) {
        final task = await getTaskById(taskId);
        if (task != null) {
          task.isSynced = false;
          await _localStorage.updateTask(task);
        }
      }
      rethrow;
    }
  }

  // Added helper method to get single task
  Future<Task?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        return Task.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Try to get from local storage if offline
      return await _localStorage.getTask(taskId);
    }
  }

  // Added method to sync offline tasks
  Future<void> syncOfflineTasks() async {
    try {
      final unsyncedTasks = await _localStorage.getUnsyncedTasks();
      for (final task in unsyncedTasks) {
        if (task.isSynced == false) {
          await _firestore.collection('tasks').doc(task.id).set(task.toMap());
          task.isSynced = true;
          await _localStorage.updateTask(task);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Sync Error',
        'Failed to sync some tasks. Will try again later.',
        backgroundColor: Appcolors.red,
        colorText: Appcolors.red,
      );
      rethrow;
    }
  }
}
