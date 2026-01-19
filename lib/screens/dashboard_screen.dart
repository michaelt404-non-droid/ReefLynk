import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/providers/reef_controller_provider.dart';
import 'package:reeflynk/screens/manual_entry_screen.dart';
import 'package:reeflynk/screens/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Consumer<ReefControllerProvider>(
        builder: (context, provider, child) {
          if (provider.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Connected to Controller: ${provider.activeIpAddress}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ManualEntryScreen(),
                        ),
                      );
                    },
                    child: const Text('Enter Data Manually'),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Controller not found.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Enter IP Manually'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ManualEntryScreen(),
                        ),
                      );
                    },
                    child: const Text('Enter Data Manually'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}