import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/services/database_service.dart';

class DataHistoryScreen extends StatelessWidget {
  final String parameterName;
  final String parameterType;
  final Stream<Map<String, dynamic>> dataStream;

  const DataHistoryScreen({
    super.key,
    required this.parameterName,
    required this.parameterType,
    required this.dataStream,
  });

  String _getparameterType(String parameterName) {
    return parameterName.toLowerCase();
  }

  Future<void> _deleteEntry(BuildContext context, String timestampKey) async {
    try {
      await context.read<DatabaseService>().deleteParameterEntry(
          _getparameterType(parameterName), timestampKey);
      
      // FIX: Check if screen is still valid
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
      BuildContext context, String timestampKey, String newValue) async {
    try {
      final double parsedValue = double.parse(newValue);
      await context.read<DatabaseService>().updateParameterEntry(
          _getparameterType(parameterName), timestampKey, parsedValue);
      
      // FIX: Check if screen is still valid
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
      BuildContext context, dynamic currentValue, String timestampKey) async {
    final TextEditingController controller =
        TextEditingController(text: currentValue.toString());
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Entry'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'New Value'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                // Save reference to values before popping
                final newValue = controller.text;
                Navigator.of(context).pop();
                // Call update after dialog closes
                _updateEntry(context, timestampKey, newValue);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$parameterName History'),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: dataStream,
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

          final Map<String, dynamic> historyData = snapshot.data!;
          final List<Map<String, dynamic>> entries = historyData.entries.map((entry) {
            if (entry.value is Map && entry.value.containsKey('timestamp') && entry.value.containsKey('value')) {
              return {
                'key': entry.key,
                'timestamp': entry.value['timestamp'],
                'value': entry.value['value'],
              };
            }
            return {}; 
          }).where((entry) => entry.isNotEmpty).map((e) => Map<String, dynamic>.from(e)).toList();

          entries.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final String timestampKey = entry['key'];
              final value = entry['value'];
              final timestamp = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);

              return ListTile(
                title: Text('Value: $value'),
                subtitle: Text('Timestamp: $timestamp'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditDialog(context, value, timestampKey);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
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
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close dialog first
                                    _deleteEntry(context, timestampKey); // Then delete
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
              );
            },
          );
        },
      ),
    );
  }
}