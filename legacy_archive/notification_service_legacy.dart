import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelIdReminders = 'capsule_reminders';
  static const String channelNameReminders = 'Capsule Reminders';
  static const String channelDescReminders = '待辦事項與靈感提醒通知';

  static const String channelIdDailySummary = 'capsule_daily_summary';
  static const String channelNameDailySummary = 'Capsule Daily Summary';
  static const String channelDescDailySummary = '每日未完成待辦總整理';

  // 回調函數：點擊通知或動作按鈕
  Function(String? payload, String? actionId)? onNotificationAction;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone init error: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
              'Notification clicked: ${response.payload}, action: ${response.actionId}');
          onNotificationAction?.call(response.payload, response.actionId);
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Local notifications init error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidPlatform =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        await androidPlatform.requestExactAlarmsPermission();
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('Request permission error: $e');
    }
    return true;
  }

  int _generateNotificationId(String todoId, [int offset = 0]) {
    return (todoId.hashCode.abs() % 100000) + offset;
  }

  Future<void> scheduleTodoReminder(TodoModel todo) async {
    if (!todo.isReminderEnabled || todo.isCompleted) return;
    final scheduledDate = todo.snoozeUntil ?? todo.reminderTime ?? todo.dueDate;

    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final notifId = _generateNotificationId(todo.id);

    try {
      final androidDetails = AndroidNotificationDetails(
        channelIdReminders,
        channelNameReminders,
        channelDescription: channelDescReminders,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Capsule Reminder',
        actions: const [
          AndroidNotificationAction('ACTION_COMPLETE', '完成',
              showsUserInterface: true),
          AndroidNotificationAction('ACTION_SNOOZE_30', '稍後 30 分鐘',
              showsUserInterface: false),
        ],
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      if (todo.repeatRule == TodoRepeatRule.none) {
        await _notificationsPlugin.zonedSchedule(
          notifId,
          '📌 ${todo.title}',
          todo.description.isNotEmpty ? todo.description : '待辦事項提醒',
          tzDateTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: todo.id,
        );
      } else {
        // 重複提醒排程
        DateTimeComponents? matchComponents;
        if (todo.repeatRule == TodoRepeatRule.daily) {
          matchComponents = DateTimeComponents.time;
        } else if (todo.repeatRule == TodoRepeatRule.weekly) {
          matchComponents = DateTimeComponents.dayOfWeekAndTime;
        } else if (todo.repeatRule == TodoRepeatRule.monthly) {
          matchComponents = DateTimeComponents.dayOfMonthAndTime;
        }

        await _notificationsPlugin.zonedSchedule(
          notifId,
          '🔁 ${todo.title}',
          todo.description.isNotEmpty ? todo.description : '重複待辦提醒',
          tzDateTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
          payload: todo.id,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule notification for todo ${todo.id}: $e');
    }
  }

  Future<void> cancelReminder(String todoId) async {
    final notifId = _generateNotificationId(todoId);
    try {
      await _notificationsPlugin.cancel(notifId);
      // 同時取消可能的稍後提醒或持續提醒 ID
      await _notificationsPlugin.cancel(notifId + 1);
    } catch (e) {
      debugPrint('Failed to cancel reminder $todoId: $e');
    }
  }

  Future<void> scheduleDailyDigestSummary(
      int pendingCount, int overdueCount) async {
    const summaryId = 999999;
    try {
      if (pendingCount == 0 && overdueCount == 0) {
        await _notificationsPlugin.cancel(summaryId);
        return;
      }

      final now = DateTime.now();
      var scheduledTime =
          DateTime(now.year, now.month, now.day, 20, 0); // 每天晚上 20:00
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      final androidDetails = const AndroidNotificationDetails(
        channelIdDailySummary,
        channelNameDailySummary,
        channelDescription: channelDescDailySummary,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      String content = '今日尚有 $pendingCount 則未完成待辦';
      if (overdueCount > 0) {
        content += '，其中 $overdueCount 則已逾期';
      }

      await _notificationsPlugin.zonedSchedule(
        summaryId,
        '📋 今日待辦總整理',
        content,
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'DAILY_DIGEST',
      );
    } catch (e) {
      debugPrint('Failed to schedule daily summary: $e');
    }
  }
}
