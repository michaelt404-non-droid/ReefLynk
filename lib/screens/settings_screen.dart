import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reeflynk/config/feature_flags.dart';
import 'package:reeflynk/providers/reef_controller_provider.dart';
import 'package:reeflynk/services/auth_service.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/services/notification_service.dart';
import 'package:reeflynk/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    if (FeatureFlags.isControllerEnabled) {
      final reefControllerProvider =
          Provider.of<ReefControllerProvider>(context, listen: false);
      _ipController.text = reefControllerProvider.manualIpAddress ?? '';
    }
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loadingPrefs = false);
      return;
    }
    final db = Provider.of<DatabaseService>(context, listen: false);
    final prefs = await db.getNotificationPreferences();
    if (mounted) {
      setState(() {
        if (prefs != null) {
          _pushNotificationsEnabled = prefs['push_enabled'] ?? true;
          _emailNotificationsEnabled = prefs['email_enabled'] ?? false;
          _emailController.text = prefs['email_address'] ?? user.email ?? '';
        } else {
          _emailController.text = user.email ?? '';
        }
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _saveEmailPreference(bool enabled) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final db = Provider.of<DatabaseService>(context, listen: false);
    await db.updateNotificationPreferences({
      'email_enabled': enabled,
      'email_address': _emailController.text.trim(),
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (FeatureFlags.isControllerEnabled)
              Consumer<ReefControllerProvider>(
                builder: (context, reefControllerProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Controller Connection Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Controller Connection',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Connect Manually'),
                                value: reefControllerProvider.isManuallyConnected,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (bool value) {
                                  reefControllerProvider.setManuallyConnected(value);
                                  if (!value) {
                                    _ipController.clear();
                                    reefControllerProvider.setManualIpAddress(null);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _ipController,
                                enabled: reefControllerProvider.isManuallyConnected,
                                decoration: const InputDecoration(
                                  labelText: 'Manual IP Address',
                                  hintText: 'e.g., 192.168.1.100',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: reefControllerProvider.isManuallyConnected
                                      ? () {
                                          final ipAddress = _ipController.text.trim();
                                          reefControllerProvider.setManualIpAddress(ipAddress);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text('Manual IP set to: $ipAddress')),
                                          );
                                        }
                                      : null,
                                  child: const Text('Save Manual IP'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),

                      // Connection Status Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connection Status',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _StatusInfoRow(
                                label: 'Connected',
                                value: reefControllerProvider.isConnected ? 'Yes' : 'No',
                                valueColor: reefControllerProvider.isConnected
                                    ? AppColors.success
                                    : AppColors.destructive,
                              ),
                              const SizedBox(height: 8),
                              _StatusInfoRow(
                                label: 'Using Manual IP',
                                value: reefControllerProvider.isManuallyConnected ? 'Yes' : 'No',
                              ),
                              const SizedBox(height: 8),
                              _StatusInfoRow(
                                label: 'Active IP Address',
                                value: reefControllerProvider.activeIpAddress ?? 'N/A',
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 100.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

            // Notifications Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Maintenance reminders'),
                      value: _pushNotificationsEnabled,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool value) async {
                        setState(() => _pushNotificationsEnabled = value);
                        if (value) {
                          await NotificationService().requestPermissions();
                        } else {
                          await NotificationService().cancelAllReminders();
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      subtitle: const Text('Maintenance reminders via email'),
                      value: _emailNotificationsEnabled,
                      contentPadding: EdgeInsets.zero,
                      onChanged: _loadingPrefs
                          ? null
                          : (bool value) async {
                              setState(() => _emailNotificationsEnabled = value);
                              await _saveEmailPreference(value);
                            },
                    ),
                    if (_emailNotificationsEnabled) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'your@email.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onFieldSubmitted: (_) => _saveEmailPreference(true),
                      ),
                    ],
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 150.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),

            // Account Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Consumer<User?>(
                  builder: (context, user, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Signed in as: ${user?.email ?? 'Unknown'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.mutedFg,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sign Out'),
                                content: const Text('Are you sure you want to sign out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await context.read<AuthService>().signOut();
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedFg),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
