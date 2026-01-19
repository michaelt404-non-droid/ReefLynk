import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reeflynk/providers/reef_controller_provider.dart';
import 'package:reeflynk/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final reefControllerProvider =
        Provider.of<ReefControllerProvider>(context, listen: false);
    _ipController.text = reefControllerProvider.manualIpAddress ?? '';
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // <--- FIX 1: Add Scaffold to provide Material context
      appBar: AppBar(
        title: const Text("Settings"), // Optional: Gives it a clean header
        automaticallyImplyLeading: false, // Prevents back button since it's a tab
      ),
      body: Consumer<ReefControllerProvider>(
        builder: (context, reefControllerProvider, child) {
          return SingleChildScrollView( // <--- FIX 2: Prevents overflow errors
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Controller Connection',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Connect Manually'),
                    value: reefControllerProvider.isManuallyConnected,
                    onChanged: (bool value) {
                      reefControllerProvider.setManuallyConnected(value);
                      if (!value) {
                        // If turning off manual connection, clear the IP
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
                      border: OutlineInputBorder(),
                      hintText: 'e.g., 192.168.1.100',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
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
                  const SizedBox(height: 24),
                  const Text(
                    'Current Connection Status:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Connected: ${reefControllerProvider.isConnected ? 'Yes' : 'No'}'),
                  Text(
                      'Using Manual IP: ${reefControllerProvider.isManuallyConnected ? 'Yes' : 'No'}'),
                  Text(
                      'Active IP Address: ${reefControllerProvider.activeIpAddress ?? 'N/A'}'),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Account',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Consumer<User?>(
                    builder: (context, user, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Signed in as: ${user?.email ?? 'Unknown'}'),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
