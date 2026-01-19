import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final String? uid;

  // Cache for the last emitted value per sensor (enables replay to new subscribers)
  final Map<String, Map<String, dynamic>> _sensorValueCache = {};
  // Cache for replay StreamControllers - these handle the "emit cached value on subscribe" pattern
  final Map<String, StreamController<Map<String, dynamic>>> _sensorControllers = {};

  Stream<Map<String, String>>? _sensorModesStreamCache;

  DatabaseService({this.uid});

  Stream<Map<String, dynamic>> _getSensorStream(String sensorName) {
    if (uid == null) {
      return Stream.value({});
    }

    // Return existing controller's stream if available
    if (_sensorControllers.containsKey(sensorName)) {
      final controller = _sensorControllers[sensorName]!;
      if (!controller.isClosed) {
        return controller.stream;
      }
    }

    // Create a new broadcast StreamController with replay capability
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _sensorControllers[sensorName] = controller;

    // Listen to Firebase and forward to controller
    _database
        .ref('users/$uid/sensors/$sensorName')
        .onValue
        .listen((event) {
      final Map<String, dynamic> data = {};
      final dynamic value = event.snapshot.value;

      if (value != null && value is Map) {
        value.forEach((key, val) {
          if (val is Map) {
            // New, correct format: { "value": ..., "timestamp": ... }
            data[key.toString()] = val;
          } else if (val is num) {
            // Old format from a previous fix: "-PushId": 123.45
            // Wrap it to prevent a crash.
            data[key.toString()] = {
              'value': val,
              'timestamp': 0 // We don't have a real timestamp, so use 0.
            };
          }
        });
      } else if (value != null && value is num) {
        // Old format where the path held a single number.
        // Wrap it so it can be displayed.
        data['current'] = {
           'value': value,
           'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000
        };
      }

      // Cache the latest value for replay to new subscribers
      _sensorValueCache[sensorName] = Map<String, dynamic>.from(data);

      // Emit to all current subscribers
      if (!controller.isClosed) {
        controller.add(data);
      }
    });

    return controller.stream;
  }

  /// Get cached value for a sensor (for use as initialData in StreamBuilder)
  Map<String, dynamic>? getCachedSensorValue(String sensorName) {
    final cached = _sensorValueCache[sensorName];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return null;
  }

  // Stream for temperature data
  Stream<Map<String, dynamic>> getTemperatureStream() {
    return _getSensorStream('temperature');
  }

  // Stream for pH data
  Stream<Map<String, dynamic>> getPhStream() {
    return _getSensorStream('ph');
  }

  // Stream for alkalinity data
  Stream<Map<String, dynamic>> getAlkalinityStream() {
    return _getSensorStream('alkalinity');
  }

  // Stream for calcium data
  Stream<Map<String, dynamic>> getCalciumStream() {
    return _getSensorStream('calcium');
  }

  // Stream for magnesium data
  Stream<Map<String, dynamic>> getMagnesiumStream() {
    return _getSensorStream('magnesium');
  }

  // Stream for ORP data
  Stream<Map<String, dynamic>> getOrpStream() {
    return _getSensorStream('orp');
  }

  // Stream for ammonia data
  Stream<Map<String, dynamic>> getAmmoniaStream() {
    return _getSensorStream('ammonia');
  }

  // Stream for nitrate data
  Stream<Map<String, dynamic>> getNitrateStream() {
    return _getSensorStream('nitrate');
  }

  // Stream for nitrite data
  Stream<Map<String, dynamic>> getNitriteStream() {
    return _getSensorStream('nitrite');
  }

  // Stream for phosphate data
  Stream<Map<String, dynamic>> getPhosphateStream() {
    return _getSensorStream('phosphate');
  }

  // --- DATA MANAGEMENT ---
  Future<void> updateParameterEntry(String parameterType, String timestampKey, double newValue) async {
    if (uid == null) throw Exception('User is not logged in');

    // FIX: Handle the special "current" key for old/raw data
    if (timestampKey == 'current') {
      // If the key is 'current', we are editing a raw number at the root.
      // We overwrite the root node directly.
      await _database.ref('users/$uid/sensors/$parameterType').set(newValue);
    } else {
      // Normal update for list items
      await _database.ref('users/$uid/sensors/$parameterType/$timestampKey/value').set(newValue);
    }
  }

  Future<void> deleteParameterEntry(String parameterType, String timestampKey) async {
    if (uid == null) throw Exception('User is not logged in');

    // FIX: Handle the special "current" key
    if (timestampKey == 'current') {
      // If the key is 'current', it means we are looking at a raw number node.
      // We delete the whole node to clear it.
      await _database.ref('users/$uid/sensors/$parameterType').remove();
    } else {
      // Normal deletion for list items
      await _database.ref('users/$uid/sensors/$parameterType/$timestampKey').remove();
    }
  }

  // --- MANUAL ENTRY SAVE FUNCTION ---
  Future<void> saveSensorData(Map<String, double> sensorData) async {
    if (uid == null) throw Exception('User is not logged in');

    final Map<String, dynamic> updates = {};

    sensorData.forEach((sensorName, value) {
      final newKey = _database.ref().push().key;
      
      // TRANSLATOR: Convert App Labels to Database Paths
      String dbPath = sensorName.toLowerCase(); // Default fallback
      
      switch (sensorName) {
        case 'Temp':
          dbPath = 'temperature';
          break;
        case 'Alk':
          dbPath = 'alkalinity';
          break;
        case 'Ca':
          dbPath = 'calcium';
          break;
        case 'Mg':
          dbPath = 'magnesium';
          break;
        case 'Amm':
          dbPath = 'ammonia';
          break;
        // These are already correct, but good to be explicit:
        case 'pH':
          dbPath = 'ph';
          break;
        case 'ORP':
          dbPath = 'orp';
          break;
        case 'Nitrate':
          dbPath = 'nitrate';
          break;
        case 'Nitrite':
          dbPath = 'nitrite';
          break;
        case 'Phosphate':
          dbPath = 'phosphate';
          break;
      }

      // Save to the correct translated path (user-specific)
      updates['users/$uid/sensors/$dbPath/$newKey'] = {
        'timestamp': ServerValue.timestamp,
        'value': value,
      };
    });

    await _database.ref().update(updates);
  }

  // Cache for sensor modes replay
  Map<String, String>? _sensorModesValueCache;

  // Stream for sensor modes
  Stream<Map<String, String>> getSensorModesStream() {
    if (uid == null) {
      return Stream.value({});
    }

    // If we have a cached stream and cached value, replay the value first
    if (_sensorModesStreamCache != null && _sensorModesValueCache != null) {
      return _createSensorModesReplayStream(_sensorModesValueCache!);
    }

    if (_sensorModesStreamCache != null) {
      return _sensorModesStreamCache!;
    }

    _sensorModesStreamCache = _database.ref('users/$uid/sensors').onValue.map((event) {
      final Map<String, String> modes = {};
      if (event.snapshot.value != null) {
        (event.snapshot.value as Map).forEach((sensorName, sensorData) {
          if (sensorData is Map && sensorData.containsKey('mode')) {
            modes[sensorName] = sensorData['mode'] as String;
          } else {
            modes[sensorName] = 'auto';
          }
        });
      }
      // Cache the latest value for replay
      _sensorModesValueCache = Map<String, String>.from(modes);
      return modes;
    }).asBroadcastStream();

    return _sensorModesStreamCache!;
  }

  /// Creates a replay stream for sensor modes
  Stream<Map<String, String>> _createSensorModesReplayStream(Map<String, String> cachedValue) async* {
    yield cachedValue;
    await for (final value in _sensorModesStreamCache!) {
      yield value;
    }
  }

  // Method to update sensor mode
  Future<void> updateSensorMode(String sensorName, String mode) async {
    if (uid == null) {
      throw Exception('User is not logged in');
    }
    // This path uses the old structure.
    await _database.ref('users/$uid/sensors/$sensorName/mode').set(mode);
  }

  // Method to bulk update sensor modes
  Future<void> bulkUpdateSensorModes(String mode) async {
    if (uid == null) {
      throw Exception('User is not logged in');
    }
    final Map<String, dynamic> updates = {};
    final List<String> sensors = [
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
    for (final sensorName in sensors) {
      // This path uses the old structure.
      updates['users/$uid/sensors/$sensorName/mode'] = mode;
    }
    await _database.ref().update(updates);
  }

  // =============================================================================
  // LIGHTING CONTROL
  // =============================================================================

  // Cache for light streams and their last values (for replay)
  final Map<String, Stream<Map<String, dynamic>>> _lightStatusStreamCache = {};
  final Map<String, Stream<Map<String, dynamic>>> _lightStateStreamCache = {};
  final Map<String, Map<String, dynamic>> _lightStatusValueCache = {};
  final Map<String, Map<String, dynamic>> _lightStateValueCache = {};

  /// Get stream of light status (read-only, from ESP32)
  Stream<Map<String, dynamic>> getLightStatusStream(String lightId) {
    if (uid == null) {
      return Stream.value({});
    }

    // If we have a cached stream and value, replay the value first
    if (_lightStatusStreamCache.containsKey(lightId) && _lightStatusValueCache.containsKey(lightId)) {
      return _createLightReplayStream(_lightStatusStreamCache[lightId]!, _lightStatusValueCache[lightId]!);
    }

    if (_lightStatusStreamCache.containsKey(lightId)) {
      return _lightStatusStreamCache[lightId]!;
    }

    final stream = _database
        .ref('users/$uid/lights/$lightId/status')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <String, dynamic>{};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      _lightStatusValueCache[lightId] = data;
      return data;
    }).asBroadcastStream();

    _lightStatusStreamCache[lightId] = stream;
    return stream;
  }

  /// Get stream of light state (commands sent to ESP32)
  Stream<Map<String, dynamic>> getLightStateStream(String lightId) {
    if (uid == null) {
      return Stream.value({});
    }

    // If we have a cached stream and value, replay the value first
    if (_lightStateStreamCache.containsKey(lightId) && _lightStateValueCache.containsKey(lightId)) {
      return _createLightReplayStream(_lightStateStreamCache[lightId]!, _lightStateValueCache[lightId]!);
    }

    if (_lightStateStreamCache.containsKey(lightId)) {
      return _lightStateStreamCache[lightId]!;
    }

    final stream = _database
        .ref('users/$uid/lights/$lightId/state')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <String, dynamic>{};
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      _lightStateValueCache[lightId] = data;
      return data;
    }).asBroadcastStream();

    _lightStateStreamCache[lightId] = stream;
    return stream;
  }

  /// Creates a replay stream for light data
  Stream<Map<String, dynamic>> _createLightReplayStream(Stream<Map<String, dynamic>> baseStream, Map<String, dynamic> cachedValue) async* {
    yield cachedValue;
    await for (final value in baseStream) {
      yield value;
    }
  }

  /// Set light mode ("off", "manual", "schedule")
  Future<void> setLightMode(String lightId, String mode) async {
    if (uid == null) throw Exception('User is not logged in');
    await _database.ref('users/$uid/lights/$lightId/state/mode').set(mode);
  }

  /// Set channel intensity (0-100)
  Future<void> setLightChannel(String lightId, String channel, int intensity) async {
    if (uid == null) throw Exception('User is not logged in');
    await _database.ref('users/$uid/lights/$lightId/state/$channel').set(intensity);
  }

  /// Set master brightness (0-100)
  Future<void> setLightMasterBrightness(String lightId, int brightness) async {
    if (uid == null) throw Exception('User is not logged in');
    await _database.ref('users/$uid/lights/$lightId/state/master').set(brightness);
  }

  /// Update light schedule
  Future<void> setLightSchedule(
    String lightId, {
    required int onHour,
    required int onMinute,
    required int offHour,
    required int offMinute,
    required int rampMinutes,
  }) async {
    if (uid == null) throw Exception('User is not logged in');
    await _database.ref('users/$uid/lights/$lightId/state/schedule').set({
      'onHour': onHour,
      'onMinute': onMinute,
      'offHour': offHour,
      'offMinute': offMinute,
      'rampMinutes': rampMinutes,
    });
  }

  /// Update multiple light state values at once
  Future<void> updateLightState(String lightId, Map<String, dynamic> updates) async {
    if (uid == null) throw Exception('User is not logged in');
    final Map<String, dynamic> pathUpdates = {};
    updates.forEach((key, value) {
      pathUpdates['users/$uid/lights/$lightId/state/$key'] = value;
    });
    await _database.ref().update(pathUpdates);
  }
}