import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/habit_color_picker.dart';

class HabitsListScreen extends StatefulWidget {
  const HabitsListScreen({super.key});

  @override
  State<HabitsListScreen> createState() => _HabitsListScreenState();
}

class _HabitsListScreenState extends State<HabitsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HabitProvider>().loadHabits();
    });
  }

  Future<void> _showAddHabitDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final habitCount = context.read<HabitProvider>().habits.length;
    var selectedColor = habitColorPalette[habitCount % habitColorPalette.length];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Add Habit'),
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
                    await context.read<HabitProvider>().addHabit(
                          nameController.text,
                          color: selectedColor,
                        );
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      drawer: const AppDrawer(),
      body: habitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : habitProvider.habits.isEmpty
              ? const Center(child: Text('No habits yet — add one below.'))
              : ListView.builder(
                  itemCount: habitProvider.habits.length,
                  itemBuilder: (context, index) {
                    final habit = habitProvider.habits[index];
                    return _HabitTile(habit: habit);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;

  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final completedToday = habitProvider.isCompletedToday(habit);

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showConfirmDeleteDialog(
        context,
        title: 'Delete Habit',
        itemName: habit.name,
      ),
      onDismissed: (_) => habitProvider.deleteHabit(habit.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: habit.color, radius: 12),
        title: Text(habit.name),
        onTap: () => context.push('/habits/${habit.id}'),
        trailing: Checkbox(
          value: completedToday,
          onChanged: (_) => habitProvider.toggleTodayCompletion(habit),
        ),
      ),
    );
  }
}
