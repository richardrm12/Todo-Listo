import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:todo_listo/model/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> scheduleDueDateNotifications(Task task) async {
    if (task.dueDate == null) return;

    // Cancelar notificaciones existentes para esta tarea
    await cancelNotifications(task.id);

    final dueDate = task.dueDate!;
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;

    // Programar notificaciones para 3, 2 y 1 día antes
    for (var daysBeforeDue = 3; daysBeforeDue > 0; daysBeforeDue--) {
      if (daysUntilDue >= daysBeforeDue) {
        final scheduledDate = dueDate.subtract(Duration(days: daysBeforeDue));
        if (scheduledDate.isAfter(now)) {
          await _scheduleNotification(
            id: int.parse(task.id.substring(0, 8), radix: 16) + daysBeforeDue,
            title: 'Recordatorio de tarea',
            body: '¡La tarea "${task.title}" vence en $daysBeforeDue días!',
            scheduledDate: scheduledDate,
          );
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Asegurarnos de que el ID esté dentro del rango válido
    final safeId =
        id.abs() % 100000; // Usar módulo para mantener el número pequeño

    await _notifications.zonedSchedule(
      safeId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotifications(String taskId) async {
    // Convertir solo los primeros 5 caracteres del ID a un número
    final baseId = int.parse(taskId.substring(0, 5), radix: 16);
    for (var i = 1; i <= 3; i++) {
      await _notifications.cancel((baseId + i) % 100000);
    }
  }
}
