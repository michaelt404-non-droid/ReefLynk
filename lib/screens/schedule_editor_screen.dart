import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/providers/lighting_provider.dart';
import 'package:reeflynk/theme/app_theme.dart';

class ScheduleEditorScreen extends StatefulWidget {
  final String lightId;

  const ScheduleEditorScreen({super.key, required this.lightId});

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  late int _onHour;
  late int _onMinute;
  late int _offHour;
  late int _offMinute;
  late int _rampMinutes;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LightingProvider>(
      builder: (context, provider, child) {
        final config = provider.getLightConfig(widget.lightId);
        final state = provider.getLightState(widget.lightId);

        if (!_initialized) {
          final schedule = state.schedule;
          _onHour = (schedule['onHour'] as num?)?.toInt() ?? 20;
          _onMinute = (schedule['onMinute'] as num?)?.toInt() ?? 0;
          _offHour = (schedule['offHour'] as num?)?.toInt() ?? 8;
          _offMinute = (schedule['offMinute'] as num?)?.toInt() ?? 0;
          _rampMinutes = (schedule['rampMinutes'] as num?)?.toInt() ?? 60;
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${config?.name ?? 'Light'} Schedule'),
            actions: [
              TextButton(
                onPressed: () => _saveSchedule(context, provider),
                child: const Text('Save'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _TimePicker(
                label: 'Light On Time',
                icon: Icons.wb_sunny,
                hour: _onHour,
                minute: _onMinute,
                onChanged: (hour, minute) {
                  setState(() {
                    _onHour = hour;
                    _onMinute = minute;
                  });
                },
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              _TimePicker(
                label: 'Light Off Time',
                icon: Icons.nightlight,
                hour: _offHour,
                minute: _offMinute,
                onChanged: (hour, minute) {
                  setState(() {
                    _offHour = hour;
                    _offMinute = minute;
                  });
                },
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sunrise/Sunset Ramp Duration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How long to fade the lights on/off',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _rampMinutes.toDouble(),
                              min: 0,
                              max: 120,
                              divisions: 24,
                              label: '$_rampMinutes min',
                              onChanged: (value) {
                                setState(() {
                                  _rampMinutes = value.round();
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '$_rampMinutes min',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              _SchedulePreview(
                onHour: _onHour,
                onMinute: _onMinute,
                offHour: _offHour,
                offMinute: _offMinute,
                rampMinutes: _rampMinutes,
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              if (widget.lightId == 'refugium')
                Card(
                  color: AppColors.accent,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Refugium lights typically run opposite to display lights to help stabilize pH overnight.',
                            style: TextStyle(color: AppColors.foreground),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms),
            ],
          ),
        );
      },
    );
  }

  void _saveSchedule(BuildContext context, LightingProvider provider) async {
    try {
      await provider.setSchedule(
        widget.lightId,
        onHour: _onHour,
        onMinute: _onMinute,
        offHour: _offHour,
        offMinute: _offMinute,
        rampMinutes: _rampMinutes,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  const _TimePicker({
    required this.label,
    required this.icon,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _showTimePicker(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(hour, minute),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit, size: 20, color: AppColors.mutedFg),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked.hour, picked.minute);
    }
  }
}

class _SchedulePreview extends StatelessWidget {
  final int onHour;
  final int onMinute;
  final int offHour;
  final int offMinute;
  final int rampMinutes;

  const _SchedulePreview({
    required this.onHour,
    required this.onMinute,
    required this.offHour,
    required this.offMinute,
    required this.rampMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final rampUpStart = _subtractMinutes(onHour, onMinute, rampMinutes);
    final rampDownEnd = _addMinutes(offHour, offMinute, rampMinutes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _TimelineRow(
              time: _formatTime(rampUpStart.$1, rampUpStart.$2),
              label: 'Ramp up starts',
              icon: Icons.trending_up,
            ),
            _TimelineRow(
              time: _formatTime(onHour, onMinute),
              label: 'Full brightness',
              icon: Icons.wb_sunny,
            ),
            _TimelineRow(
              time: _formatTime(offHour, offMinute),
              label: 'Ramp down starts',
              icon: Icons.trending_down,
            ),
            _TimelineRow(
              time: _formatTime(rampDownEnd.$1, rampDownEnd.$2),
              label: 'Lights off',
              icon: Icons.nightlight,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  (int, int) _subtractMinutes(int hour, int minute, int mins) {
    int totalMins = hour * 60 + minute - mins;
    if (totalMins < 0) totalMins += 24 * 60;
    return (totalMins ~/ 60, totalMins % 60);
  }

  (int, int) _addMinutes(int hour, int minute, int mins) {
    int totalMins = hour * 60 + minute + mins;
    if (totalMins >= 24 * 60) totalMins -= 24 * 60;
    return (totalMins ~/ 60, totalMins % 60);
  }
}

class _TimelineRow extends StatelessWidget {
  final String time;
  final String label;
  final IconData icon;
  final bool isLast;

  const _TimelineRow({
    required this.time,
    required this.label,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: AppTheme.borderColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
