import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/models/maintenance_task.dart';
import 'package:reeflynk/models/maintenance_completion.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/services/maintenance_scheduler.dart';
import 'package:reeflynk/services/notification_service.dart';
import 'package:reeflynk/screens/maintenance_task_form_screen.dart';
import 'package:reeflynk/theme/app_theme.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
      ),
      body: StreamBuilder<List<MaintenanceTask>>(
        stream: db.getMaintenanceTasksStream(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.hasError) {
            return Center(child: Text('Error: ${taskSnapshot.error}'));
          }
          if (!taskSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = taskSnapshot.data!;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build_outlined, size: 64, color: AppColors.mutedFg),
                  const SizedBox(height: 16),
                  Text(
                    'No maintenance tasks yet',
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.mutedFg),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first task',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedFg),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<Map<int, MaintenanceCompletion>>(
            future: db.getLatestCompletions(),
            builder: (context, completionSnapshot) {
              final completions = completionSnapshot.data ?? {};

              final overdue = <MaintenanceTask>[];
              final upcoming = <MaintenanceTask>[];

              for (final task in tasks) {
                final lastCompletion = completions[task.id];
                if (MaintenanceScheduler.isOverdue(task, lastCompletion)) {
                  overdue.add(task);
                } else {
                  upcoming.add(task);
                }
              }

              // Sort by due date
              overdue.sort((a, b) {
                final aDue = MaintenanceScheduler.getNextDueDate(a, completions[a.id]);
                final bDue = MaintenanceScheduler.getNextDueDate(b, completions[b.id]);
                return aDue.compareTo(bDue);
              });
              upcoming.sort((a, b) {
                final aDue = MaintenanceScheduler.getNextDueDate(a, completions[a.id]);
                final bDue = MaintenanceScheduler.getNextDueDate(b, completions[b.id]);
                return aDue.compareTo(bDue);
              });

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (overdue.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'Overdue',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.destructive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...overdue.map((task) => _TaskCard(
                      task: task,
                      lastCompletion: completions[task.id],
                      isOverdue: true,
                    )),
                    const SizedBox(height: 16),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'Upcoming',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...upcoming.map((task) => _TaskCard(
                      task: task,
                      lastCompletion: completions[task.id],
                      isOverdue: false,
                    )),
                  ],
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MaintenanceTaskFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final MaintenanceTask task;
  final MaintenanceCompletion? lastCompletion;
  final bool isOverdue;

  const _TaskCard({
    required this.task,
    required this.lastCompletion,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextDue = MaintenanceScheduler.getNextDueDate(task, lastCompletion);
    final dateFormatter = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOverdue
              ? AppColors.destructive.withOpacity(0.5)
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaintenanceTaskFormScreen(existingTask: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _TypeChip(taskType: task.taskType),
                        const SizedBox(width: 8),
                        Text(
                          MaintenanceTask.frequencyLabel(task.frequency),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverdue
                          ? 'Overdue since ${dateFormatter.format(nextDue)}'
                          : 'Due ${dateFormatter.format(nextDue)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue ? AppColors.destructive : AppColors.mutedFg,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => _showCompleteDialog(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Complete'),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  void _showCompleteDialog(BuildContext context) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Complete "${task.name}"'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Any observations or details...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              await db.completeMaintenanceTask(
                task.id!,
                notesController.text.isEmpty ? null : notesController.text,
              );

              // Reschedule notification
              final completions = await db.getLatestCompletions();
              final newCompletion = completions[task.id];
              final reminderTime = MaintenanceScheduler.getReminderTime(task, newCompletion);
              await NotificationService().scheduleMaintenanceReminder(
                taskId: task.id!,
                taskName: task.name,
                scheduledDate: reminderTime,
              );

              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${task.name} completed!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String taskType;

  const _TypeChip({required this.taskType});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    switch (taskType) {
      case 'water_change':
        chipColor = const Color(0xFF3498DB);
        break;
      case 'cleaning':
        chipColor = AppColors.warning;
        break;
      case 'parameter_check':
        chipColor = AppColors.success;
        break;
      default:
        chipColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        MaintenanceTask.taskTypeLabel(taskType),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }
}
