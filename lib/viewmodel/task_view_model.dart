import 'package:flutter/material.dart';
import 'package:todo_listo/model/task.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_listo/services/notification_service.dart';

class TaskViewModel extends ChangeNotifier {
  final List<Task> _tasks = [];
  final Uuid _uuid = const Uuid();
  bool _showCompleted = true;
  TaskPriority? _filterPriority;
  static const String _storageKey = 'tasks';
  String _searchQuery = '';

  Task? _lastDeletedTask;
  int? _lastDeletedTaskIndex;

  TaskViewModel() {
    _loadTasks();
  }

  List<Task> get tasks {
    return _tasks.where((task) {
      if (!_showCompleted && task.isCompleted) return false;
      if (_filterPriority != null && task.priority != _filterPriority) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        return task.title.toLowerCase().contains(_searchQuery) ||
            task.description.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  List<Task> get completedTasks {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  List<Task> get pendingTasks {
    return _tasks.where((task) => !task.isCompleted).toList();
  }

  bool get showCompleted => _showCompleted;
  TaskPriority? get filterPriority => _filterPriority;

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> tasksJson = _tasks
        .map((task) => {
              'id': task.id,
              'title': task.title,
              'description': task.description,
              'isCompleted': task.isCompleted,
              'dueDate': task.dueDate?.toIso8601String(),
              'priority': task.priority.toString(),
              'subtasks': task.subtasks
                  .map((s) => {
                        'id': s.id,
                        'title': s.title,
                        'isCompleted': s.isCompleted,
                      })
                  .toList(),
            })
        .toList();

    await prefs.setString(_storageKey, jsonEncode(tasksJson));
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_storageKey);

    if (tasksJson != null) {
      final List<dynamic> decodedTasks = jsonDecode(tasksJson);
      _tasks.clear();

      for (final taskMap in decodedTasks) {
        final List<Subtask> subtasks = (taskMap['subtasks'] as List?)
                ?.map((s) => Subtask(
                      id: s['id'],
                      title: s['title'],
                      isCompleted: s['isCompleted'],
                    ))
                .toList() ??
            [];

        _tasks.add(Task(
          id: taskMap['id'],
          title: taskMap['title'],
          description: taskMap['description'],
          isCompleted: taskMap['isCompleted'],
          dueDate: taskMap['dueDate'] != null
              ? DateTime.parse(taskMap['dueDate'])
              : null,
          priority: TaskPriority.values.firstWhere(
            (e) => e.toString() == taskMap['priority'],
            orElse: () => TaskPriority.Medium,
          ),
          subtasks: subtasks,
        ));
      }
      notifyListeners();
    }
  }

  void addTask(
    String taskId,
    String trim, {
    required String title,
    String description = '',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.Medium,
  }) {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
    _tasks.add(task);
    _saveTasks();
    if (dueDate != null) {
      NotificationService.instance.scheduleDueDateNotifications(task);
    }
    notifyListeners();
  }

  void editTask({
    required String id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
  }) {
    final task = _tasks.firstWhere((task) => task.id == id);
    if (title != null) task.title = title;
    if (description != null) task.description = description;
    if (dueDate != null) task.dueDate = dueDate;
    if (priority != null) task.priority = priority;
    _saveTasks();
    NotificationService.instance.scheduleDueDateNotifications(task);
    notifyListeners();
  }

  void setShowCompleted(bool show) {
    _showCompleted = show;
    notifyListeners();
  }

  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void toggleTaskStatus(String id) {
    final task = _tasks.firstWhere((task) => task.id == id);
    task.isCompleted = !task.isCompleted;
    _saveTasks();
    notifyListeners();
  }

  void deleteTask(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    final task = _tasks[index];

    _lastDeletedTask = task;
    _lastDeletedTaskIndex = index;

    NotificationService.instance.cancelNotifications(id);
    _tasks.removeAt(index);
    _saveTasks();
    notifyListeners();
  }

  void undoDeleteTask() {
    if (_lastDeletedTask != null && _lastDeletedTaskIndex != null) {
      _tasks.insert(_lastDeletedTaskIndex!, _lastDeletedTask!);
      if (_lastDeletedTask!.dueDate != null) {
        NotificationService.instance
            .scheduleDueDateNotifications(_lastDeletedTask!);
      }
      _saveTasks();
      _lastDeletedTask = null;
      _lastDeletedTaskIndex = null;
      notifyListeners();
    }
  }

  String? validateTask({
    required String title,
    required String description,
    required DateTime? dueDate,
  }) {
    if (title.isEmpty) {
      return '✎ Necesitas agregar un título';
    }
    if (description.length > Task.maxDescriptionLength) {
      return '📝 La descripción es muy larga';
    }
    if (dueDate == null) {
      return '📅 Selecciona una fecha límite';
    }
    return null;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void toggleSubtask(String taskId, String subtaskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subtask = task.subtasks.firstWhere((s) => s.id == subtaskId);
    subtask.isCompleted = !subtask.isCompleted;
    _saveTasks();
    notifyListeners();
  }

  void deleteSubtask(String taskId, String subtaskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.subtasks.removeWhere((s) => s.id == subtaskId);
    _saveTasks();
    notifyListeners();
  }

  void addSubtask(String taskId, String title) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.subtasks.add(Subtask(
      id: _uuid.v4(),
      title: title,
    ));
    _saveTasks();
    notifyListeners();
  }

  void editSubtask(String taskId, String subtaskId, String title) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subtask = task.subtasks.firstWhere((s) => s.id == subtaskId);
    subtask.title = title;
    _saveTasks();
    notifyListeners();
  }
}
