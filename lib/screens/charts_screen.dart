import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:reeflynk/screens/data_history_screen.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:path_provider/path_provider.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<User?>(
      builder: (context, user, child) {
        if (user == null) {
          return const Center(
            child: Text('Please sign in to view charts.'),
          );
        }
        return const DefaultTabController(
          length: 10,
          child: _ChartsView(),
        );
      },
    );
  }
}

class _ChartsView extends StatelessWidget {
  const _ChartsView();

  @override
  Widget build(BuildContext context) {
    // Scaffold removed here to prevent double-scaffold issues, 
    // but kept the Tab structure clean.
    return Scaffold( 
      appBar: AppBar(
        title: const Text('Sensor Charts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _navigateToHistoryScreen(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportChartDataToCsv(context),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.thermostat), text: 'Temp'),
            Tab(icon: Icon(Icons.science_outlined), text: 'pH'),
            Tab(icon: Icon(Icons.opacity), text: 'Alk'),
            Tab(icon: Icon(Icons.local_drink), text: 'Ca'),
            Tab(icon: Icon(Icons.whatshot), text: 'Mg'),
            Tab(icon: Icon(Icons.bolt), text: 'ORP'),
            Tab(icon: Icon(Icons.warning), text: 'Amm'),
            Tab(icon: Icon(Icons.filter_alt), text: 'Nitrate'),
            Tab(icon: Icon(Icons.flare), text: 'Nitrite'),
            Tab(icon: Icon(Icons.grain), text: 'Phosphate'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildChart(context, 'temperature', '°F', [Colors.red, Colors.orange], minY: 70, maxY: 90, intervalY: 5),
          _buildChart(context, 'ph', 'pH', [Colors.blue, Colors.green], minY: 7.5, maxY: 8.5, intervalY: 0.1),
          _buildChart(context, 'alkalinity', 'dKH', [Colors.purple, Colors.pink], minY: 5, maxY: 12, intervalY: 1),
          _buildChart(context, 'calcium', 'ppm', [Colors.orange, Colors.yellow], minY: 350, maxY: 500, intervalY: 25),
          _buildChart(context, 'magnesium', 'ppm', [Colors.teal, Colors.cyan], minY: 1200, maxY: 1500, intervalY: 50),
          _buildChart(context, 'orp', 'mV', [Colors.greenAccent, Colors.lightGreenAccent], minY: 200, maxY: 450, intervalY: 50),
          _buildChart(context, 'ammonia', 'ppm', [Colors.brown, Colors.orangeAccent], minY: 0, maxY: 2, intervalY: 0.1),
          _buildChart(context, 'nitrate', 'ppm', [Colors.indigo, Colors.lightBlue], minY: 0, maxY: 50, intervalY: 5),
          _buildChart(context, 'nitrite', 'ppm', [Colors.pinkAccent, Colors.purpleAccent], minY: 0, maxY: 1, intervalY: 0.1),
          _buildChart(context, 'phosphate', 'ppm', [Colors.cyan, Colors.blue], minY: 0, maxY: 1.5, intervalY: 0.1, autoScale: true),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>> _getStreamForSensor(DatabaseService db, String sensorName) {
    switch (sensorName) {
      case 'temperature': return db.getTemperatureStream();
      case 'ph': return db.getPhStream();
      case 'alkalinity': return db.getAlkalinityStream();
      case 'calcium': return db.getCalciumStream();
      case 'magnesium': return db.getMagnesiumStream();
      case 'orp': return db.getOrpStream();
      case 'ammonia': return db.getAmmoniaStream();
      case 'nitrate': return db.getNitrateStream();
      case 'nitrite': return db.getNitriteStream();
      case 'phosphate': return db.getPhosphateStream();
      default: return Stream.value({});
    }
  }

  Widget _buildChart(BuildContext context, String sensorName, String yAxisTitle, List<Color> gradientColors, {double? minY, double? maxY, double? intervalY, bool autoScale = false}) {
    return Consumer<DatabaseService>(
      builder: (context, databaseService, child) {
        final stream = _getStreamForSensor(databaseService, sensorName);
        final cachedValue = databaseService.getCachedSensorValue(sensorName);

        return StreamBuilder<dynamic>(
          stream: stream,
          initialData: cachedValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            // Only show loading on initial connection when no cached data
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, dynamic> historyData = {};

            // 1. Safe Data Parsing
            if (snapshot.data is Map) {
              historyData = Map<String, dynamic>.from(snapshot.data as Map);
            } else if (snapshot.data is num) {
              historyData = {
                'current': {
                  'value': snapshot.data, 
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                }
              };
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No data available for $yAxisTitle.'));
            }

            if (historyData.isEmpty) {
              return Center(child: Text('No data available for $yAxisTitle.'));
            }

            double highestValueInData = 0.0;

            final List<Map<String, dynamic>> entries = historyData.entries.map((entry) {
              if (entry.value is Map && entry.value.containsKey('timestamp') && entry.value.containsKey('value')) {
                dynamic rawTime = entry.value['timestamp'];
                int timestamp = 0;
                if (rawTime is int) timestamp = rawTime;
                if (rawTime is double) timestamp = rawTime.toInt();

                // Time Normalization (Seconds -> Milliseconds)
                if (timestamp < 100000000000) { 
                  timestamp = timestamp * 1000;
                }

                double val = (entry.value['value'] as num).toDouble();
                
                // Track highest value for auto-scaling
                if (val > highestValueInData) highestValueInData = val;

                return {
                  'timestamp': timestamp,
                  'value': val,
                };
              }
              if (entry.value is num) {
                double val = (entry.value as num).toDouble();
                if (val > highestValueInData) highestValueInData = val;
                return {
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'value': val,
                };
              }
              return {};
            }).where((entry) => entry.isNotEmpty).map((e) => Map<String, dynamic>.from(e)).toList();

            // Sort by time
            entries.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

            final List<FlSpot> spots = [];
            for (int i = 0; i < entries.length; i++) {
              final entry = entries[i];
              spots.add(FlSpot(i.toDouble(), entry['value']));
            }

            if (spots.isEmpty) {
               return Center(child: Text('No valid data points for $yAxisTitle.'));
            }

            // --- SMART SCALING LOGIC ---
            double effectiveMaxY = maxY ?? 100;
            double effectiveIntervalY = intervalY ?? 10;

            if (autoScale) {
              // If the highest value is very low (e.g. 0.04), Zoom in!
              if (highestValueInData <= 0.10) {
                effectiveMaxY = 0.12;  // Set max just above 0.1
                effectiveIntervalY = 0.01; // Show detailed 0.01 steps
              } else {
                // Otherwise, keep the wide view, but use the provided defaults
                effectiveMaxY = maxY ?? 1.5;
                effectiveIntervalY = intervalY ?? 0.1;
              }
            }
            // ---------------------------

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: effectiveIntervalY, // Use the dynamic interval
                        getTitlesWidget: (value, meta) {
                          // Smart formatting: if interval is small (0.01), show 2 decimal places
                          if (effectiveIntervalY < 0.1) {
                             return Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 10, color: Colors.white));
                          }
                          // Otherwise show 1 decimal place (or 0 if whole number)
                          return Text(
                            value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1), 
                            style: const TextStyle(fontSize: 10, color: Colors.white)
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: minY,
                  maxY: effectiveMaxY, // Use the dynamic max
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(colors: gradientColors),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: gradientColors.map((color) => color.withAlpha(77)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToHistoryScreen(BuildContext context) {
    // ... (Your switch statement logic here is fine, omitted for brevity but you can keep it as it was) ...
    // Note: Since this navigation doesn't await anything, no async gap fix needed here.
    // For simplicity, re-paste your Switch statement logic here if needed, or I can paste the full block if you want.
    // Assuming standard switch case logic...
     final int tabIndex = DefaultTabController.of(context).index;
    String parameterName;
    Stream<Map<String, dynamic>>? dataStream;

    switch (tabIndex) {
      case 0: parameterName = 'Temperature'; dataStream = context.read<DatabaseService>().getTemperatureStream(); break;
      case 1: parameterName = 'pH'; dataStream = context.read<DatabaseService>().getPhStream(); break;
      case 2: parameterName = 'Alkalinity'; dataStream = context.read<DatabaseService>().getAlkalinityStream(); break;
      case 3: parameterName = 'Calcium'; dataStream = context.read<DatabaseService>().getCalciumStream(); break;
      case 4: parameterName = 'Magnesium'; dataStream = context.read<DatabaseService>().getMagnesiumStream(); break;
      case 5: parameterName = 'ORP'; dataStream = context.read<DatabaseService>().getOrpStream(); break;
      case 6: parameterName = 'Ammonia'; dataStream = context.read<DatabaseService>().getAmmoniaStream(); break;
      case 7: parameterName = 'Nitrate'; dataStream = context.read<DatabaseService>().getNitrateStream(); break;
      case 8: parameterName = 'Nitrite'; dataStream = context.read<DatabaseService>().getNitriteStream(); break;
      case 9: parameterName = 'Phosphate'; dataStream = context.read<DatabaseService>().getPhosphateStream(); break;
      default: return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataHistoryScreen(
          parameterName: parameterName,
          parameterType: parameterName.toLowerCase(),
          dataStream: dataStream!,
        ),
      ),
    );
  }

  Future<void> _exportChartDataToCsv(BuildContext context) async {
    final int tabIndex = DefaultTabController.of(context).index;
    // ... (Keep switch statement same as before) ...
    String sensorType;
    Stream<Map<String, dynamic>>? dataStream;
    String yAxisUnit;

    switch (tabIndex) {
      case 0: sensorType = 'temperature'; dataStream = context.read<DatabaseService>().getTemperatureStream(); yAxisUnit = '°F'; break;
      case 1: sensorType = 'ph'; dataStream = context.read<DatabaseService>().getPhStream(); yAxisUnit = 'pH'; break;
      case 2: sensorType = 'alkalinity'; dataStream = context.read<DatabaseService>().getAlkalinityStream(); yAxisUnit = 'dKH'; break;
      case 3: sensorType = 'calcium'; dataStream = context.read<DatabaseService>().getCalciumStream(); yAxisUnit = 'ppm'; break;
      case 4: sensorType = 'magnesium'; dataStream = context.read<DatabaseService>().getMagnesiumStream(); yAxisUnit = 'ppm'; break;
      case 5: sensorType = 'orp'; dataStream = context.read<DatabaseService>().getOrpStream(); yAxisUnit = 'mV'; break;
      case 6: sensorType = 'ammonia'; dataStream = context.read<DatabaseService>().getAmmoniaStream(); yAxisUnit = 'ppm'; break;
      case 7: sensorType = 'nitrate'; dataStream = context.read<DatabaseService>().getNitrateStream(); yAxisUnit = 'ppm'; break;
      case 8: sensorType = 'nitrite'; dataStream = context.read<DatabaseService>().getNitriteStream(); yAxisUnit = 'ppm'; break;
      case 9: sensorType = 'phosphate'; dataStream = context.read<DatabaseService>().getPhosphateStream(); yAxisUnit = 'ppm'; break;
      default: return;
    }

    final Map<String, dynamic>? data = await dataStream.first;

    if (data == null || data.isEmpty) {
      if (!context.mounted) return; // FIX: Async gap check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $sensorType data to export.')),
      );
      return;
    }

    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('Timestamp,$yAxisUnit');

    final sortedKeys = data.keys.toList()..sort();
    for (final key in sortedKeys) {
      final dataPoint = data[key];
      if (dataPoint is Map && dataPoint.containsKey('value')) {
        csvBuffer.writeln('$key,${dataPoint['value']}');
      } else if (dataPoint is num) {
        csvBuffer.writeln('$key,$dataPoint');
      }
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$sensorType-data.csv';
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString());

      // Check context before using it again, although Share doesn't strictly need context, 
      // the ScaffoldMessenger below DOES.
      if (!context.mounted) return; // FIX: Async gap check

      await Share.shareXFiles([XFile(filePath)], text: 'ReefLynk Data Export');

      if (!context.mounted) return; // FIX: Async gap check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV file prepared for sharing.')),
      );
    } catch (e) {
      if (!context.mounted) return; // FIX: Async gap check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }
}
