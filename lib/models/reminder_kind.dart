import '../l10n/app_strings.dart';

enum ReminderKind {
  notification,
  alarm;

  String get storageValue => name;

  String get displayName {
    switch (this) {
      case ReminderKind.notification:
        return '一般通知';
      case ReminderKind.alarm:
        return '鬧鐘模式';
    }
  }

  String localizedName(AppStrings s) {
    switch (this) {
      case ReminderKind.notification:
        return s.notificationKind;
      case ReminderKind.alarm:
        return s.alarmKind;
    }
  }

  bool get isAlarm => this == ReminderKind.alarm;

  static ReminderKind fromStorage(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    if (raw == ReminderKind.alarm.storageValue) {
      return ReminderKind.alarm;
    }
    return ReminderKind.notification;
  }
}
