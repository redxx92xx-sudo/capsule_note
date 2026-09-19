import '../models/reminder_schedule.dart';
import '../models/repeat_rule.dart';
import '../models/todo_item.dart';
import '../utils/rk_trace.dart';
import 'alarm_port.dart';
import 'database_service.dart';
import 'notification_port.dart';

class ReminderScheduler {
  static ReminderScheduler? _instance;
  static ReminderScheduler? _testOverride;

  final DatabaseService? _injectedDb;
  final INotificationService? _injectedNotif;
  final IAlarmScheduler? _injectedAlarm;

  ReminderScheduler({
    DatabaseService? dbService,
    INotificationService? notifService,
    IAlarmScheduler? alarmService,
  }) : _injectedDb = dbService,
       _injectedNotif = notifService,
       _injectedAlarm = alarmService;

  static ReminderScheduler get instance =>
      _testOverride ?? (_instance ??= ReminderScheduler());

  static void bindDefault(ReminderScheduler scheduler) {
    _instance = scheduler;
  }

  static set instanceForTest(ReminderScheduler? scheduler) {
    _testOverride = scheduler;
  }

  DatabaseService get _dbService => _injectedDb ?? DatabaseService.instance;

  INotificationService get _notifService =>
      _injectedNotif ?? NotificationPort.instance;

  IAlarmScheduler get _alarmService => _injectedAlarm ?? AlarmPort.instance;

  DateTime _minute(DateTime value) =>
      DateTime(value.year, value.month, value.day, value.hour, value.minute);

  String _dayKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  /// 同步單筆待辦事項的鬧鐘提醒與持續提醒（冪等）
  Future<DateTime?> syncTodo(TodoItem todo, {DateTime? nowTime}) async {
    final now = nowTime ?? DateTime.now();
    rkTrace('scheduler.syncTodo id=${todo.id}');

    if (todo.isCompleted) {
      await cancelTodo(todo.id);
      if (todo.nextReminderTime != null) {
        await _dbService.updateTodo(todo.copyWith(nextReminderTime: null));
      }
      return null;
    }

    DateTime? nextReminder;
    final snooze = todo.snoozeUntil;
    if (snooze != null && snooze.isAfter(now)) {
      nextReminder = _minute(snooze);
      await _reconcile(
        todoId: todo.id,
        type: ReminderScheduleRecord.typeSnooze,
        desired: [
          _DesiredReminder(
            notificationId: NotificationIds.generateStableNotificationId(
              todo.id,
            ),
            triggerTime: nextReminder,
            title: todo.title,
            body: '稍後提醒：${todo.title}',
            isUrgent: true,
            payload: todo.id,
            asAlarm: todo.reminderKind.isAlarm,
          ),
        ],
      );
      await _reconcile(
        todoId: todo.id,
        type: ReminderScheduleRecord.typeRegular,
        desired: const [],
      );
      final persistentAfterSnooze = await _buildPersistentWindow(
        todo,
        now,
        after: nextReminder,
      );
      await _reconcile(
        todoId: todo.id,
        type: ReminderScheduleRecord.typePersistent,
        desired: persistentAfterSnooze,
      );
    } else {
      nextReminder = RepeatRuleHelper.calculateNextReminder(
        fromTime: now,
        scheduledDate: todo.scheduledDate,
        baseReminderTime: todo.reminderTime,
        repeatType: todo.repeatRule,
        repeatDays: todo.repeatDays,
      );
      if (nextReminder != null) {
        nextReminder = _minute(nextReminder);
      }

      final regularDesired = <_DesiredReminder>[];
      if (nextReminder != null && nextReminder.isAfter(now)) {
        regularDesired.add(
          _DesiredReminder(
            notificationId: NotificationIds.generateStableNotificationId(
              todo.id,
            ),
            triggerTime: nextReminder,
            title: todo.title,
            body: todo.notes.isNotEmpty ? todo.notes : '待辦事項提醒：${todo.title}',
            isUrgent:
                todo.priority == TodoPriority.urgent ||
                todo.priority == TodoPriority.high,
            payload: todo.id,
            asAlarm: todo.reminderKind.isAlarm,
          ),
        );
      }

      await _reconcile(
        todoId: todo.id,
        type: ReminderScheduleRecord.typeRegular,
        desired: regularDesired,
      );
      await _reconcile(
        todoId: todo.id,
        type: ReminderScheduleRecord.typeSnooze,
        desired: const [],
      );

      final persistentDesired = await _buildPersistentWindow(todo, now);
      await _reconcile(
        todoId: todo.id,
        type: ReminderScheduleRecord.typePersistent,
        desired: persistentDesired,
      );

      final todayKey = _dayKey(now);
      final todayPersistent = persistentDesired
          .where((item) => _dayKey(item.triggerTime) == todayKey)
          .length;
      await _dbService.updateTodo(
        todo.copyWith(
          nextReminderTime: nextReminder,
          persistentReminderCountToday: todayPersistent,
          lastPersistentReminderDate: persistentDesired.isEmpty
              ? todo.lastPersistentReminderDate
              : todayKey,
        ),
      );
      return nextReminder;
    }

    await _dbService.updateTodo(todo.copyWith(nextReminderTime: nextReminder));
    return nextReminder;
  }

