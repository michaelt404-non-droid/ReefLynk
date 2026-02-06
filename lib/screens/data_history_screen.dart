import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/theme/app_theme.dart';
import 'package:intl/intl.dart';

class DataHistoryScreen extends StatelessWidget {
  final String parameterName;
  final String sensorType;
  final String unit;

  const DataHistoryScreen({
    super.key,
    required this.parameterName,
    required this.sensorType,
    this.unit = '',
  });

  Future<void> _deleteEntry(BuildContext context, int readingId) async {
    try {
      await context.read<DatabaseService>().deleteParameterEntry(readingId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting entry: $e')),
      );
    }
  }

  Future<void> _updateEntry(
      BuildContext context, int readingId, String newValue) async {
    try {
      final double parsedValue = double.parse(newValue);
      await context.read<DatabaseService>().updateParameterEntry(readingId, parsedValue);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry updated successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating entry: $e')),
      );
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, SensorReading reading) async {
    final TextEditingController controller =
        TextEditingController(text: reading.value.toString());
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Entry'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'New Value ($unit)'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final newValue = controller.text;
                Navigator.of(context).pop();
                _updateEntry(context, reading.id, newValue);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('$parameterName History'),
      ),
      body: StreamBuilder<List<SensorReading>>(
        stream: db.getSensorStream(sensorType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available for $parameterName.'));
          }

          final readings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final reading = readings[index];
              final formattedTimestamp = DateFormat('MMM d, yyyy - hh:mm a').format(reading.timestamp.toLocal());

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Value: ${reading.value} $unit',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTimestamp,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: AppColors.mutedFg,
                          onPressed: () => _showEditDialog(context, reading),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: AppColors.destructive,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Entry'),
                                  content: const Text(
                                      'Are you sure you want to delete this entry?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    TextButton(
                                      child: const Text('Delete'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _deleteEntry(context, reading.id);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: Duration(milliseconds: (index * 50).clamp(0, 500)))
                    .slideX(begin: 0.05, end: 0),
              );
            },
          );
        },
      ),
    );
  }
}
