import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/models/maintenance_task.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/services/maintenance_scheduler.dart';
import 'package:reeflynk/services/notification_service.dart';
import 'package:reeflynk/theme/app_theme.dart';

class MaintenanceTaskFormScreen extends StatefulWidget {
  final MaintenanceTask? existingTask;

  const MaintenanceTaskFormScreen({super.key, this.existingTask});

  @override
  State<MaintenanceTaskFormScreen> createState() => _MaintenanceTaskFormScreenState();
}

class _MaintenanceTaskFormScreenState extends State<MaintenanceTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _taskType;
  late String _frequency;
  int? _preferredDay;
  TimeOfDay _preferredTime = const TimeOfDay(hour: 9, minute: 0);
  int _remindBeforeHours = 1;
  bool _isLoading = false;

  bool get _isEditing => widget.existingTask != null;

  static const _dayNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  static const _remindOptions = [1, 2, 4, 12, 24];

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _nameController = TextEditingController(text: task?.name ?? '');
    _taskType = task?.taskType ?? 'water_change';
    _frequency = task?.frequency ?? 'weekly';
    _preferredDay = task?.preferredDay;
    if (task != null) {
      final parts = task.preferredTime.split(':');
      _preferredTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      _remindBeforeHours = task.remindBeforeHours;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _showDayPicker => _frequency == 'weekly' || _frequency == 'biweekly';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final timeStr =
        '${_preferredTime.hour.toString().padLeft(2, '0')}:${_preferredTime.minute.toString().padLeft(2, '0')}';

    final task = MaintenanceTask(
      name: _nameController.text.trim(),
      taskType: _taskType,
      frequency: _frequency,
      preferredDay: _showDayPicker ? _preferredDay : null,
      preferredTime: timeStr,
      remindBeforeHours: _remindBeforeHours,
    );

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      if (_isEditing) {
        await db.updateMaintenanceTask(widget.existingTask!.id!, task);
        // Cancel old notification and schedule new one
        await NotificationService().cancelReminder(widget.existingTask!.id!);
      } else {
        await db.createMaintenanceTask(task);
      }

      // Schedule notification for the new/updated task
      // For new tasks, we need to get it from the stream to get the ID
      // For simplicity, we'll reschedule all on next app open
      // But we can still schedule for edited tasks
      if (_isEditing) {
        final completions = await db.getLatestCompletions();
        final lastCompletion = completions[widget.existingTask!.id];
        final updatedTask = task.copyWith(id: widget.existingTask!.id);
        final reminderTime = MaintenanceScheduler.getReminderTime(updatedTask, lastCompletion);
        await NotificationService().scheduleMaintenanceReminder(
          taskId: widget.existingTask!.id!,
          taskName: task.name,
          scheduledDate: reminderTime,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Task updated' : 'Task created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = Provider.of<DatabaseService>(context, listen: false);
    await db.deleteMaintenanceTask(widget.existingTask!.id!);
    await NotificationService().cancelReminder(widget.existingTask!.id!);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.destructive),
              onPressed: _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task Details', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Task Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Task Type
                      DropdownButtonFormField<String>(
                        initialValue: _taskType,
                        decoration: const InputDecoration(labelText: 'Task Type'),
                        items: MaintenanceTask.taskTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(MaintenanceTask.taskTypeLabel(t)),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _taskType = v!),
                      ),
                      const SizedBox(height: 16),

                      // Frequency
                      Text('Frequency', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: MaintenanceTask.frequencies.map((f) {
                          return ButtonSegment(value: f, label: Text(MaintenanceTask.frequencyLabel(f)));
                        }).toList(),
                        selected: {_frequency},
                        onSelectionChanged: (v) => setState(() {
                          _frequency = v.first;
                          if (!_showDayPicker) _preferredDay = null;
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Preferred Day (conditional)
                      if (_showDayPicker) ...[
                        DropdownButtonFormField<int>(
                          initialValue: _preferredDay,
                          decoration: const InputDecoration(labelText: 'Preferred Day'),
                          items: _dayNames.entries.map((e) {
                            return DropdownMenuItem(value: e.key, child: Text(e.value));
                          }).toList(),
                          onChanged: (v) => setState(() => _preferredDay = v),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Preferred Time
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Preferred Time'),
                        trailing: Text(
                          _preferredTime.format(context),
                          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.primary),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _preferredTime,
                          );
                          if (picked != null) setState(() => _preferredTime = picked);
                        },
                      ),
                      const SizedBox(height: 8),

                      // Remind Before
                      DropdownButtonFormField<int>(
                        initialValue: _remindBeforeHours,
                        decoration: const InputDecoration(labelText: 'Remind Before'),
                        items: _remindOptions.map((h) {
                          return DropdownMenuItem(
                            value: h,
                            child: Text(h == 1 ? '1 hour' : '$h hours'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _remindBeforeHours = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'Update Task' : 'Create Task'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
