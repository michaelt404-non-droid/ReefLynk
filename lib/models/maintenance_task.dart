class MaintenanceTask {
  final int? id;
  final String name;
  final String taskType;
  final String frequency;
  final int? preferredDay;
  final String preferredTime;
  final int remindBeforeHours;
  final bool isActive;
  final DateTime? createdAt;

  MaintenanceTask({
    this.id,
    required this.name,
    required this.taskType,
    required this.frequency,
    this.preferredDay,
    this.preferredTime = '09:00',
    this.remindBeforeHours = 1,
    this.isActive = true,
    this.createdAt,
  });

  factory MaintenanceTask.fromMap(Map<String, dynamic> map) {
    return MaintenanceTask(
      id: map['id'],
      name: map['name'],
      taskType: map['task_type'],
      frequency: map['frequency'],
      preferredDay: map['preferred_day'],
      preferredTime: map['preferred_time'] ?? '09:00',
      remindBeforeHours: map['remind_before_hours'] ?? 1,
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'task_type': taskType,
      'frequency': frequency,
      'preferred_day': preferredDay,
      'preferred_time': preferredTime,
      'remind_before_hours': remindBeforeHours,
      'is_active': isActive,
    };
  }

  MaintenanceTask copyWith({
    int? id,
    String? name,
    String? taskType,
    String? frequency,
    int? preferredDay,
    String? preferredTime,
    int? remindBeforeHours,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      name: name ?? this.name,
      taskType: taskType ?? this.taskType,
      frequency: frequency ?? this.frequency,
      preferredDay: preferredDay ?? this.preferredDay,
      preferredTime: preferredTime ?? this.preferredTime,
      remindBeforeHours: remindBeforeHours ?? this.remindBeforeHours,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const taskTypes = ['water_change', 'cleaning', 'parameter_check', 'custom'];
  static const frequencies = ['daily', 'weekly', 'biweekly', 'monthly'];

  static String taskTypeLabel(String type) {
    switch (type) {
      case 'water_change':
        return 'Water Change';
      case 'cleaning':
        return 'Cleaning';
      case 'parameter_check':
        return 'Parameter Check';
      case 'custom':
        return 'Custom';
      default:
        return type;
    }
  }

  static String frequencyLabel(String freq) {
    switch (freq) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Biweekly';
      case 'monthly':
        return 'Monthly';
      default:
        return freq;
    }
  }
}
