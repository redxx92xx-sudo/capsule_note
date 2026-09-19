/// Plugin-free notification contract so tests never import
/// flutter_local_notifications / flutter_timezone / timezone data.
typedef NotificationActionCallback = void Function(
  String? actionId,
  String? payload,
);

abstract class INotificationService {
  Future<void> initialize({NotificationActionCallback? onNotificationAction});
  Future<bool> requestPermissions();
  Future<bool> canScheduleExactAlarms();
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
  });
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = NotificationIds.channelIdDefault,
    String channelName = NotificationIds.channelNameDefault,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAll();
}

class NotificationPort {
  static INotificationService? _instance;

  static INotificationService get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'NotificationPort.instance 尚未設定。測試必須注入 Fake，正式 App 必須在 main() 註冊真實服務。',
      );
    }
    return current;
  }

  static set instance(INotificationService service) {
    _instance = service;
  }

  static bool get isConfigured => _instance != null;

  static void reset() {
    _instance = null;
  }
}

class NotificationIds {
  static const String channelIdDefault = 'capsule_note_tasks';
  static const String channelNameDefault = '待辦事項提醒';
  static const String channelDescDefault = '發送已排定的待辦事項提醒與鬧鐘';

  /// Drawable resource name (not mipmap). Android status-bar icons must be
  /// a white alpha mask; @mipmap/ic_launcher is a full-color launcher image.
  static const String androidSmallIcon = 'ic_stat_notify';

  static const String channelIdDaily = 'capsule_note_daily';
  static const String channelNameDaily = '每日待辦總整理';
  static const String channelDescDaily = '每日固定時間整理未完成與逾期待辦事項';

  static const String actionComplete = 'ACTION_COMPLETE';
  static const String actionSnooze30 = 'ACTION_SNOOZE_30';
  static const String actionSnooze60 = 'ACTION_SNOOZE_60';
  static const String actionSnooze180 = 'ACTION_SNOOZE_180';
  static const String actionSnoozeTomorrow = 'ACTION_SNOOZE_TOMORROW';

  static int generateStableNotificationId(String uniqueId) {
    var hash = 0xcbf29ce484222325;
    for (var i = 0; i < uniqueId.length; i++) {
      hash ^= uniqueId.codeUnitAt(i);
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return (hash & 0x3FFFFFFF);
  }

  static int generatePersistentNotificationId(String uniqueId, [int slot = 0]) {
    if (slot <= 0) {
      return generateStableNotificationId(uniqueId) | 0x40000000;
    }
    return generateStableNotificationId('$uniqueId#p$slot') | 0x40000000;
  }

  static const int dailySummaryId = 88888;
  static const int maxPendingNotifications = 80;
}
