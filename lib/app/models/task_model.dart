class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String userId;
  bool isSynced;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.userId,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.toString(),
      'status': status.toString(),
      'userId': userId,
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: TaskPriority.values.firstWhere(
          (e) => e.toString() == map['priority']),
      status: TaskStatus.values.firstWhere(
          (e) => e.toString() == map['status']),
      userId: map['userId'],
      isSynced: map['isSynced'] ?? true,
    );
  }
}


enum TaskPriority { high, medium, low }

enum TaskStatus { pending, inProgress, completed }
