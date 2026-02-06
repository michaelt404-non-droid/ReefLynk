import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/services/database_service.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  final List<String> _sensors = [
    'temperature',
    'ph',
    'alkalinity',
    'calcium',
    'magnesium',
    'orp',
    'ammonia',
    'nitrate',
    'nitrite',
    'phosphate',
  ];
  Map<String, String> _sensorModes = {};

  Future<void> _showBulkEditDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bulk Edit Sensor Modes'),
          content: const Text('Set all sensors to manual or automatic mode.'),
          actions: <Widget>[
            TextButton(
              child: const Text('All Manual'),
              onPressed: () {
                _bulkUpdateModes('manual');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('All Auto'),
              onPressed: () {
                _bulkUpdateModes('auto');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _bulkUpdateModes(String mode) async {
    try {
      await context.read<DatabaseService>().bulkUpdateSensorModes(mode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All sensors set to $mode mode.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating sensor modes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Modes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showBulkEditDialog,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, String>>(
        stream: context.read<DatabaseService>().getSensorModesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _sensorModes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            _sensorModes = snapshot.data!;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _sensors.length,
            itemBuilder: (context, index) {
              final sensorName = _sensors[index];
              final currentMode = _sensorModes[sensorName] ?? 'auto';
              final isManual = currentMode == 'manual';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sensorName[0].toUpperCase() + sensorName.substring(1),
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mode: $currentMode',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isManual,
                          onChanged: (bool value) {
                            final newMode = value ? 'manual' : 'auto';
                            setState(() {
                              _sensorModes[sensorName] = newMode;
                            });
                            context
                                .read<DatabaseService>()
                                .updateSensorMode(sensorName, newMode);
                          },
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                    .slideX(begin: 0.05, end: 0),
              );
            },
          );
        },
      ),
    );
  }
}
