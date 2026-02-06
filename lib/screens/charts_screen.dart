import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:reeflynk/screens/data_history_screen.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:reeflynk/theme/app_theme.dart';

enum TimeRange { day, week, month, year, all }

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

class _ChartsView extends StatefulWidget {
  const _ChartsView();

  @override
  State<_ChartsView> createState() => _ChartsViewState();
}

class _ChartsViewState extends State<_ChartsView> {
  TimeRange _selectedRange = TimeRange.month;

  Duration? _getDuration(TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return const Duration(hours: 24);
      case TimeRange.week:
        return const Duration(days: 7);
      case TimeRange.month:
        return const Duration(days: 30);
      case TimeRange.year:
        return const Duration(days: 365);
      case TimeRange.all:
        return null;
    }
  }

  String _getRangeLabel(TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return '24h';
      case TimeRange.week:
        return '7d';
      case TimeRange.month:
        return '30d';
      case TimeRange.year:
        return '1y';
      case TimeRange.all:
        return 'All';
    }
  }

  String _formatAxisLabel(DateTime date, TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return DateFormat('HH:mm').format(date);
      case TimeRange.week:
        return DateFormat('E').format(date);
      case TimeRange.month:
        return DateFormat('M/d').format(date);
      case TimeRange.year:
        return DateFormat('MMM').format(date);
      case TimeRange.all:
        return DateFormat("MMM ''yy").format(date);
    }
  }

  String _formatTooltipDate(DateTime date) {
    return DateFormat('MMM d, y  HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
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
            Tab(icon: Icon(Icons.opacity), text: 'Alk.'),
            Tab(icon: Icon(Icons.local_drink), text: 'Calc.'),
            Tab(icon: Icon(Icons.whatshot), text: 'Mag.'),
            Tab(icon: Icon(Icons.bolt), text: 'ORP'),
            Tab(icon: Icon(Icons.warning), text: 'Amm.'),
            Tab(icon: Icon(Icons.filter_alt), text: 'Nitrate'),
            Tab(icon: Icon(Icons.flare), text: 'Nitrite'),
            Tab(icon: Icon(Icons.grain), text: 'Phosphate'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: TimeRange.values.map((range) {
                final isSelected = range == _selectedRange;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_getRangeLabel(range)),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedRange = range),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildChart(context, 'temperature', '\u00b0F',
                    [const Color(0xFFE5534B), const Color(0xFFE8A317)],
                    minY: 70, maxY: 90, intervalY: 5),
                _buildChart(context, 'ph', 'pH',
                    [const Color(0xFF7C6AED), const Color(0xFF3FB950)],
                    minY: 7.5, maxY: 8.5, intervalY: 0.1),
                _buildChart(context, 'alkalinity', 'dKH',
                    [const Color(0xFF9B59B6), const Color(0xFFE91E8C)],
                    minY: 5, maxY: 12, intervalY: 1),
                _buildChart(context, 'calcium', 'ppm',
                    [const Color(0xFFE8A317), const Color(0xFFF1C40F)],
                    minY: 350, maxY: 500, intervalY: 25),
                _buildChart(context, 'magnesium', 'ppm',
                    [const Color(0xFF1ABC9C), const Color(0xFF3FB950)],
                    minY: 1200, maxY: 1500, intervalY: 50),
                _buildChart(context, 'orp', 'mV',
                    [const Color(0xFF3FB950), const Color(0xFF7C6AED)],
                    minY: 200, maxY: 450, intervalY: 50),
                _buildChart(context, 'ammonia', 'ppm',
                    [const Color(0xFFE8A317), const Color(0xFFE5534B)],
                    minY: 0, maxY: 2, intervalY: 0.1),
                _buildChart(context, 'nitrate', 'ppm',
                    [const Color(0xFF7C6AED), const Color(0xFF3498DB)],
                    minY: 0, maxY: 50, intervalY: 5),
                _buildChart(context, 'nitrite', 'ppm',
                    [const Color(0xFFE91E8C), const Color(0xFF9B59B6)],
                    minY: 0, maxY: 1, intervalY: 0.1),
                _buildChart(context, 'phosphate', 'ppm',
                    [const Color(0xFF3498DB), const Color(0xFF7C6AED)],
                    minY: 0,
                    maxY: 1.5,
                    intervalY: 0.1,
                    autoScale: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<SensorReading>> _getStreamForSensor(
      DatabaseService db, String sensorName, {Duration? duration}) {
    switch (sensorName) {
      case 'temperature':
        return db.getTemperatureStream(duration: duration);
      case 'ph':
        return db.getPhStream(duration: duration);
      case 'alkalinity':
        return db.getAlkalinityStream(duration: duration);
      case 'calcium':
        return db.getCalciumStream(duration: duration);
      case 'magnesium':
        return db.getMagnesiumStream(duration: duration);
      case 'orp':
        return db.getOrpStream(duration: duration);
      case 'ammonia':
        return db.getAmmoniaStream(duration: duration);
      case 'nitrate':
        return db.getNitrateStream(duration: duration);
      case 'nitrite':
        return db.getNitriteStream(duration: duration);
      case 'phosphate':
        return db.getPhosphateStream(duration: duration);
      default:
        return Stream.value([]);
    }
  }

  Widget _buildChart(BuildContext context, String sensorName, String yAxisTitle,
      List<Color> gradientColors,
      {double? minY,
      double? maxY,
      double? intervalY,
      bool autoScale = false}) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final stream = _getStreamForSensor(db, sensorName, duration: _getDuration(_selectedRange));
    final borderColor = Colors.white.withOpacity(0.10);

    return StreamBuilder<List<SensorReading>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Data arrives newest-first; reverse to ascending for chart
        final readings = snapshot.data!.reversed.toList();

        if (readings.isEmpty) {
          return Center(
            child: Text(
                'No $yAxisTitle data in the last ${_getRangeLabel(_selectedRange)}.'),
          );
        }

        // Use timestamps for x-axis, normalized to keep values small
        final baseMs =
            readings.first.timestamp.millisecondsSinceEpoch.toDouble();
        final spots = readings.map((r) {
          return FlSpot(
            r.timestamp.millisecondsSinceEpoch.toDouble() - baseMs,
            r.value,
          );
        }).toList();

        // Aim for ~5 labels on the x-axis
        final timeSpanMs = spots.last.x - spots.first.x;
        final bottomInterval = timeSpanMs > 0 ? timeSpanMs / 5 : 1.0;

        // Y-axis auto-scaling
        double highestValueInData =
            readings.map((r) => r.value).reduce((a, b) => a > b ? a : b);

        double effectiveMaxY = maxY ?? 100;
        double effectiveIntervalY = intervalY ?? 10;

        if (autoScale) {
          if (highestValueInData <= 0.10) {
            effectiveMaxY = 0.12;
            effectiveIntervalY = 0.01;
          } else {
            effectiveMaxY = maxY ?? 1.5;
            effectiveIntervalY = intervalY ?? 0.1;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: borderColor,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: borderColor,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: bottomInterval,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            (value + baseMs).toInt(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatAxisLabel(date, _selectedRange),
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.mutedFg),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: effectiveIntervalY,
                        getTitlesWidget: (value, meta) {
                          if (effectiveIntervalY < 0.1) {
                            return Text(value.toStringAsFixed(2),
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.mutedFg));
                          }
                          return Text(
                            value % 1 == 0
                                ? value.toInt().toString()
                                : value.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.mutedFg),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: minY,
                  maxY: effectiveMaxY,
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: borderColor),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            (spot.x + baseMs).toInt(),
                          );
                          return LineTooltipItem(
                            '${_formatTooltipDate(date)}\n${spot.y.toStringAsFixed(2)} $yAxisTitle',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(colors: gradientColors),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: readings.length <= 30),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            colors: gradientColors
                                .map((color) => color.withAlpha(50))
                                .toList()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),
        );
      },
    );
  }

  void _navigateToHistoryScreen(BuildContext context) {
    final int tabIndex = DefaultTabController.of(context).index;
    String parameterName;
    String sensorType;
    String unit;

    switch (tabIndex) {
      case 0:
        parameterName = 'Temperature';
        sensorType = 'temperature';
        unit = '\u00b0F';
        break;
      case 1:
        parameterName = 'pH';
        sensorType = 'ph';
        unit = 'pH';
        break;
      case 2:
        parameterName = 'Alkalinity';
        sensorType = 'alkalinity';
        unit = 'dKH';
        break;
      case 3:
        parameterName = 'Calcium';
        sensorType = 'calcium';
        unit = 'ppm';
        break;
      case 4:
        parameterName = 'Magnesium';
        sensorType = 'magnesium';
        unit = 'ppm';
        break;
      case 5:
        parameterName = 'ORP';
        sensorType = 'orp';
        unit = 'mV';
        break;
      case 6:
        parameterName = 'Ammonia';
        sensorType = 'ammonia';
        unit = 'ppm';
        break;
      case 7:
        parameterName = 'Nitrate';
        sensorType = 'nitrate';
        unit = 'ppm';
        break;
      case 8:
        parameterName = 'Nitrite';
        sensorType = 'nitrite';
        unit = 'ppm';
        break;
      case 9:
        parameterName = 'Phosphate';
        sensorType = 'phosphate';
        unit = 'ppm';
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataHistoryScreen(
          parameterName: parameterName,
          sensorType: sensorType,
          unit: unit,
        ),
      ),
    );
  }

  Future<void> _exportChartDataToCsv(BuildContext context) async {
    final int tabIndex = DefaultTabController.of(context).index;
    String sensorType;
    String yAxisUnit;

    switch (tabIndex) {
      case 0:
        sensorType = 'temperature';
        yAxisUnit = '\u00b0F';
        break;
      case 1:
        sensorType = 'ph';
        yAxisUnit = 'pH';
        break;
      case 2:
        sensorType = 'alkalinity';
        yAxisUnit = 'dKH';
        break;
      case 3:
        sensorType = 'calcium';
        yAxisUnit = 'ppm';
        break;
      case 4:
        sensorType = 'magnesium';
        yAxisUnit = 'ppm';
        break;
      case 5:
        sensorType = 'orp';
        yAxisUnit = 'mV';
        break;
      case 6:
        sensorType = 'ammonia';
        yAxisUnit = 'ppm';
        break;
      case 7:
        sensorType = 'nitrate';
        yAxisUnit = 'ppm';
        break;
      case 8:
        sensorType = 'nitrite';
        yAxisUnit = 'ppm';
        break;
      case 9:
        sensorType = 'phosphate';
        yAxisUnit = 'ppm';
        break;
      default:
        return;
    }

    final db = context.read<DatabaseService>();
    final readings = await _getStreamForSensor(db, sensorType).first;

    if (readings.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $sensorType data to export.')),
      );
      return;
    }

    final StringBuffer csvBuffer = StringBuffer();
    csvBuffer.writeln('Timestamp,$yAxisUnit');

    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final reading in readings) {
      final formattedTimestamp = formatter.format(reading.timestamp);
      csvBuffer.writeln('$formattedTimestamp,${reading.value}');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$sensorType-data.csv';
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString());

      if (!context.mounted) return;
      await Share.shareXFiles([XFile(filePath)],
          text: 'ReefLynk Data Export');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }
}
