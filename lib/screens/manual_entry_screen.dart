import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/theme/app_theme.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _controllers;
  var _isLoading = false;

  final Map<String, String> _sensorLabels = {
    'temperature': 'Temperature (\u00b0F)',
    'ph': 'pH',
    'alkalinity': 'Alkalinity (dKH)',
    'calcium': 'Calcium (ppm)',
    'magnesium': 'Magnesium (ppm)',
    'orp': 'ORP (mV)',
    'ammonia': 'Ammonia (ppm)',
    'nitrate': 'Nitrate (ppm)',
    'nitrite': 'Nitrite (ppm)',
    'phosphate': 'Phosphate (ppm)',
  };

  final Map<String, String> _sensorHints = {
    'temperature': 'Optimal: 76\u201378\u00b0F',
    'ph': 'Optimal: 8.1\u20138.4',
    'alkalinity': 'Optimal: 8\u201312 dKH',
    'calcium': 'Optimal: 380\u2013450 ppm',
    'magnesium': 'Optimal: 1250\u20131350 ppm',
    'orp': 'Optimal: 300\u2013450 mV',
    'ammonia': 'Optimal: 0 ppm',
    'nitrate': 'Optimal: 1\u201310 ppm',
    'nitrite': 'Optimal: 0 ppm',
    'phosphate': 'Optimal: 0.03\u20130.1 ppm',
  };

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var sensorName in _sensorLabels.keys)
        sensorName: TextEditingController()
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveData() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final Map<String, double> sensorData = {};
      _controllers.forEach((sensorName, controller) {
        if (controller.text.isNotEmpty) {
          sensorData[sensorName] = double.parse(controller.text);
        }
      });

      if (sensorData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one value.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        await context.read<DatabaseService>().saveSensorData(sensorData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data saved successfully!')),
        );
        _formKey.currentState!.reset();
        for (var controller in _controllers.values) {
          controller.clear();
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Manual Data Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Readings',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._sensorLabels.keys.map((sensorName) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _controllers[sensorName]!,
                            decoration: InputDecoration(
                              labelText: _sensorLabels[sensorName]!,
                              helperText: _sensorHints[sensorName],
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _saveData,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Data'),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