  Future<List<_DesiredReminder>> _buildPersistentWindow(
    TodoItem todo,
    DateTime now, {
    DateTime? after,
  }) async {
    if (!todo.isPersistentReminder || todo.isCompleted) {
      return const [];
    }

    final maxDailySetting = await _dbService.getSetting('persistent_daily_max');
    final maxDaily = int.tryParse(maxDailySetting ?? '') ?? 6;
    final intervalMinutes = todo.persistentIntervalMinutes > 0
        ? todo.persistentIntervalMinutes
        : 60;
    final interval = Duration(minutes: intervalMinutes);
    final horizonEnd = now.add(const Duration(hours: 24));

    final firstOccurrence = DateTime(
      todo.scheduledDate.year,
      todo.scheduledDate.month,
      todo.scheduledDate.day,
      todo.reminderTime?.hour ?? 9,
      todo.reminderTime?.minute ?? 0,
    );
    DateTime startAfter = now;
    if (after != null && after.isAfter(now)) {
      startAfter = after;
    } else if (firstOccurrence.isAfter(now)) {
      startAfter = firstOccurrence;
    }

    final times = <DateTime>[];
    final perDay = <String, int>{};
    DateTime cursor;
    if (intervalMinutes >= 1440) {
      final hour = todo.reminderTime?.hour ?? 9;
      final minute = todo.reminderTime?.minute ?? 0;
      cursor = DateTime(now.year, now.month, now.day, hour, minute);
      if (!cursor.isAfter(now) || !cursor.isAfter(startAfter)) {
        cursor = cursor.add(const Duration(days: 1));
      }
    } else {
      cursor = startAfter.add(interval);
    }
    cursor = _minute(cursor);
    if (!cursor.isAfter(now)) {
      cursor = _minute(now.add(interval));
    }

    while (times.length < maxDaily &&
        cursor.isBefore(horizonEnd.add(const Duration(hours: 12)))) {
      final key = _dayKey(cursor);
      final used = perDay[key] ?? 0;
      if (used >= maxDaily) {
        cursor = DateTime(
          cursor.year,
          cursor.month,
          cursor.day + 1,
          cursor.hour,
          cursor.minute,
        );
        continue;
      }
      times.add(cursor);
      perDay[key] = used + 1;
      cursor = _minute(cursor.add(interval));
    }

    final desired = <_DesiredReminder>[];
    for (var i = 0; i < times.length; i++) {
      desired.add(
        _DesiredReminder(
          notificationId: NotificationIds.generatePersistentNotificationId(
            todo.id,
            i,
          ),
          triggerTime: times[i],
          title: '【持續提醒】${todo.title}',
          body: '此事項尚未完成，請及時處理：${todo.title}',
          isUrgent: true,
          payload: todo.id,
          asAlarm: todo.reminderKind.isAlarm,
        ),
      );
    }
    return desired;
  }

