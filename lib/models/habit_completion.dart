class HabitCompletion {
  final DateTime date;
  final bool completed;

  const HabitCompletion({required this.date, required this.completed});

  Map<String, Object?> toMap(String habitId) {
    return {
      'habitId': habitId,
      'date': _dateOnly(date),
      'completed': completed ? 1 : 0,
    };
  }

  factory HabitCompletion.fromMap(Map<String, Object?> map) {
    return HabitCompletion(
      date: DateTime.parse(map['date'] as String),
      completed: (map['completed'] as int) == 1,
    );
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
