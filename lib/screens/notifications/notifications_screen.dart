import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_settings.dart';
import '../../providers/habit_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_drawer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().loadSettings();
      context.read<HabitProvider>().loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final enabled = notificationProvider.settings.enabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      drawer: const AppDrawer(),
      body: notificationProvider.isLoading || habitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Get reminders for the habits you select below'),
                  value: enabled,
                  onChanged: (value) =>
                      notificationProvider.setEnabled(value, habitProvider.habits),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => notificationProvider.sendTestNotification(),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Send Test Notification'),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Reminder Times', style: Theme.of(context).textTheme.titleSmall),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: NotificationTime.values.map((time) {
                      final selected = notificationProvider.settings.times.contains(time);
                      return FilterChip(
                        label: Text(time.label),
                        selected: selected,
                        onSelected: enabled
                            ? (_) => notificationProvider.toggleTime(time, habitProvider.habits)
                            : null,
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Habits', style: Theme.of(context).textTheme.titleSmall),
                ),
                if (habitProvider.habits.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No habits yet — add one to enable reminders for it.'),
                  )
                else
                  ...habitProvider.habits.map((habit) {
                    final selected = notificationProvider.settings.habitIds.contains(habit.id);
                    return CheckboxListTile(
                      secondary: CircleAvatar(backgroundColor: habit.color, radius: 10),
                      title: Text(habit.name),
                      value: selected,
                      onChanged: enabled
                          ? (_) =>
                              notificationProvider.toggleHabit(habit.id, habitProvider.habits)
                          : null,
                    );
                  }),
              ],
            ),
    );
  }
}
