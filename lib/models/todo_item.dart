import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import 'reminder_kind.dart';
import 'repeat_rule.dart';

enum TodoPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TodoPriority.low:
        return '低';
      case TodoPriority.normal:
        return '普通';
      case TodoPriority.high:
        return '重要';
      case TodoPriority.urgent:
        return '緊急';
    }
  }

  String localizedName(AppStrings s) {
    switch (this) {
      case TodoPriority.low:
        return s.priorityLow;
      case TodoPriority.normal:
        return s.priorityNormal;
      case TodoPriority.high:
        return s.priorityHigh;
      case TodoPriority.urgent:
        return s.priorityUrgent;
    }
  }

  int get value => index;

  static TodoPriority fromValue(int val) {
    if (val < 0 || val >= TodoPriority.values.length) {
      return TodoPriority.normal;
    }
    return TodoPriority.values[val];
  }
}

class TodoItem {
  final String id;
  final String title;
  final String notes;
  final DateTime createdAt;
  final DateTime scheduledDate;
  final DateTime? reminderTime;
  final bool isCompleted;
  final DateTime? completedAt;
  final TodoPriority priority;
  final RepeatType repeatRule;
  final List<int> repeatDays;
  final DateTime? snoozeUntil;
  final bool isPersistentReminder;
  final int persistentIntervalMinutes;
  final int persistentReminderCountToday;
  final String? lastPersistentReminderDate;
  final DateTime? nextReminderTime;
  final ReminderKind reminderKind;
  final int dataVersion;

  TodoItem({
    String? id,
    required this.title,
    this.notes = '',
    DateTime? createdAt,
    required this.scheduledDate,
    this.reminderTime,
    this.isCompleted = false,
    this.completedAt,
    this.priority = TodoPriority.normal,
    this.repeatRule = RepeatType.none,
    this.repeatDays = const [],
    this.snoozeUntil,
    this.isPersistentReminder = false,
    this.persistentIntervalMinutes = 60,
    this.persistentReminderCountToday = 0,
    this.lastPersistentReminderDate,
    this.nextReminderTime,
    this.reminderKind = ReminderKind.notification,
    this.dataVersion = 1,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  static const Object _unset = Object();

  TodoItem copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? createdAt,
    DateTime? scheduledDate,
    Object? reminderTime = _unset,
    bool? isCompleted,
    Object? completedAt = _unset,
    TodoPriority? priority,
    RepeatType? repeatRule,
    List<int>? repeatDays,
    Object? snoozeUntil = _unset,
    bool? isPersistentReminder,
    int? persistentIntervalMinutes,
    int? persistentReminderCountToday,
    Object? lastPersistentReminderDate = _unset,
    Object? nextReminderTime = _unset,
    ReminderKind? reminderKind,
    int? dataVersion,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      reminderTime: identical(reminderTime, _unset)
          ? this.reminderTime
          : reminderTime as DateTime?,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      priority: priority ?? this.priority,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatDays: repeatDays ?? this.repeatDays,
      snoozeUntil: identical(snoozeUntil, _unset)
          ? this.snoozeUntil
          : snoozeUntil as DateTime?,
      isPersistentReminder: isPersistentReminder ?? this.isPersistentReminder,
      persistentIntervalMinutes:
          persistentIntervalMinutes ?? this.persistentIntervalMinutes,
      persistentReminderCountToday:
          persistentReminderCountToday ?? this.persistentReminderCountToday,
      lastPersistentReminderDate: identical(lastPersistentReminderDate, _unset)
          ? this.lastPersistentReminderDate
          : lastPersistentReminderDate as String?,
      nextReminderTime: identical(nextReminderTime, _unset)
          ? this.nextReminderTime
          : nextReminderTime as DateTime?,
      reminderKind: reminderKind ?? this.reminderKind,
      dataVersion: dataVersion ?? this.dataVersion,
    );
  }

