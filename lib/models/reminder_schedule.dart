class ReminderScheduleRecord {
  static const String typeRegular = 'regular';
  static const String typePersistent = 'persistent';
  static const String typeSnooze = 'snooze';
  static const String typeDailySummary = 'daily_summary';

  final int? id;
  final String? todoId;
  final int notificationId;
  final DateTime triggerTime;
  final String type;

  const ReminderScheduleRecord({
    this.id,
    this.todoId,
    required this.notificationId,
    required this.triggerTime,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'todo_id': todoId,
      'notification_id': notificationId,
      'trigger_time': triggerTime.toIso8601String(),
      'type': type,
    };
  }

  factory ReminderScheduleRecord.fromMap(Map<String, dynamic> map) {
    return ReminderScheduleRecord(
      id: map['id'] as int?,
      todoId: map['todo_id'] as String?,
      notificationId: map['notification_id'] as int,
      triggerTime: DateTime.parse(map['trigger_time'] as String),
      type: map['type'] as String,
    );
  }
}
