// ignore: constant_identifier_names
enum TaskPriority { Low, Medium, High }

class Subtask {
  String id;
  String title;
  bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime? dueDate;
  TaskPriority priority;
  List<Subtask> subtasks;

  static const num maxDescriptionLength = 50;
  static const num maxTitleLength = 20;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.dueDate,
    this.priority = TaskPriority.Medium,
    List<Subtask>? subtasks,
  }) : subtasks = subtasks ?? [];
}