  Future<void> _reconcile({
    required String? todoId,
    required String type,
    required List<_DesiredReminder> desired,
    String channelId = NotificationIds.channelIdDefault,
    String channelName = NotificationIds.channelNameDefault,
    bool includeActions = true,
  }) async {
    final existing = await _dbService.getSchedules(todoId: todoId, type: type);
    final desiredTimes = {
      for (final item in desired) item.triggerTime.toIso8601String(),
    };

    for (final row in existing) {
      if (!desiredTimes.contains(row.triggerTime.toIso8601String())) {
        await _cancelId(row.notificationId);
        if (row.id != null) {
          await _dbService.deleteScheduleById(row.id!);
        }
      }
    }

    final existingTimes = {
      for (final row in existing) row.triggerTime.toIso8601String(),
    };

    for (final item in desired) {
      final alreadyTracked = existingTimes.contains(
        item.triggerTime.toIso8601String(),
      );
      if (!alreadyTracked) {
        final pending = await _dbService.countSchedules();
        if (pending >= NotificationIds.maxPendingNotifications) {
          rkTrace('scheduler._reconcile hit pending cap');
          break;
        }
      }
      final success = item.asAlarm
          ? await _scheduleAlarm(item)
          : await _scheduleNotification(
              item,
              channelId: channelId,
              channelName: channelName,
              includeActions: includeActions,
            );
      if (success && !alreadyTracked) {
        await _dbService.insertSchedule(
          ReminderScheduleRecord(
            todoId: todoId,
            notificationId: item.notificationId,
            triggerTime: item.triggerTime,
            type: type,
          ),
        );
      }
    }
  }

  Future<bool> _scheduleNotification(
    _DesiredReminder item, {
    required String channelId,
    required String channelName,
    required bool includeActions,
  }) async {
    await _alarmService.cancelAlarm(item.notificationId);
    return _notifService.scheduleReminder(
      notificationId: item.notificationId,
      title: item.title,
      body: item.body,
      scheduledTime: item.triggerTime,
      payload: item.payload,
      isUrgent: item.isUrgent,
      includeActions: includeActions,
      channelId: channelId,
      channelName: channelName,
    );
  }

  Future<bool> _scheduleAlarm(_DesiredReminder item) async {
    await _notifService.cancelNotification(item.notificationId);
    return _alarmService.scheduleAlarm(
      AlarmScheduleRequest(
        requestCode: item.notificationId,
        triggerTime: item.triggerTime,
        todoId: item.payload,
        title: item.title,
        notes: item.body,
        scheduledTime: item.triggerTime,
      ),
    );
  }

  Future<void> _cancelId(int id) async {
    await _notifService.cancelNotification(id);
    await _alarmService.cancelAlarm(id);
  }

  Future<DateTime?> scheduleTodo(TodoItem todo, {DateTime? nowTime}) =>
      syncTodo(todo, nowTime: nowTime);

  Future<void> cancelTodo(String todoId) async {
    rkTrace('scheduler.cancelTodo $todoId');
    final records = await _dbService.deleteSchedulesForTodo(todoId);
    for (final record in records) {
      await _cancelId(record.notificationId);
    }
    await _cancelId(NotificationIds.generateStableNotificationId(todoId));
    await _cancelId(NotificationIds.generatePersistentNotificationId(todoId));
    await _alarmService.cancelAlarmsForTodo(todoId);
  }

  Future<void> cancelTodoReminder(TodoItem todo) => cancelTodo(todo.id);

  Future<void> scheduleDailySummary({DateTime? nowTime}) async {
    final now = nowTime ?? DateTime.now();
    rkTrace('scheduler.scheduleDailySummary');
    final enabledStr = await _dbService.getSetting('daily_summary_enabled');
    final isEnabled = enabledStr != 'false';

    if (!isEnabled) {
      await _cancelDailySummary();
      return;
    }

    final timeStr =
        await _dbService.getSetting('daily_summary_time') ?? '09:00';
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    scheduled = _minute(scheduled);

    final todos = await _dbService.getAllTodos();
    final uncompleted = todos.where((t) => !t.isCompleted).toList();
    final overdue = uncompleted.where((t) => t.isOverdue(now)).length;

    if (uncompleted.isEmpty) {
      await _cancelDailySummary();
      return;
    }

    await _reconcile(
      todoId: null,
      type: ReminderScheduleRecord.typeDailySummary,
      desired: [
        _DesiredReminder(
          notificationId: NotificationIds.dailySummaryId,
          triggerTime: scheduled,
          title: '提醒Kath 每日待辦總整理',
          body: '您有 ${uncompleted.length} 項未完成待辦（含 $overdue 項已逾期）',
          isUrgent: false,
          payload: 'daily_summary',
        ),
      ],
      channelId: NotificationIds.channelIdDaily,
      channelName: NotificationIds.channelNameDaily,
      includeActions: false,
    );
  }

