import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:task_manager/app/models/task_model.dart';

class LocalStorageService extends GetxService {
  late Database _db;

  Future<void> init() async {
    _db = await openDatabase(
      'tasks.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            dueDate TEXT,
            priority TEXT,
            status TEXT,
            userId TEXT,
            isSynced INTEGER,
            isDeleted INTEGER
          )
        ''');
      },
    );
  }

  // Add the missing getTask method
  Future<Task?> getTask(String taskId) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Task.fromMap({
          ...maps.first,
          'isSynced': maps.first['isSynced'] == 1,
          'isDeleted': maps.first['isDeleted'] == 1,
        });
      }
      return null;
    } catch (e) {
      print('Error getting task from local storage: $e');
      return null;
    }
  }

  Future<void> saveTask(Task task) async {
    await _db.insert('tasks', {
      ...task.toMap(),
      'isSynced': task.isSynced ? 1 : 0,
      'isDeleted': 0,
    });
  }

  Future<void> updateTask(Task task) async {
    await _db.update(
      'tasks',
      {
        ...task.toMap(),
        'isSynced': task.isSynced ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String taskId) async {
    await _db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<void> markTaskForDeletion(String taskId) async {
    await _db.update(
      'tasks',
      {'isDeleted': 1, 'isSynced': 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<Task>> getUnsyncedTasks() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tasks',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    return maps
        .map((map) => Task.fromMap({
              ...map,
              'isSynced': map['isSynced'] == 1,
              'isDeleted': map['isDeleted'] == 1,
            }))
        .toList();
  }

  // Added method to clear all tasks
  Future<void> clearAllTasks() async {
    await _db.delete('tasks');
  }

  // Added method to get all tasks
  Future<List<Task>> getAllTasks() async {
    final List<Map<String, dynamic>> maps = await _db.query('tasks');
    return maps
        .map((map) => Task.fromMap({
              ...map,
              'isSynced': map['isSynced'] == 1,
              'isDeleted': map['isDeleted'] == 1,
            }))
        .toList();
  }

  // Added method to check if a task exists
  Future<bool> taskExists(String taskId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }
}
