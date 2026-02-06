import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/providers/lighting_provider.dart';
import 'package:reeflynk/screens/light_control_screen.dart';
import 'package:reeflynk/theme/app_theme.dart';

class LightingScreen extends StatelessWidget {
  const LightingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LightingProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (int i = 0; i < LightingProvider.lights.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _LightStatusCard(
                  config: LightingProvider.lights[i],
                  state: provider.getLightState(LightingProvider.lights[i].id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LightControlScreen(
                          lightId: LightingProvider.lights[i].id,
                        ),
                      ),
                    );
                  },
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: (i * 100).ms)
                    .slideY(begin: 0.1, end: 0),
              ),
          ],
        );
      },
    );
  }
}

class _LightStatusCard extends StatelessWidget {
  final LightConfig config;
  final LightState state;
  final VoidCallback onTap;

  const _LightStatusCard({
    required this.config,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = state.isOnline;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: state.mode == 'off'
                        ? AppColors.mutedFg
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.name,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  _StatusChip(
                    label: isOnline ? 'Online' : 'Offline',
                    icon: isOnline ? Icons.wifi : Icons.wifi_off,
                    color: isOnline ? AppColors.success : AppColors.destructive,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: AppColors.mutedFg),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _StatusChip(
                    label: state.modeDisplay,
                    icon: _getModeIcon(state.mode),
                  ),
                  const SizedBox(width: 8),
                  if (state.ramping)
                    _StatusChip(
                      label: 'Ramping',
                      icon: Icons.trending_up,
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _ChannelBars(config: config, state: state),

              if (state.heatsinkTemp > 50)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.thermostat,
                        size: 16,
                        color: state.heatsinkTemp > 65
                            ? AppColors.destructive
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Heatsink: ${state.heatsinkTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 12,
                          color: state.heatsinkTemp > 65
                              ? AppColors.destructive
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'schedule':
        return Icons.schedule;
      case 'manual':
        return Icons.touch_app;
      case 'off':
        return Icons.power_settings_new;
      default:
        return Icons.help_outline;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _StatusChip({
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: chipColor),
          ),
        ],
      ),
    );
  }
}

class _ChannelBars extends StatelessWidget {
  final LightConfig config;
  final LightState state;

  const _ChannelBars({
    required this.config,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final channel in config.channels)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ChannelBar(
              name: channel.name,
              color: Color(channel.color),
              intensity: _getChannelIntensity(channel.id),
              masterBrightness: state.master,
            ),
          ),
      ],
    );
  }

  int _getChannelIntensity(String channelId) {
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

class _ChannelBar extends StatelessWidget {
  final String name;
  final Color color;
  final int intensity;
  final int masterBrightness;

  const _ChannelBar({
    required this.name,
    required this.color,
    required this.intensity,
    required this.masterBrightness,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIntensity = (intensity * masterBrightness / 100).round();

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedFg),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: effectiveIntensity / 100,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '$effectiveIntensity%',
            style: const TextStyle(fontSize: 12, color: AppColors.mutedFg),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
