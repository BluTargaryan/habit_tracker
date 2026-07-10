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
              title: 'To Do',
              child: habitProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _HabitStatusList(
                      habits: habitProvider.habits
                          .where((habit) => !habitProvider.isCompletedToday(habit))
                          .toList(),
                      habitProvider: habitProvider,
                      emptyText: habitProvider.habits.isEmpty
                          ? 'No habits yet — add one to start tracking your progress.'
                          : "You're all caught up for today!",
                    ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Completed',
              child: habitProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _HabitStatusList(
                      habits: habitProvider.habits.where(habitProvider.isCompletedToday).toList(),
                      habitProvider: habitProvider,
                      emptyText: 'No habits completed today.',
                    ),
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

class _HabitStatusList extends StatelessWidget {
  final List<Habit> habits;
  final HabitProvider habitProvider;
  final String emptyText;

  const _HabitStatusList({
    required this.habits,
    required this.habitProvider,
    required this.emptyText,
  });

  static const _cardWidth = 140.0;
  static const _listHeight = 116.0;

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return Text(emptyText);
    }

    return SizedBox(
      height: _listHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: habits.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final habit = habits[index];
          return Dismissible(
            key: ValueKey(habit.id),
            direction: DismissDirection.vertical,
            onDismissed: (_) => habitProvider.toggleTodayCompletion(habit),
            background: _swipeIndicator(context),
            secondaryBackground: _swipeIndicator(context),
            child: SizedBox(
              width: _cardWidth,
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/habits/${habit.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(backgroundColor: habit.color, radius: 14),
                        const SizedBox(height: 8),
                        Text(
                          habit.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.unfold_more, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _swipeIndicator(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.swap_vert),
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
