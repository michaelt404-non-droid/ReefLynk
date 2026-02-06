import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reeflynk/models/maintenance_task.dart';
import 'package:reeflynk/models/maintenance_completion.dart';
import 'package:reeflynk/models/livestock.dart';

// Data model for a single sensor reading
class SensorReading {
  final DateTime timestamp;
  final double value;
  final int id;

  SensorReading({required this.timestamp, required this.value, required this.id});

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'],
      timestamp: DateTime.parse(map['created_at']),
      value: map['value'].toDouble(),
    );
  }
}

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _uid => _supabase.auth.currentUser?.id;

  // Generic function to get a stream of readings for any sensor type
  Stream<List<SensorReading>> getSensorStream(String sensorType, {Duration? duration}) {
    final uid = _uid;
    if (uid == null) {
      return Stream.value([]);
    }

    late final StreamController<List<SensorReading>> streamController;
    late final RealtimeChannel channel;

    Future<void> fetchData() async {
      try {
        var query = _supabase
            .from('sensor_readings')
            .select()
            .eq('user_id', uid)
            .eq('sensor_type', sensorType);

        if (duration != null) {
          final cutoff = DateTime.now().subtract(duration);
          query = query.gte('created_at', cutoff.toIso8601String());
        }
        
        final data = await query.order('created_at', ascending: false);

        final readings = data.map((item) => SensorReading.fromMap(item)).toList();
        if (!streamController.isClosed) {
          streamController.add(readings);
        }
      } catch (e) {
        if (!streamController.isClosed) {
          streamController.addError('Failed to fetch sensor data: $e');
        }
      }
    }

    streamController = StreamController<List<SensorReading>>.broadcast(
      onListen: () => fetchData(),
      onCancel: () => _supabase.removeChannel(channel),
    );

    channel = _supabase.channel('public:sensor_readings:type=$sensorType');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sensor_readings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: uid,
      ),
      callback: (payload) => fetchData(),
    ).subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          fetchData();
        }
    });

    return streamController.stream;
  }

  // Specific streams for each sensor
  Stream<List<SensorReading>> getTemperatureStream({Duration? duration}) => getSensorStream('temperature', duration: duration);
  Stream<List<SensorReading>> getPhStream({Duration? duration}) => getSensorStream('ph', duration: duration);
  Stream<List<SensorReading>> getAlkalinityStream({Duration? duration}) => getSensorStream('alkalinity', duration: duration);
  Stream<List<SensorReading>> getCalciumStream({Duration? duration}) => getSensorStream('calcium', duration: duration);
  Stream<List<SensorReading>> getMagnesiumStream({Duration? duration}) => getSensorStream('magnesium', duration: duration);
  Stream<List<SensorReading>> getOrpStream({Duration? duration}) => getSensorStream('orp', duration: duration);
  Stream<List<SensorReading>> getAmmoniaStream({Duration? duration}) => getSensorStream('ammonia', duration: duration);
  Stream<List<SensorReading>> getNitrateStream({Duration? duration}) => getSensorStream('nitrate', duration: duration);
  Stream<List<SensorReading>> getNitriteStream({Duration? duration}) => getSensorStream('nitrite', duration: duration);
  Stream<List<SensorReading>> getPhosphateStream({Duration? duration}) => getSensorStream('phosphate', duration: duration);


  // Stream for all sensor modes
  Stream<Map<String, String>> getSensorModesStream() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value({});
    }
    late final StreamController<Map<String, String>> streamController;
    late final RealtimeChannel channel;

    Future<void> fetchModes() async {
        final data = await _supabase.from('sensor_configs').select().eq('user_id', uid);
        final modes = {for (var item in data) item['sensor_type'] as String: item['mode'] as String};
        if(!streamController.isClosed) {
          streamController.add(modes);
        }
    }

    streamController = StreamController<Map<String, String>>.broadcast(
      onListen: () => fetchModes(),
      onCancel: () => _supabase.removeChannel(channel),
    );

    channel = _supabase.channel('public:sensor_configs');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'sensor_configs',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: uid,
      ),
      callback: (payload) => fetchModes(),
    ).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        fetchModes();
      }
    });

    return streamController.stream;
  }

  // --- DATA MANAGEMENT ---
  Future<void> updateParameterEntry(int readingId, double newValue) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');

    await _supabase
        .from('sensor_readings')
        .update({'value': newValue})
        .eq('id', readingId)
        .eq('user_id', uid); 
  }

  Future<void> deleteParameterEntry(int readingId) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase
        .from('sensor_readings')
        .delete()
        .eq('id', readingId)
        .eq('user_id', uid);
  }

  Future<void> saveSensorData(Map<String, double> sensorData) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');

    final List<Map<String, dynamic>> readingsToInsert = [];
    final now = DateTime.now().toIso8601String();

    sensorData.forEach((sensorName, value) {
      readingsToInsert.add({
        'user_id': uid,
        'created_at': now,
        'sensor_type': sensorName.toLowerCase(),
        'value': value,
      });
    });

    if (readingsToInsert.isNotEmpty) {
      await _supabase.from('sensor_readings').insert(readingsToInsert);
    }
  }

  Future<void> updateSensorMode(String sensorName, String mode) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase.from('sensor_configs').upsert({
      'user_id': uid,
      'sensor_type': sensorName,
      'mode': mode,
    });
  }

  Future<void> bulkUpdateSensorModes(String mode) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    final List<String> sensors = [
      'temperature', 'ph', 'alkalinity', 'calcium', 'magnesium', 'orp',
      'ammonia', 'nitrate', 'nitrite', 'phosphate',
    ];

    final List<Map<String, dynamic>> updates = sensors.map((sensorName) => {
      'user_id': uid,
      'sensor_type': sensorName,
      'mode': mode,
    }).toList();

    await _supabase.from('sensor_configs').upsert(updates);
  }

  // --- MAINTENANCE TASKS ---

  Stream<List<MaintenanceTask>> getMaintenanceTasksStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    late final StreamController<List<MaintenanceTask>> streamController;
    late final RealtimeChannel channel;

    Future<void> fetchTasks() async {
      try {
        final data = await _supabase
            .from('maintenance_tasks')
            .select()
            .eq('user_id', uid)
            .eq('is_active', true)
            .order('created_at', ascending: false);

        final tasks = data.map((item) => MaintenanceTask.fromMap(item)).toList();
        if (!streamController.isClosed) {
          streamController.add(tasks);
        }
      } catch (e) {
        if (!streamController.isClosed) {
          streamController.addError('Failed to fetch maintenance tasks: $e');
        }
      }
    }

    streamController = StreamController<List<MaintenanceTask>>.broadcast(
      onListen: () => fetchTasks(),
      onCancel: () => _supabase.removeChannel(channel),
    );

    channel = _supabase.channel('public:maintenance_tasks');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'maintenance_tasks',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: uid,
      ),
      callback: (payload) => fetchTasks(),
    ).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        fetchTasks();
      }
    });

    return streamController.stream;
  }

  Future<void> createMaintenanceTask(MaintenanceTask task) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    final data = task.toInsertMap()..['user_id'] = uid;
    await _supabase.from('maintenance_tasks').insert(data);
  }

  Future<void> updateMaintenanceTask(int id, MaintenanceTask task) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase
        .from('maintenance_tasks')
        .update(task.toInsertMap())
        .eq('id', id)
        .eq('user_id', uid);
  }

  Future<void> deleteMaintenanceTask(int id) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase
        .from('maintenance_tasks')
        .delete()
        .eq('id', id)
        .eq('user_id', uid);
  }

  Future<Map<int, MaintenanceCompletion>> getLatestCompletions() async {
    final uid = _uid;
    if (uid == null) return {};
    final data = await _supabase
        .from('maintenance_completions')
        .select()
        .eq('user_id', uid)
        .order('completed_at', ascending: false);

    final completions = <int, MaintenanceCompletion>{};
    for (final item in data) {
      final completion = MaintenanceCompletion.fromMap(item);
      // Keep only the latest completion per task
      if (!completions.containsKey(completion.taskId)) {
        completions[completion.taskId] = completion;
      }
    }
    return completions;
  }

  Future<void> completeMaintenanceTask(int taskId, String? notes) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase.from('maintenance_completions').insert({
      'task_id': taskId,
      'user_id': uid,
      'completed_at': DateTime.now().toIso8601String(),
      'notes': notes,
    });
  }

  // --- LIVESTOCK ---
  Future<String> uploadLivestockImage(Uint8List imageBytes, String fileName) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    try {
      final String path = '$uid/$fileName';
      await _supabase.storage
          .from('livestock_images')
          .uploadBinary(path, imageBytes);

      return path; // Return the path, not the public URL
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createSignedUrl(String path) async {
    final response = await _supabase.storage
        .from('livestock_images')
        .createSignedUrl(path, 3600); // URL is valid for 1 hour
    return response;
  }
  
  Stream<List<Livestock>> getLivestockStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    late final StreamController<List<Livestock>> streamController;
    late final RealtimeChannel channel;

    Future<void> fetchLivestock() async {
      try {
        final data = await _supabase
            .from('livestock')
            .select()
            .eq('user_id', uid)
            .order('species_type')
            .order('common_name');

        final items = data.map((item) => Livestock.fromMap(item)).toList();
        if (!streamController.isClosed) {
          streamController.add(items);
        }
      } catch (e) {
        if (!streamController.isClosed) {
          streamController.addError('Failed to fetch livestock: $e');
        }
      }
    }

    streamController = StreamController<List<Livestock>>.broadcast(
      onListen: () => fetchLivestock(),
      onCancel: () => _supabase.removeChannel(channel),
    );

    channel = _supabase.channel('public:livestock');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'livestock',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: uid,
      ),
      callback: (payload) => fetchLivestock(),
    ).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        fetchLivestock();
      }
    });

    return streamController.stream;
  }

  Future<void> addLivestock(Livestock item) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    final data = Map<String, dynamic>.from(item.toInsertMap());
    data['user_id'] = uid;
    print('DEBUG: Inserting livestock data: $data');
    await _supabase.from('livestock').insert([data]);
  }

  Future<void> updateLivestock(int id, Livestock item) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase
        .from('livestock')
        .update(item.toInsertMap())
        .eq('id', id)
        .eq('user_id', uid);
  }

  Future<void> deleteLivestock(int id) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase
        .from('livestock')
        .delete()
        .eq('id', id)
        .eq('user_id', uid);
  }

  // --- NOTIFICATION PREFERENCES ---

  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    final uid = _uid;
    if (uid == null) return null;
    final data = await _supabase
        .from('user_notification_preferences')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return data;
  }

  Future<void> updateNotificationPreferences(Map<String, dynamic> updates) async {
    final uid = _uid;
    if (uid == null) throw Exception('User is not logged in');
    await _supabase.from('user_notification_preferences').upsert({
      'user_id': uid,
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}