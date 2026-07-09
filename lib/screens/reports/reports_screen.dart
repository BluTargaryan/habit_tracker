import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/app_drawer.dart';

const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

enum _ReportFilter { all, completed, incomplete }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportFilter _filter = _ReportFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HabitProvider>().loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

    final filteredHabits = habitProvider.habits.where((habit) {
      final completedToday = habitProvider.isCompletedToday(habit);
      switch (_filter) {
        case _ReportFilter.all:
          return true;
        case _ReportFilter.completed:
          return completedToday;
        case _ReportFilter.incomplete:
          return !completedToday;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      drawer: const AppDrawer(),
      body: habitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : habitProvider.habits.isEmpty
              ? const Center(child: Text('No habits yet — add one to see reports.'))
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: SegmentedButton<_ReportFilter>(
                          segments: const [
                            ButtonSegment(value: _ReportFilter.all, label: Text('All')),
                            ButtonSegment(
                              value: _ReportFilter.completed,
                              label: Text('Completed'),
                            ),
                            ButtonSegment(
                              value: _ReportFilter.incomplete,
                              label: Text('Incomplete'),
                            ),
                          ],
                          selected: {_filter},
                          onSelectionChanged: (selection) {
                            setState(() => _filter = selection.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('This Week', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (filteredHabits.isEmpty)
                        const Text('No habits match this filter.')
                      else
                        ...filteredHabits.map(
                          (habit) => _WeeklySummaryTile(habit: habit, days: days),
                        ),
                      const SizedBox(height: 32),
                      Text('Completions by Day', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      if (filteredHabits.isNotEmpty) ...[
                        SizedBox(
                          height: 200,
                          child: _CompletionsChart(habits: filteredHabits, days: days),
                        ),
                        const SizedBox(height: 16),
                        _Legend(habits: filteredHabits),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _WeeklySummaryTile extends StatelessWidget {
  final Habit habit;
  final List<DateTime> days;

  const _WeeklySummaryTile({required this.habit, required this.days});

  @override
  Widget build(BuildContext context) {
    final completedCount = days.where((day) {
      return habit.completions.any(
        (completion) => completion.completed && _isSameDay(completion.date, day),
      );
    }).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: habit.color, radius: 8),
          const SizedBox(width: 12),
          Expanded(child: Text(habit.name)),
          Text('$completedCount/${days.length} days'),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CompletionsChart extends StatelessWidget {
  final List<Habit> habits;
  final List<DateTime> days;

  const _CompletionsChart({required this.habits, required this.days});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final groups = List.generate(days.length, (dayIndex) {
      final day = days[dayIndex];
      return BarChartGroupData(
        x: dayIndex,
        barRods: habits.map((habit) {
          final completed = habit.completions.any(
            (completion) => completion.completed && _isSameDay(completion.date, day),
          );
          return BarChartRodData(
            toY: completed ? 1 : 0,
            color: habit.color,
            width: 6,
          );
        }).toList(),
      );
    });

    return BarChart(
      BarChartData(
        maxY: 1,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: const BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = days[value.toInt() % 7];
                final label = _weekdayLabels[day.weekday - 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barGroups: groups,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<Habit> habits;

  const _Legend({required this.habits});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: habits.map((habit) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, color: habit.color),
            const SizedBox(width: 6),
            Text(habit.name, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}
