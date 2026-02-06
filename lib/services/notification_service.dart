import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    // iOS
    final iosResult = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+
    final androidResult = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (iosResult ?? true) && (androidResult ?? true);
  }

  Future<void> scheduleMaintenanceReminder({
    required int taskId,
    required String taskName,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      taskId,
      'Maintenance Reminder',
      '$taskName is due soon',
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'maintenance_reminders',
          'Maintenance Reminders',
          channelDescription: 'Reminders for tank maintenance tasks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int taskId) async {
    await _plugin.cancel(taskId);
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }
}
