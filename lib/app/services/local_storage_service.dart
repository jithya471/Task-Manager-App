import 'dart:developer';

import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:task_manager/app/models/task_model.dart';

import 'package:get/get.dart';

class LocalStorageService extends GetxService {
  late Database _db;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initDatabase();
  }

  Future<void> _initDatabase() async {
    try {
      _db = await openDatabase(
        join(await getDatabasesPath(), 'tasks.db'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS tasks(
              id TEXT PRIMARY KEY,
              title TEXT,
              description TEXT,
              dueDate TEXT,
              priority TEXT,
              status TEXT,
              userId TEXT,
              isSynced INTEGER DEFAULT 1,
              isDeleted INTEGER DEFAULT 0
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Add isDeleted column if upgrading from version 1
            await db.execute(
                'ALTER TABLE tasks ADD COLUMN isDeleted INTEGER DEFAULT 0');
          }
        },
        version: 2,
      );
      log('Database initialized successfully');
    } catch (e) {
      log('Error initializing database: $e');
      rethrow;
    }
  }

  Future<Database> get database async {
    if (_db == null) {
      await _initDatabase();
    }
    return _db;
  }

  Future<List<Task>> getUnsyncedTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'isSynced = ? AND isDeleted = ?',
        whereArgs: [0, 0],
      );
      return maps.map((map) => Task.fromMap(map)).toList();
    } catch (e) {
      log('Error getting unsynced tasks: $e');
      return [];
    }
  }

  Future<List<String>> getTasksToDelete() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        columns: ['id'],
        where: 'isDeleted = ?',
        whereArgs: [1],
      );
      return maps.map((map) => map['id'] as String).toList();
    } catch (e) {
      log('Error getting tasks to delete: $e');
      return [];
    }
  }

  // Mark a task as synced
  Future<void> markTaskSynced(String taskId) async {
    try {
      final db = await database;
      await db.update(
        'tasks',
        {'isSynced': 1},
        where: 'id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      log('Error marking task as synced: $e');
    }
  }

  // Remove a task from the deletion queue
  Future<void> removeFromDeletionQueue(String taskId) async {
    try {
      final db = await database;
      await db.delete(
        'tasks',
        where: 'id = ? AND isDeleted = ?',
        whereArgs: [taskId, 1],
      );
    } catch (e) {
      log('Error removing task from deletion queue: $e');
    }
  }

  // Override the original saveTask to include sync status
  Future<void> saveTask(Task task) async {
    try {
      final db = await database;
      await db.insert('tasks', {
        ...task.toMap(),
        'isSynced': task.isSynced ? 1 : 0,
        'isDeleted': 0,
      });
    } catch (e) {
      log('Error saving task: $e');
    }
  }

  // Override the original updateTask to include sync status
  Future<void> updateTask(Task task) async {
    try {
      final db = await database;
      await db.update(
        'tasks',
        {
          ...task.toMap(),
          'isSynced': task.isSynced ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      log('Error updating task: $e');
    }
  }

  // Update the markTaskForDeletion method
  Future<void> markTaskForDeletion(String taskId) async {
    try {
      final db = await database;
      await db.update(
        'tasks',
        {
          'isDeleted': 1,
          'isSynced': 0,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      log('Error marking task for deletion: $e');
    }
  }

  // Modified getTask to handle deleted status
  Future<Task?> getTask(String taskId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'id = ? AND isDeleted = ?',
        whereArgs: [taskId, 0],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        final map = maps.first;
        return Task.fromMap({
          ...map,
          'isSynced': map['isSynced'] == 1,
        });
      }
      return null;
    } catch (e) {
      log('Error getting task: $e');
      return null;
    }
  }

  Future<List<Task>> getAllTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'isDeleted = ?',
        whereArgs: [0],
      );
      return maps
          .map((map) => Task.fromMap({
                ...map,
                'isSynced': map['isSynced'] == 1,
              }))
          .toList();
    } catch (e) {
      log('Error fetching all tasks: $e');
      return [];
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final db = await database;
      await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
    } catch (e) {
      log('Error deleting task: $e');
    }
  }
}
