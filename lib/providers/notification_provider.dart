import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../models/notification_settings.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const _enabledKey = 'notifications.enabled';
  static const _habitIdsKey = 'notifications.habitIds';
  static const _timesKey = 'notifications.times';

  final NotificationService _notificationService;

  NotificationProvider({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService.instance;

  NotificationSettings settings = NotificationSettings();
  bool isLoading = false;

  Future<void> loadSettings() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    settings = NotificationSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      habitIds: prefs.getStringList(_habitIdsKey) ?? [],
      times: (prefs.getStringList(_timesKey) ?? [])
          .map((name) => NotificationTime.values.byName(name))
          .toList(),
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value, List<Habit> habits) async {
    settings.enabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);

    if (value) {
      await _notificationService.requestPermission();
    }
    await _reschedule(habits);
  }

  Future<void> toggleHabit(String habitId, List<Habit> habits) async {
    final habitIds = [...settings.habitIds];
    if (habitIds.contains(habitId)) {
      habitIds.remove(habitId);
    } else {
      habitIds.add(habitId);
    }
    settings.habitIds = habitIds;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_habitIdsKey, habitIds);
    await _reschedule(habits);
  }

  Future<void> toggleTime(NotificationTime time, List<Habit> habits) async {
    final times = [...settings.times];
    if (times.contains(time)) {
      times.remove(time);
    } else {
      times.add(time);
    }
    settings.times = times;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_timesKey, times.map((time) => time.name).toList());
    await _reschedule(habits);
  }

  Future<void> sendTestNotification() async {
    await _notificationService.requestPermission();
    await _notificationService.showTestNotification();
  }

  Future<void> _reschedule(List<Habit> habits) async {
    await _notificationService.cancelAll();
    if (!settings.enabled) return;

    for (final habit in habits) {
      if (settings.habitIds.contains(habit.id)) {
        await _notificationService.scheduleForHabit(
          habitId: habit.id,
          habitName: habit.name,
          times: settings.times,
        );
      }
    }
  }
}
