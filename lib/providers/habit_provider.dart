import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_completion.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../utils/id_generator.dart';

class HabitProvider extends ChangeNotifier {
  final DbService _dbService;
  final NotificationService _notificationService;

  HabitProvider({DbService? dbService, NotificationService? notificationService})
      : _dbService = dbService ?? DbService.instance,
        _notificationService = notificationService ?? NotificationService.instance;

  List<Habit> habits = [];
  bool isLoading = false;

  Future<void> loadHabits() async {
    isLoading = true;
    notifyListeners();

    habits = await _dbService.getAllHabits();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit(String name, {required Color color}) async {
    final habit = Habit(
      id: generateId(),
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
    );

    await _dbService.insertHabit(habit);
    habits = [...habits, habit];
    notifyListeners();
  }

  Future<void> updateHabit(String habitId, {required String name, required Color color}) async {
    final habit = habitById(habitId);
    if (habit == null) return;

    habit.name = name.trim();
    habit.color = color;

    await _dbService.updateHabit(habit);
    habits = [...habits];
    notifyListeners();
  }

  Future<void> setOutdoor(String habitId, bool isOutdoor) async {
    final habit = habitById(habitId);
    if (habit == null) return;

    habit.isOutdoor = isOutdoor;

    await _dbService.updateHabit(habit);
    habits = [...habits];
    notifyListeners();
  }

  Future<void> deleteHabit(String habitId) async {
    await _dbService.deleteHabit(habitId);
    await _notificationService.cancelForHabit(habitId);
    habits = habits.where((habit) => habit.id != habitId).toList();
    notifyListeners();
  }

  Habit? habitById(String habitId) {
    for (final habit in habits) {
      if (habit.id == habitId) return habit;
    }
    return null;
  }

  /// Current streak uses a grace period: if today isn't marked complete yet,
  /// the streak still counts from yesterday backward — it isn't broken until
  /// a full day passes with no completion.
  ({int current, int longest}) streakFor(Habit habit) {
    final completedDays = habit.completions
        .where((completion) => completion.completed)
        .map((completion) => _dayOnly(completion.date))
        .toSet();

    if (completedDays.isEmpty) {
      return (current: 0, longest: 0);
    }

    final sortedDays = completedDays.toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sortedDays.length; i++) {
      final gap = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }

    final today = _dayOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    var cursor = completedDays.contains(today)
        ? today
        : completedDays.contains(yesterday)
            ? yesterday
            : null;

    var current = 0;
    while (cursor != null && completedDays.contains(cursor)) {
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return (current: current, longest: longest);
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool isCompletedToday(Habit habit) {
    final today = _dateOnly(DateTime.now());
    return habit.completions.any(
      (completion) => completion.completed && _dateOnly(completion.date) == today,
    );
  }

  Future<void> toggleTodayCompletion(Habit habit) async {
    final newValue = !isCompletedToday(habit);
    await _dbService.setCompletionForToday(habit.id, newValue);

    final today = _dateOnly(DateTime.now());
    habit.completions = [
      ...habit.completions.where((completion) => _dateOnly(completion.date) != today),
      HabitCompletion(date: DateTime.now(), completed: newValue),
    ];
    notifyListeners();
  }

  String _dateOnly(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
