import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/habit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/quote_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HabitProvider>().loadHabits();
      context.read<QuoteProvider>().loadIfNeeded();
      context.read<WeatherProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().currentUser?.name;
    final habitProvider = context.watch<HabitProvider>();
    final quoteProvider = context.watch<QuoteProvider>();
    final weatherProvider = context.watch<WeatherProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              name != null ? 'Welcome back, $name' : 'Welcome back',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Weekly Progress',
              child: habitProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _WeeklyProgress(habits: habitProvider.habits),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Completed Today',
              child: habitProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _CompletedToday(habitProvider: habitProvider),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Motivation & Weather',
              onTap: () => context.go('/motivation'),
              child: _MotivationWeatherPreview(
                quoteProvider: quoteProvider,
                weatherProvider: weatherProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyProgress extends StatelessWidget {
  final List<Habit> habits;

  const _WeeklyProgress({required this.habits});

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Text('No habits yet — add one to start tracking your progress.');
    }

    final days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: habits.map((habit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(habit.name, overflow: TextOverflow.ellipsis),
              ),
              ...days.map((day) {
                final completedThatDay = habit.completions.any(
                  (completion) => completion.completed && _isSameDay(completion.date, day),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    completedThatDay ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: completedThatDay ? habit.color : Colors.grey,
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CompletedToday extends StatelessWidget {
  final HabitProvider habitProvider;

  const _CompletedToday({required this.habitProvider});

  @override
  Widget build(BuildContext context) {
    final completed = habitProvider.habits.where(habitProvider.isCompletedToday).toList();

    if (completed.isEmpty) {
      return const Text('No habits completed today.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: completed.map((habit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: habit.color),
              const SizedBox(width: 8),
              Text(habit.name),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MotivationWeatherPreview extends StatelessWidget {
  final QuoteProvider quoteProvider;
  final WeatherProvider weatherProvider;

  const _MotivationWeatherPreview({required this.quoteProvider, required this.weatherProvider});

  @override
  Widget build(BuildContext context) {
    final quote = quoteProvider.quote;
    final snapshot = weatherProvider.snapshot;

    if (quote == null && snapshot == null) {
      if (quoteProvider.isLoading || weatherProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Text("Tap for motivation and today's weather.");
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: quote != null
              ? Text(
                  '"${quote.text}" — ${quote.author}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : const Text('Quote unavailable'),
        ),
        if (snapshot != null) ...[
          const SizedBox(width: 12),
          Column(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 20),
              Text('${snapshot.current.temperature.round()}°C'),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;

  const _SectionCard({required this.title, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
