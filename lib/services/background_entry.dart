import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../utils/rk_trace.dart';
import 'alarm_port.dart';
import 'android_alarm_scheduler.dart';
import 'app_timezone.dart';
import 'database_service.dart';
import 'notification_port.dart';
import 'notification_service.dart';
import 'reminder_scheduler.dart';

const MethodChannel kBackgroundChannel = MethodChannel(
  'com.capsulenote.app/bg',
);

Future<void> runBackgroundIsolateWork(Future<void> Function() work) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    AppTimezone.ensureDatabase();
    String deviceZone = AppTimezone.fallback;
    try {
      deviceZone = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 3),
        onTimeout: () => AppTimezone.fallback,
      );
    } catch (_) {}
    AppTimezone.applyNamed(deviceZone);

    final notifications = NotificationService();
    NotificationPort.instance = notifications;
    await notifications.initialize();
    if (!AlarmPort.isConfigured) {
      AlarmPort.instance = AndroidAlarmScheduler();
    }
    await DatabaseService.instance.database;
    await work();
  } catch (e) {
    debugPrint('background isolate failed: $e');
    rkTrace('background isolate failed: $e');
  } finally {
    try {
      await kBackgroundChannel.invokeMethod('resyncFinished');
    } catch (_) {}
  }
}

/// 背景通知動作（完成／稍後／明天）。必須是 top-level + vm:entry-point。
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) async {
  await runBackgroundIsolateWork(() async {
    final actionId = response.actionId;
    final payload = response.payload;
    if (actionId == null ||
        actionId.isEmpty ||
        payload == null ||
        payload.isEmpty ||
        payload == 'daily_summary') {
      return;
    }
    await ReminderScheduler.instance.handleNotificationAction(
      actionId,
      payload,
    );
  });
}

/// 開機、時區或系統時間改變後的背景核對。
@pragma('vm:entry-point')
void backgroundResyncCallback() async {
  await runBackgroundIsolateWork(() async {
    await ReminderScheduler.instance.syncAllReminders();
  });
}

Future<void> registerBackgroundResyncCallback() async {
  try {
    final handle = PluginUtilities.getCallbackHandle(backgroundResyncCallback);
    if (handle == null) return;
    await kBackgroundChannel.invokeMethod(
      'saveResyncHandle',
      handle.toRawHandle(),
    );
  } catch (e) {
    debugPrint('registerBackgroundResyncCallback failed: $e');
  }
}

Future<void> processPendingAlarmActions() async {
  if (!AlarmPort.isConfigured) return;
  try {
    final pending = await AlarmPort.instance.drainPendingActions();
    for (final item in pending) {
      await ReminderScheduler.instance.handleNotificationAction(
        item.actionId,
        item.todoId,
      );
    }
  } catch (e) {
    debugPrint('processPendingAlarmActions failed: $e');
    rkTrace('processPendingAlarmActions failed: $e');
  }
}

/// 原生鬧鐘畫面「完成／稍後」後，由原生啟動 Dart isolate 寫入 SQLite。
@pragma('vm:entry-point')
void backgroundAlarmActionCallback() async {
  await runBackgroundIsolateWork(() async {
    await processPendingAlarmActions();
  });
}

Future<void> registerBackgroundAlarmActionCallback() async {
  try {
    final handle = PluginUtilities.getCallbackHandle(
      backgroundAlarmActionCallback,
    );
    if (handle == null) return;
    await kBackgroundChannel.invokeMethod(
      'saveAlarmActionHandle',
      handle.toRawHandle(),
    );
  } catch (e) {
    debugPrint('registerBackgroundAlarmActionCallback failed: $e');
  }
}
