import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/providers/lighting_provider.dart';
import 'package:reeflynk/screens/schedule_editor_screen.dart';

class LightControlScreen extends StatelessWidget {
  final String lightId;

  const LightControlScreen({super.key, required this.lightId});

  @override
  Widget build(BuildContext context) {
    return Consumer<LightingProvider>(
      builder: (context, provider, child) {
        final config = provider.getLightConfig(lightId);
        final state = provider.getLightState(lightId);

        if (config == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Light Control')),
            body: const Center(child: Text('Light not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(config.name),
            actions: [
              // Online status
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  state.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: state.isOnline ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Mode selector
              _ModeSelector(
                currentMode: state.mode,
                onModeChanged: (mode) => provider.setMode(lightId, mode),
              ),
              const SizedBox(height: 24),

              // Master brightness
              _BrightnessSlider(
                label: 'Master Brightness',
                value: state.master,
                color: Colors.white,
                enabled: state.mode != 'off',
                onChanged: (value) => provider.setMasterBrightness(lightId, value),
              ),
              const SizedBox(height: 24),

              // Channel sliders
              Text(
                'Channels',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              for (final channel in config.channels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ChannelSlider(
                    channel: channel,
                    value: _getChannelValue(state, channel.id),
                    enabled: state.mode == 'manual',
                    onChanged: (value) => provider.setChannel(lightId, channel.id, value),
                  ),
                ),

              const Divider(height: 32),

              // Schedule section
              _ScheduleSection(
                lightId: lightId,
                state: state,
              ),

              const Divider(height: 32),

              // Status section
              _StatusSection(state: state),
            ],
          ),
        );
      },
    );
  }

  int _getChannelValue(LightState state, String channelId) {
    switch (channelId) {
      case 'red':
        return state.red;
      case 'blue':
        return state.blue;
      default:
        return 0;
    }
  }
}

class _ModeSelector extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const _ModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'off',
              label: Text('Off'),
              icon: Icon(Icons.power_settings_new),
            ),
            ButtonSegment(
              value: 'schedule',
              label: Text('Schedule'),
              icon: Icon(Icons.schedule),
            ),
            ButtonSegment(
              value: 'manual',
              label: Text('Manual'),
              icon: Icon(Icons.touch_app),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (selection) {
            onModeChanged(selection.first);
          },
        ),
      ],
    );
  }
}

class _BrightnessSlider extends StatefulWidget {
  final String label;
  final int value;
  final Color color;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _BrightnessSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<_BrightnessSlider> {
  late double _localValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value.toDouble();
  }

  @override
  void didUpdateWidget(_BrightnessSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.value != oldWidget.value) {
      _localValue = widget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label),
            Text(
              '${_localValue.round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.enabled ? widget.color : Colors.grey,
            inactiveTrackColor: widget.color.withOpacity(0.2),
            thumbColor: widget.enabled ? widget.color : Colors.grey,
          ),
          child: Slider(
            value: _localValue,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: widget.enabled
                ? (value) {
                    setState(() {
                      _localValue = value;
                    });
                  }
                : null,
            onChangeStart: (_) {
              _isDragging = true;
            },
            onChangeEnd: (value) {
              _isDragging = false;
              widget.onChanged(value.round());
            },
          ),
        ),
      ],
    );
  }
}

class _ChannelSlider extends StatefulWidget {
  final ChannelConfig channel;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _ChannelSlider({
    required this.channel,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_ChannelSlider> createState() => _ChannelSliderState();
}

class _ChannelSliderState extends State<_ChannelSlider> {
  late double _localValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value.toDouble();
  }

  @override
  void didUpdateWidget(_ChannelSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && widget.value != oldWidget.value) {
      _localValue = widget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.channel.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.channel.name)),
            Text(
              '${_localValue.round()}%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: widget.enabled ? color : Colors.grey,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: widget.enabled ? color : Colors.grey,
          ),
          child: Slider(
            value: _localValue,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: widget.enabled
                ? (value) {
                    setState(() {
                      _localValue = value;
                    });
                  }
                : null,
            onChangeStart: (_) {
              _isDragging = true;
            },
            onChangeEnd: (value) {
              _isDragging = false;
              widget.onChanged(value.round());
            },
          ),
        ),
        if (!widget.enabled)
          Text(
            'Switch to Manual mode to adjust channels',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final String lightId;
  final LightState state;

  const _ScheduleSection({
    required this.lightId,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = state.schedule;
    final hasSchedule = schedule.isNotEmpty;

    String scheduleText = 'Not configured';
    if (hasSchedule) {
      final onHour = schedule['onHour'] ?? 20;
      final onMin = schedule['onMinute'] ?? 0;
      final offHour = schedule['offHour'] ?? 8;
      final offMin = schedule['offMinute'] ?? 0;
      scheduleText = 'ON ${_formatTime(onHour, onMin)} - OFF ${_formatTime(offHour, offMin)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleEditorScreen(lightId: lightId),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scheduleText),
                    if (hasSchedule && schedule['rampMinutes'] != null)
                      Text(
                        'Ramp: ${schedule['rampMinutes']} min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
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
}

class _StatusSection extends StatelessWidget {
  final LightState state;

  const _StatusSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _StatusRow(
          icon: Icons.thermostat,
          label: 'Heatsink Temperature',
          value: '${state.heatsinkTemp.toStringAsFixed(1)}°C',
          warning: state.heatsinkTemp > 50,
          critical: state.heatsinkTemp > 65,
        ),
        const SizedBox(height: 8),
        _StatusRow(
          icon: Icons.wifi,
          label: 'Connection',
          value: state.isOnline ? 'Online' : 'Offline',
          warning: !state.isOnline,
        ),
        if (state.ramping) ...[
          const SizedBox(height: 8),
          _StatusRow(
            icon: Icons.trending_up,
            label: 'Status',
            value: 'Ramping...',
          ),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool warning;
  final bool critical;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.warning = false,
    this.critical = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (critical) {
      color = Colors.red;
    } else if (warning) {
      color = Colors.orange;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
