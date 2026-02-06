import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reeflynk/config/feature_flags.dart';
import 'package:reeflynk/screens/controls_screen.dart';
import 'package:reeflynk/screens/manual_entry_screen.dart';
import 'package:reeflynk/screens/settings_screen.dart';
import 'package:reeflynk/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Connection status card
        if (FeatureFlags.isControllerEnabled)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.wifi,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Controller: 192.168.1.100',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.1, end: 0),
        if (FeatureFlags.isControllerEnabled) const SizedBox(height: 16),

        // Actions card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ManualEntryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Enter Data Manually'),
                  ),
                ),
                if (FeatureFlags.isControllerEnabled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ControlsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.toggle_on),
                      label: const Text('Sensor Controls'),
                    ),
                  ),
                ],
                if (FeatureFlags.isControllerEnabled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Enter IP Manually'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 150.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
