import 'package:flutter/material.dart';

import 'habit_completion.dart';

class Habit {
  final String id;
  String name;
  Color color;
  bool isOutdoor;
  DateTime createdAt;
  List<HabitCompletion> completions;

  Habit({
    required this.id,
    required this.name,
    required this.color,
    this.isOutdoor = false,
    required this.createdAt,
    List<HabitCompletion>? completions,
  }) : completions = completions ?? [];

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'isOutdoor': isOutdoor ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, Object?> map, {List<HabitCompletion>? completions}) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      color: Color(map['color'] as int),
      isOutdoor: (map['isOutdoor'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completions: completions,
    );
  }
}
