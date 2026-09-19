import 'package:capsule_note/services/notification_port.dart';

/// In-memory notification fake. Never touches a MethodChannel.
class FakeNotificationService implements INotificationService {
  final Map<int, Map<String, dynamic>> scheduledReminders = {};
  final List<int> cancelledIds = [];
  final List<Map<String, dynamic>> shownNotifications = [];
  bool permissionsGranted = true;
  bool exactAlarmsGranted = true;
  bool initialized = false;
  bool lastScheduleUsedExact = true;

  @override
  Future<void> initialize({
    NotificationActionCallback? onNotificationAction,
  }) async {
    initialized = true;
  }

  @override
  Future<bool> canScheduleExactAlarms() async => exactAlarmsGranted;

  @override
  Future<bool> requestPermissions() async => permissionsGranted;

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
    lastScheduleUsedExact = exactAlarmsGranted;
    scheduledReminders[notificationId] = {
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
      'payload': payload,
      'isUrgent': isUrgent,
      'includeActions': includeActions,
      'channelId': channelId,
      'channelName': channelName,
      'usedExact': exactAlarmsGranted,
    };
    return true;
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
    shownNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  @override
  Future<void> cancelNotification(int id) async {
    scheduledReminders.remove(id);
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduledReminders.clear();
  }
}
