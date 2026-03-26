import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Setup timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );

    // Get android plugin instance — only once
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Step 1 — Create notification channels first
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'event_channel_v3',
          'Calendar Events',
          description: 'Notifications for calendar events',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'weather_channel_v2',
          'Weather Updates',
          description: 'Periodic weather updates',
          importance: Importance.defaultImportance,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'expense_channel',
          'Expense Reminders',
          description: 'Monthly reminders for tracking expenses',
          importance: Importance.defaultImportance,
        ),
      );

      print('Notification channels created');

    }
  }

  static Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final bool? notifGranted = await androidPlugin
          .requestNotificationsPermission();
      final bool? alarmGranted = await androidPlugin
          .requestExactAlarmsPermission();

      print('Notification permission: $notifGranted');
      print('Exact alarm permission: $alarmGranted');
    }
  }
  static Future<void> requestBatteryOptimizationExemption() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    print('Battery optimization status: $status');
    if (!status.isGranted) {
      final result = await Permission.ignoreBatteryOptimizations.request();
      print('Battery optimization result: $result');
    }
  }

  static Future<void> scheduleEventNotification({
    required int id,
    required String title,
    required String note,
    required DateTime scheduledDate,
  }) async {
    await _plugin.cancel(id);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime tzScheduled = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    print('Now:       $now');
    print('Scheduled: $tzScheduled');
    print('Seconds until fire: ${tzScheduled.difference(now).inSeconds}');

    if (tzScheduled.isBefore(now)) {
      print('Time is in the past — skipping.');
      return;
    }

    await _plugin.zonedSchedule(
      id,
      title,
      note.isEmpty ? 'You have an event!' : note,
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_channel_v3',
          'Calendar Events',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          // Removed fullScreenIntent: true because it requires user approval on Android 14+ when installed via APK
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('Notification scheduled for: $tzScheduled');
  }

  static Future<void> showWeatherNotification({
    required String city,
    required String temperature,
    required String description,
  }) async {
    await _plugin.show(
      999,
      '$city $temperature C',
      description,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weather_channel_v2',
          'Weather Updates',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  static Future<void> checkPendingNotifications() async {
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    print('Pending notifications: ${pending.length}');
    for (var n in pending) {
      print('  - ID: ${n.id}, Title: ${n.title}, Body: ${n.body}');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    print('Cancelled notification ID: $id');
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    print('All notifications cancelled');
  }

  static Future<void> scheduleMonthlyExpenseReminders() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final DateFormat formatter = DateFormat('MMMM');
    
    // We schedule notifications for the 1st day of the next 12 months
    for (int i = 0; i < 12; i++) {
      int targetMonth = now.month + i;
      int targetYear = now.year;
      if (targetMonth > 12) {
        targetMonth -= 12;
        targetYear++;
      }
      
      tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, targetYear, targetMonth, 1, 9, 0); // 9:00 AM on the 1st
      
      // If the 1st of this month has already passed, skip the current month
      if (scheduledDate.isBefore(now)) {
        continue;
      }

      final String monthName = formatter.format(scheduledDate);
      
      await _plugin.zonedSchedule(
        1000 + targetMonth, // Unique ID per month so they easily overwrite
        'Expense Planner',
        'It\'s $monthName, ready to plot your expenses now?',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expense_channel',
            'Expense Reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    print('Scheduled rolling 12-month expense reminders.');
  }
}