  Future<void> _cancelDailySummary() async {
    final records = await _dbService.deleteSchedulesOfType(
      ReminderScheduleRecord.typeDailySummary,
    );
    for (final record in records) {
      await _cancelId(record.notificationId);
    }
    await _cancelId(NotificationIds.dailySummaryId);
  }

  Future<int> syncAllReminders({DateTime? nowTime}) async {
    final now = nowTime ?? DateTime.now();
    rkTrace('scheduler.syncAllReminders start');
    final expired = await _dbService.deleteExpiredSchedules(
      now.subtract(const Duration(days: 1)),
    );
    for (final record in expired) {
      await _cancelId(record.notificationId);
    }

    final todos = await _dbService.getAllTodos();
    int scheduledCount = 0;
    for (final todo in todos) {
      if (todo.isCompleted) {
        await cancelTodo(todo.id);
        continue;
      }
      final scheduled = await syncTodo(todo, nowTime: now);
      if (scheduled != null) {
        scheduledCount++;
      }
    }

    await scheduleDailySummary(nowTime: now);
    rkTrace('scheduler.syncAllReminders done count=$scheduledCount');
    return scheduledCount;
  }

  Future<void> handleNotificationAction(String actionId, String todoId) async {
    rkTrace('scheduler.handleNotificationAction $actionId $todoId');
    if (actionId.isEmpty || todoId.isEmpty || todoId == 'daily_summary') {
      return;
    }

    TodoItem? todo;
    try {
      todo = await _dbService.getTodoById(todoId);
    } catch (e) {
      rkTrace('scheduler.handleNotificationAction db unavailable: $e');
      return;
    }
    if (todo == null) return;

    final now = DateTime.now();

    try {
      switch (actionId) {
        case 'action_complete':
        case NotificationIds.actionComplete:
          final updated = todo.copyWith(
            isCompleted: true,
            completedAt: now,
            nextReminderTime: null,
            snoozeUntil: null,
          );
          await _dbService.updateTodo(updated);
          await cancelTodo(todoId);
          break;

        case 'action_snooze_30m':
        case NotificationIds.actionSnooze30:
          await _applySnooze(todo, now.add(const Duration(minutes: 30)));
          break;

        case 'action_snooze_1h':
        case NotificationIds.actionSnooze60:
          await _applySnooze(todo, now.add(const Duration(hours: 1)));
          break;

        case 'action_snooze_3h':
        case NotificationIds.actionSnooze180:
          await _applySnooze(todo, now.add(const Duration(hours: 3)));
          break;

        case 'action_tomorrow':
        case NotificationIds.actionSnoozeTomorrow:
          final tomorrow = now.add(const Duration(days: 1));
          final tomorrowDate = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
          );
          final tomorrowReminder = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            9,
            0,
          );
          final updated = todo.copyWith(
            scheduledDate: tomorrowDate,
            reminderTime: tomorrowReminder,
            nextReminderTime: tomorrowReminder,
            snoozeUntil: null,
          );
          await _dbService.updateTodo(updated);
          await cancelTodo(todoId);
          await syncTodo(updated, nowTime: now);
          break;
      }
    } catch (e) {
      rkTrace('scheduler.handleNotificationAction failed: $e');
    }
  }

  Future<void> _applySnooze(TodoItem todo, DateTime snoozeTime) async {
    final stamped = _minute(snoozeTime);
    final updated = todo.copyWith(
      snoozeUntil: stamped,
      nextReminderTime: stamped,
    );
    await _dbService.updateTodo(updated);
    await cancelTodo(todo.id);
    await syncTodo(updated);
  }
}

class _DesiredReminder {
  final int notificationId;
  final DateTime triggerTime;
  final String title;
  final String body;
  final bool isUrgent;
  final String payload;
  final bool asAlarm;

  const _DesiredReminder({
    required this.notificationId,
    required this.triggerTime,
    required this.title,
    required this.body,
    required this.isUrgent,
    required this.payload,
    this.asAlarm = false,
  });
}
