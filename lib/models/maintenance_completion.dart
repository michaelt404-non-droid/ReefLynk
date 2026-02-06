class MaintenanceCompletion {
  final int? id;
  final int taskId;
  final String userId;
  final DateTime completedAt;
  final String? notes;
  final DateTime? createdAt;

  MaintenanceCompletion({
    this.id,
    required this.taskId,
    required this.userId,
    required this.completedAt,
    this.notes,
    this.createdAt,
  });

  factory MaintenanceCompletion.fromMap(Map<String, dynamic> map) {
    return MaintenanceCompletion(
      id: map['id'],
      taskId: map['task_id'],
      userId: map['user_id'],
      completedAt: DateTime.parse(map['completed_at']),
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }
}
