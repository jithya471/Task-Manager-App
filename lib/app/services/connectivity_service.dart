import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:task_manager/app/services/local_storage_service.dart';
import 'package:task_manager/app/services/task_service.dart';

class ConnectivityService extends GetxService {
  final TaskService _taskService = Get.find();
  final LocalStorageService _localStorage = Get.find();
  final _connectivity = Rx<ConnectivityResult>(ConnectivityResult.none);
  final _hasConnection = false.obs;

  bool get hasConnection => _hasConnection.value;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _setupConnectivityStream();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Couldn\'t check connectivity status: $e');
    }
  }

  void _setupConnectivityStream() {
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectivity.value = result;
    _hasConnection.value = result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile;

    if (_hasConnection.value) {
      syncUnsynedTasks();
    }
  }

  Future<void> syncUnsynedTasks() async {
    if (!_hasConnection.value) return;

    try {
      // Get all unsynced tasks and deletions
      final unsyncedTasks = await _localStorage.getUnsyncedTasks();
      final tasksToDelete = await _localStorage.getTasksToDelete();

      // Process deletions
      for (final taskId in tasksToDelete) {
        try {
          await _taskService.deleteTask(taskId);
          await _localStorage.removeFromDeletionQueue(taskId);
        } catch (e) {
          print('Error deleting task $taskId: $e');
        }
      }

      // Process updates/creations
      for (final task in unsyncedTasks) {
        try {
          if (task.id.isEmpty) {
            await _taskService.addTask(task);
          } else {
            await _taskService.updateTask(task);
          }
          await _localStorage.markTaskSynced(task.id);
        } catch (e) {
          print('Error syncing task ${task.id}: $e');
        }
      }
    } catch (e) {
      print('Error during sync: $e');
    }
  }
}
