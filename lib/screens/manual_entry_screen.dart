import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/services/database_service.dart';

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
    'temperature': 'Temperature (°F)',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Data Entry'),
      ),
      body: StreamBuilder<Map<String, String>>(
        stream: context.read<DatabaseService>().getSensorModesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sensorModes = snapshot.data ?? {};
          final manualSensors = _sensorLabels.keys
              .where((sensorName) => sensorModes[sensorName] == 'manual')
              .toList();

          if (manualSensors.isEmpty) {
            return const Center(
              child: Text('No sensors are in "manual" mode. Go to the "Controls" screen to enable manual entry.'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  ...manualSensors.map((sensorName) {
                    return _buildTextFormField(
                      controller: _controllers[sensorName]!,
                      labelText: _sensorLabels[sensorName]!,
                    );
                  }),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _saveData,
                      child: const Text('Save Data'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
  }
}
