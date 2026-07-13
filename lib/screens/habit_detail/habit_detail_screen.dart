import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/habit.dart';
import '../../models/weather.dart';
import '../../providers/habit_provider.dart';
import '../../providers/weather_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/habit_color_picker.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  bool _weatherLoadTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HabitProvider>().loadHabits();
    });
  }

  void _maybeLoadWeather(bool isOutdoor) {
    if (!isOutdoor || _weatherLoadTriggered) return;
    _weatherLoadTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WeatherProvider>().loadIfNeeded();
    });
  }

  Future<void> _showEditHabitDialog(Habit habit) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: habit.name);
    var selectedColor = habit.color;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Habit'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Habit name'),
                      validator: Validators.habitName,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Text('Color', style: Theme.of(dialogContext).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    HabitColorPicker(
                      selectedColor: selectedColor,
                      onColorSelected: (color) {
                        setDialogState(() => selectedColor = color);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await context.read<HabitProvider>().updateHabit(
                          habit.id,
                          name: nameController.text,
                          color: selectedColor,
                        );
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Habit',
      itemName: habit.name,
    );
    if (!confirmed || !mounted) return;

    await context.read<HabitProvider>().deleteHabit(habit.id);
    if (mounted) context.go('/habits');
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final habit = habitProvider.habitById(widget.habitId);

    if (habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit')),
        body: habitProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Habit not found.')),
      );
    }

    final streak = habitProvider.streakFor(habit);
    _maybeLoadWeather(habit.isOutdoor);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditHabitDialog(habit),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteHabit(habit),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: habit.color, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(habit.name, style: Theme.of(context).textTheme.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Outdoor habit'),
              subtitle: const Text('Show a weather snippet on this screen'),
              value: habit.isOutdoor,
              onChanged: (value) => habitProvider.setOutdoor(habit.id, value),
            ),
            if (habit.isOutdoor) ...[
              const SizedBox(height: 8),
              const _WeatherSnippet(),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StreakCard(label: 'Current Streak', value: streak.current)),
                const SizedBox(width: 16),
                Expanded(child: _StreakCard(label: 'Longest Streak', value: streak.longest)),
              ],
            ),
            const SizedBox(height: 32),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _HistoryList(habit: habit),
          ],
        ),
      ),
    );
  }
}

class _WeatherSnippet extends StatelessWidget {
  const _WeatherSnippet();

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();

    if (weatherProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final snapshot = weatherProvider.snapshot;
    if (snapshot == null) {
      // Degrades gracefully — habit screen stays fully functional without weather.
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined),
            const SizedBox(width: 12),
            Text(
              '${describeWeatherCode(snapshot.current.weatherCode)}, '
              '${snapshot.current.temperature.round()}°C',
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String label;
  final int value;

  const _StreakCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$value', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              value == 1 ? '$label (day)' : '$label (days)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final Habit habit;

  const _HistoryList({required this.habit});

  static const _maxHistoryDays = 30;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final createdDay = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
    final daysSinceCreated = DateTime(today.year, today.month, today.day)
            .difference(createdDay)
            .inDays +
        1;
    final historyDays = daysSinceCreated.clamp(1, _maxHistoryDays);

    final days = List.generate(historyDays, (i) => today.subtract(Duration(days: i)));

    return Column(
      children: days.map((day) {
        final completed = habit.completions.any(
          (completion) => completion.completed && _isSameDay(completion.date, day),
        );
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            completed ? Icons.check_circle : Icons.cancel,
            color: completed ? Colors.green : Colors.grey,
          ),
          title: Text(_formatDate(day)),
          trailing: Text(completed ? 'Completed' : 'Missed'),
        );
      }).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
