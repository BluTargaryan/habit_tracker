import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_settings.dart';

/// Clock time each [NotificationTime] slot fires at.
const Map<NotificationTime, (int hour, int minute)> notificationTimeOfDay = {
  NotificationTime.morning: (8, 0),
  NotificationTime.afternoon: (13, 0),
  NotificationTime.evening: (19, 0),
};

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings: settings);

    _initialized = true;
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      id: 0,
      title: 'Test Notification',
      body: 'This is what your habit reminders will look like.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Reminders to complete your habits',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleForHabit({
    required String habitId,
    required String habitName,
    required List<NotificationTime> times,
  }) async {
    for (final time in times) {
      final (hour, minute) = notificationTimeOfDay[time]!;
      await _plugin.zonedSchedule(
        id: _notificationId(habitId, time),
        title: 'Habit Reminder',
        body: 'Time to work on "$habitName"',
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Reminders to complete your habits',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelForHabit(String habitId) async {
    for (final time in NotificationTime.values) {
      await _plugin.cancel(id: _notificationId(habitId, time));
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _notificationId(String habitId, NotificationTime time) {
    return (habitId.hashCode ^ time.index) & 0x7fffffff;
  }
}