  TodoItem toggleCompleted() {
    final nextState = !isCompleted;
    return copyWith(
      isCompleted: nextState,
      completedAt: nextState ? DateTime.now() : null,
      nextReminderTime: nextState ? null : reminderTime,
      snoozeUntil: nextState ? null : snoozeUntil,
    );
  }

  bool isOverdue([DateTime? currentTime]) {
    if (isCompleted) return false;
    final now = currentTime ?? DateTime.now();
    if (snoozeUntil != null && snoozeUntil!.isAfter(now)) {
      return false;
    }
    if (reminderTime != null) {
      return reminderTime!.isBefore(now);
    }
    final endOfScheduledDay = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      23,
      59,
      59,
    );
    return endOfScheduledDay.isBefore(now);
  }

  bool isDueToday([DateTime? currentTime]) {
    final now = currentTime ?? DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  DateTime? computeNextPersistentReminder({
    DateTime? fromTime,
    int maxDailyCount = 6,
  }) {
    if (isCompleted || !isPersistentReminder) return null;
    final now = fromTime ?? DateTime.now();
    if (!isOverdue(now)) return null;

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    int currentCount = persistentReminderCountToday;
    if (lastPersistentReminderDate != todayStr) {
      currentCount = 0;
    }

    if (currentCount >= maxDailyCount) {
      final tomorrow = now.add(const Duration(days: 1));
      final baseHour = reminderTime?.hour ?? 9;
      final baseMin = reminderTime?.minute ?? 0;
      return DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        baseHour,
        baseMin,
      );
    }

    final interval = persistentIntervalMinutes > 0
        ? persistentIntervalMinutes
        : 60;
    return now.add(Duration(minutes: interval));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'scheduled_date': scheduledDate.toIso8601String(),
      'reminder_time': reminderTime?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'priority': priority.value,
      'repeat_rule': repeatRule.name,
      'repeat_days': repeatDays.join(','),
      'snooze_until': snoozeUntil?.toIso8601String(),
      'is_persistent_reminder': isPersistentReminder ? 1 : 0,
      'persistent_interval_minutes': persistentIntervalMinutes,
      'persistent_reminder_count_today': persistentReminderCountToday,
      'last_persistent_reminder_date': lastPersistentReminderDate,
      'next_reminder_time': nextReminderTime?.toIso8601String(),
      'reminder_kind': reminderKind.storageValue,
      'data_version': dataVersion,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    List<int> parsedRepeatDays = [];
    if (map['repeat_days'] != null &&
        map['repeat_days'].toString().isNotEmpty) {
      parsedRepeatDays = map['repeat_days']
          .toString()
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.tryParse(s) ?? 0)
          .where((i) => i > 0)
          .toList();
    }

    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'] as String)
          : null,
      isCompleted: (map['is_completed'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      priority: TodoPriority.fromValue((map['priority'] as int?) ?? 1),
      repeatRule: RepeatType.fromString(
        map['repeat_rule'] as String? ?? 'none',
      ),
      repeatDays: parsedRepeatDays,
      snoozeUntil: map['snooze_until'] != null
          ? DateTime.parse(map['snooze_until'] as String)
          : null,
      isPersistentReminder: (map['is_persistent_reminder'] as int?) == 1,
      persistentIntervalMinutes:
          (map['persistent_interval_minutes'] as int?) ?? 60,
      persistentReminderCountToday:
          (map['persistent_reminder_count_today'] as int?) ?? 0,
      lastPersistentReminderDate:
          map['last_persistent_reminder_date'] as String?,
      nextReminderTime: map['next_reminder_time'] != null
          ? DateTime.parse(map['next_reminder_time'] as String)
          : null,
      reminderKind: ReminderKind.fromStorage(
        map['reminder_kind'] ?? map['reminderKind'],
      ),
      dataVersion: (map['data_version'] as int?) ?? 1,
    );
  }
}
