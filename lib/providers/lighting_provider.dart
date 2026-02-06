import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:reeflynk/services/database_service.dart';

/// Represents the current state of a light
class LightState {
  final String mode;
  final int red;
  final int blue;
  final int master;
  final double heatsinkTemp;
  final bool ramping;
  final int lastUpdate;
  final Map<String, dynamic> schedule;

  LightState({
    this.mode = 'off',
    this.red = 0,
    this.blue = 0,
    this.master = 100,
    this.heatsinkTemp = 0.0,
    this.ramping = false,
    this.lastUpdate = 0,
    this.schedule = const {},
  });

  factory LightState.fromStatus(Map<String, dynamic> status) {
    return LightState(
      mode: status['mode'] as String? ?? 'off',
      red: (status['red'] as num?)?.toInt() ?? 0,
      blue: (status['blue'] as num?)?.toInt() ?? 0,
      master: (status['master'] as num?)?.toInt() ?? 100,
      heatsinkTemp: (status['heatsinkTemp'] as num?)?.toDouble() ?? 0.0,
      ramping: status['ramping'] as bool? ?? false,
      lastUpdate: (status['lastUpdate'] as num?)?.toInt() ?? 0,
    );
  }

  LightState copyWithState(Map<String, dynamic> state) {
    return LightState(
      mode: state['mode'] as String? ?? mode,
      red: (state['red'] as num?)?.toInt() ?? red,
      blue: (state['blue'] as num?)?.toInt() ?? blue,
      master: (state['master'] as num?)?.toInt() ?? master,
      heatsinkTemp: heatsinkTemp,
      ramping: ramping,
      lastUpdate: lastUpdate,
      schedule: state['schedule'] as Map<String, dynamic>? ?? schedule,
    );
  }

  bool get isOnline {
    if (lastUpdate == 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now - lastUpdate) < 120; // Consider online if updated in last 2 minutes
  }

  String get modeDisplay {
    switch (mode) {
      case 'schedule':
        return 'Schedule';
      case 'manual':
        return 'Manual';
      case 'off':
        return 'Off';
      default:
        return mode;
    }
  }
}

/// Light configuration (display name, channels, etc.)
class LightConfig {
  final String id;
  final String name;
  final List<ChannelConfig> channels;

  const LightConfig({
    required this.id,
    required this.name,
    required this.channels,
  });
}

class ChannelConfig {
  final String id;
  final String name;
  final int color;

  const ChannelConfig({
    required this.id,
    required this.name,
    required this.color,
  });
}

class LightingProvider extends ChangeNotifier {
  DatabaseService? _databaseService;
  final Map<String, LightState> _lightStates = {};
  final Map<String, StreamSubscription> _statusSubscriptions = {};
  final Map<String, StreamSubscription> _stateSubscriptions = {};

  // Define available lights
  static const List<LightConfig> lights = [
    LightConfig(
      id: 'refugium',
      name: 'Refugium',
      channels: [
        ChannelConfig(id: 'red', name: 'Red', color: 0xFFFF0000),
        ChannelConfig(id: 'blue', name: 'Blue', color: 0xFF0066FF),
      ],
    ),
    // Display tank light can be added later
    // LightConfig(
    //   id: 'display',
    //   name: 'Display Tank',
    //   channels: [
    //     ChannelConfig(id: 'royalBlue', name: 'Royal Blue', color: 0xFF0033CC),
    //     ChannelConfig(id: 'blue', name: 'Blue', color: 0xFF0066FF),
    //     ChannelConfig(id: 'violet', name: 'Violet', color: 0xFF8B00FF),
    //     ChannelConfig(id: 'uv', name: 'UV', color: 0xFF6600CC),
    //     ChannelConfig(id: 'coolWhite', name: 'Cool White', color: 0xFFFFFFFF),
    //     ChannelConfig(id: 'warmWhite', name: 'Warm White', color: 0xFFFFE4B5),
    //   ],
    // ),
  ];

  void updateDatabaseService(DatabaseService? service) {
    if (_databaseService == service) return;

    // Cancel existing subscriptions
    _cancelSubscriptions();

    _databaseService = service;

    if (service != null) {
      _subscribeToLights();
    }
  }

  void _cancelSubscriptions() {
    for (final sub in _statusSubscriptions.values) {
      sub.cancel();
    }
    for (final sub in _stateSubscriptions.values) {
      sub.cancel();
    }
    _statusSubscriptions.clear();
    _stateSubscriptions.clear();
  }

  void _subscribeToLights() {
    // Lighting control is not yet implemented.
    // Subscriptions will be added when the lighting backend is ready.
  }

  LightState getLightState(String lightId) {
    return _lightStates[lightId] ?? LightState();
  }

  LightConfig? getLightConfig(String lightId) {
    try {
      return lights.firstWhere((l) => l.id == lightId);
    } catch (_) {
      return null;
    }
  }

  // Control methods — not yet implemented
  Future<void> setMode(String lightId, String mode) async {}
  Future<void> setChannel(String lightId, String channel, int intensity) async {}
  Future<void> setMasterBrightness(String lightId, int brightness) async {}
  Future<void> setSchedule(
    String lightId, {
    required int onHour,
    required int onMinute,
    required int offHour,
    required int offMinute,
    required int rampMinutes,
  }) async {}

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
