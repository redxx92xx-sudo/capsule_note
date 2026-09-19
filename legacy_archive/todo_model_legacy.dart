import 'dart:convert';

enum TodoPriority {
  low,
  medium,
  high,
  urgent;

  String get key => name;
  static TodoPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'urgent':
        return TodoPriority.urgent;
      case 'high':
        return TodoPriority.high;
      case 'medium':
        return TodoPriority.medium;
      case 'low':
      default:
        return TodoPriority.low;
    }
  }
}

enum TodoRepeatRule {
  none,
  daily,
  weekly,
  monthly,
  custom;

  String get key => name;
  static TodoRepeatRule fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'daily':
        return TodoRepeatRule.daily;
      case 'weekly':
        return TodoRepeatRule.weekly;
      case 'monthly':
        return TodoRepeatRule.monthly;
      case 'custom':
        return TodoRepeatRule.custom;
      case 'none':
      default:
        return TodoRepeatRule.none;
    }
  }
}

class TodoModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime dueDate;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? completedAt;
  final TodoPriority priority;
  final bool isReminderEnabled;
  final DateTime? reminderTime;
  final TodoRepeatRule repeatRule;
  final DateTime? snoozeUntil;
  final DateTime? lastRemindedAt;
  final String? capsuleId;
  final int schemaVersion;
  final bool persistentReminder;
  final List<String> tags;

  const TodoModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.dueDate,
    this.deadline,
    this.isCompleted = false,
    this.completedAt,
    this.priority = TodoPriority.medium,
    this.isReminderEnabled = false,
    this.reminderTime,
    this.repeatRule = TodoRepeatRule.none,
    this.snoozeUntil,
    this.lastRemindedAt,
    this.capsuleId,
    this.schemaVersion = 1,
    this.persistentReminder = true,
    this.tags = const [],
  });

  bool isOverdue([DateTime? referenceTime]) {
    if (isCompleted) return false;
    final now = referenceTime ?? DateTime.now();
    final effectiveDeadline = deadline ?? dueDate;
    return effectiveDeadline.isBefore(now);
  }

  bool isDueOn(DateTime date) {
    return dueDate.year == date.year &&
        dueDate.month == date.month &&
        dueDate.day == date.day;
  }

  DateTime calculateNextDueDate() {
    switch (repeatRule) {
      case TodoRepeatRule.daily:
        return dueDate.add(const Duration(days: 1));
      case TodoRepeatRule.weekly:
        return dueDate.add(const Duration(days: 7));
      case TodoRepeatRule.monthly:
        return DateTime(dueDate.year, dueDate.month + 1, dueDate.day,
            dueDate.hour, dueDate.minute);
      case TodoRepeatRule.custom:
      case TodoRepeatRule.none:
        return dueDate;
    }
  }

  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? completedAt,
    TodoPriority? priority,
    bool? isReminderEnabled,
    DateTime? reminderTime,
    TodoRepeatRule? repeatRule,
    DateTime? snoozeUntil,
    DateTime? lastRemindedAt,
    String? capsuleId,
    int? schemaVersion,
    bool? persistentReminder,
    List<String>? tags,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatRule: repeatRule ?? this.repeatRule,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      lastRemindedAt: lastRemindedAt ?? this.lastRemindedAt,
      capsuleId: capsuleId ?? this.capsuleId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      persistentReminder: persistentReminder ?? this.persistentReminder,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority.key,
      'isReminderEnabled': isReminderEnabled ? 1 : 0,
      'reminderTime': reminderTime?.toIso8601String(),
      'repeatRule': repeatRule.key,
      'snoozeUntil': snoozeUntil?.toIso8601String(),
      'lastRemindedAt': lastRemindedAt?.toIso8601String(),
      'capsuleId': capsuleId,
      'schemaVersion': schemaVersion,
      'persistentReminder': persistentReminder ? 1 : 0,
      'tags': json.encode(tags),
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'] as String)
          : null,
      isCompleted: (map['isCompleted'] is int)
          ? (map['isCompleted'] as int) == 1
          : (map['isCompleted'] as bool? ?? false),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
      priority: TodoPriority.fromString(map['priority'] as String?),
      isReminderEnabled: (map['isReminderEnabled'] is int)
          ? (map['isReminderEnabled'] as int) == 1
          : (map['isReminderEnabled'] as bool? ?? false),
      reminderTime: map['reminderTime'] != null
          ? DateTime.tryParse(map['reminderTime'] as String)
          : null,
      repeatRule: TodoRepeatRule.fromString(map['repeatRule'] as String?),
      snoozeUntil: map['snoozeUntil'] != null
          ? DateTime.tryParse(map['snoozeUntil'] as String)
          : null,
      lastRemindedAt: map['lastRemindedAt'] != null
          ? DateTime.tryParse(map['lastRemindedAt'] as String)
          : null,
      capsuleId: map['capsuleId'] as String?,
      schemaVersion: map['schemaVersion'] as int? ?? 1,
      persistentReminder: (map['persistentReminder'] is int)
          ? (map['persistentReminder'] as int) == 1
          : (map['persistentReminder'] as bool? ?? true),
      tags: _parseTags(map['tags']),
    );
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return List<String>.from(raw);
    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        if (decoded is List) return List<String>.from(decoded);
      } catch (_) {}
    }
    return [];
  }

  String toJson() => json.encode(toMap());

  factory TodoModel.fromJson(String source) =>
      TodoModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
