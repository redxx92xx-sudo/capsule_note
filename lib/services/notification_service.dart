import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_strings_delegate.dart';
import '../theme/app_theme.dart';
import '../utils/rk_trace.dart';
import 'app_timezone.dart';
import 'background_entry.dart';
import 'notification_port.dart';

class NotificationService implements INotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool? _exactAlarmsAllowed;
  bool lastScheduleUsedExact = true;

  static bool get _isWidgetTestBinding {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('TestWidgetsFlutterBinding');
  }

  @override
  Future<void> initialize({
    NotificationActionCallback? onNotificationAction,
  }) async {
    if (_isInitialized) return;

    if (_isWidgetTestBinding) {
      rkTrace('NotificationService.initialize skipped (test binding)');
      _isInitialized = true;
      return;
    }

    try {
      AppTimezone.ensureDatabase();
      String timeZoneName = AppTimezone.fallback;
      try {
        rkTrace('NotificationService.initialize await FlutterTimezone.getLocalTimezone');
        timeZoneName = await FlutterTimezone.getLocalTimezone().timeout(
          const Duration(seconds: 3),
          onTimeout: () => AppTimezone.fallback,
        );
      } catch (tzErr) {
        debugPrint('時區自動偵測警告：$tzErr');
      }
      final applied = AppTimezone.applyNamed(timeZoneName);
      debugPrint('已設定裝置時區: $applied');
    } catch (e) {
      debugPrint('時區資料庫初始化警告：$e');
      AppTimezone.applyNamed(AppTimezone.fallback);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(NotificationIds.androidSmallIcon);
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      rkTrace('NotificationService.initialize await plugin.initialize');
      await _plugin
          .initialize(
            initSettings,
            onDidReceiveNotificationResponse: (response) {
              onNotificationAction?.call(response.actionId, response.payload);
            },
            onDidReceiveBackgroundNotificationResponse:
                onBackgroundNotificationAction,
          )
          .timeout(const Duration(seconds: 8));
      await _ensureAndroidChannels();
      _isInitialized = true;
      rkTrace('NotificationService.initialize done tz=${AppTimezone.currentIanaName}');
    } catch (e) {
      rkTrace('NotificationService.initialize FAILED/TIMEOUT: $e');
      debugPrint('通知外掛初始化錯誤：$e');
    }
  }

  Future<void> _ensureAndroidChannels() async {
    if (!Platform.isAndroid) return;
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;
    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationIds.channelIdDefault,
        NotificationIds.channelNameDefault,
        description: NotificationIds.channelDescDefault,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationIds.channelIdDaily,
        NotificationIds.channelNameDaily,
        description: NotificationIds.channelDescDaily,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    String? channelDescription,
    bool isUrgent = false,
    bool includeActions = false,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      icon: NotificationIds.androidSmallIcon,
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: channelName,
      color: AppColors.light.accent,
      actions: includeActions ? _actions : const <AndroidNotificationAction>[],
    );
  }

  Future<String> refreshDeviceTimezone() async {
    AppTimezone.ensureDatabase();
    String timeZoneName = AppTimezone.fallback;
    try {
      timeZoneName = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 3),
        onTimeout: () => AppTimezone.fallback,
      );
    } catch (_) {}
    return AppTimezone.applyNamed(timeZoneName);
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) {
      _exactAlarmsAllowed = true;
      return true;
    }
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final allowed = await androidImpl?.canScheduleExactNotifications();
      _exactAlarmsAllowed = allowed ?? false;
    } catch (e) {
      debugPrint('檢查精確鬧鐘權限失敗：$e');
      _exactAlarmsAllowed = false;
    }
    return _exactAlarmsAllowed!;
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_isInitialized || !Platform.isAndroid) return true;
    try {
      rkTrace('NotificationService.requestPermissions');
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission().timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );
        try {
          await androidImpl.requestExactAlarmsPermission().timeout(
            const Duration(seconds: 5),
          );
        } catch (e) {
          debugPrint('精確鬧鐘權限請求忽略或降級：$e');
        }
        _exactAlarmsAllowed = null;
        await canScheduleExactAlarms();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('請求權限例外：$e');
    }
    return false;
  }

  List<AndroidNotificationAction> get _actions {
    final s = AppLocaleHolder.strings;
    return [
      AndroidNotificationAction(
        NotificationIds.actionComplete,
        s.complete,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationIds.actionSnooze30,
        s.snooze30,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationIds.actionSnooze60,
        s.snooze60,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationIds.actionSnooze180,
        s.snooze180,
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationIds.actionSnoozeTomorrow,
        s.snoozeTomorrow,
        showsUserInterface: false,
      ),
    ];
  }

  @override
  Future<bool> scheduleReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool isUrgent = false,
    bool includeActions = true,
    String channelId = NotificationIds.channelIdDefault,
    String channelName = NotificationIds.channelNameDefault,
  }) async {
    if (!_isInitialized) return false;

    try {
      rkTrace('NotificationService.scheduleReminder id=$notificationId');
      final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);
      if (!tzScheduled.isAfter(tz.TZDateTime.now(tz.local))) {
        return false;
      }

      final exact = await canScheduleExactAlarms();
      lastScheduleUsedExact = exact;

      final NotificationDetails details = NotificationDetails(
        android: _androidDetails(
          channelId: channelId,
          channelName: channelName,
          channelDescription: channelId == NotificationIds.channelIdDaily
              ? NotificationIds.channelDescDaily
              : NotificationIds.channelDescDefault,
          isUrgent: isUrgent,
          includeActions: includeActions,
        ),
      );

      Future<void> zoned(AndroidScheduleMode mode) {
        return _plugin
            .zonedSchedule(
              notificationId,
              title,
              body,
              tzScheduled,
              details,
              androidScheduleMode: mode,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: payload,
            )
            .timeout(const Duration(seconds: 5));
      }

      try {
        await zoned(
          exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (exactError) {
        debugPrint('精確鬧鐘排程降級為非精確模式：$exactError');
        lastScheduleUsedExact = false;
        await zoned(AndroidScheduleMode.inexactAllowWhileIdle);
      }
      return true;
    } catch (e) {
      debugPrint('排程通知失敗：$e');
      return false;
    }
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = NotificationIds.channelIdDefault,
    String channelName = NotificationIds.channelNameDefault,
  }) async {
    if (!_isInitialized) return;
    try {
      rkTrace('NotificationService.showNotification await plugin.show');
      final NotificationDetails details = NotificationDetails(
        android: _androidDetails(
          channelId: channelId,
          channelName: channelName,
          channelDescription: channelId == NotificationIds.channelIdDaily
              ? NotificationIds.channelDescDaily
              : NotificationIds.channelDescDefault,
          isUrgent: true,
          includeActions: true,
        ),
      );
      await _plugin
          .show(id, title, body, details, payload: payload)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('顯示即時通知失敗：$e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    try {
      rkTrace('NotificationService.cancelNotification await plugin.cancel id=$id');
      await _plugin.cancel(id).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('取消通知失敗 (ID: $id)：$e');
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    try {
      rkTrace('NotificationService.cancelAll await plugin.cancelAll');
      await _plugin.cancelAll().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('取消全部通知失敗：$e');
    }
  }
}
