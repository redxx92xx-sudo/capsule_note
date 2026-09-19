import '../l10n/app_strings.dart';

enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  customWeekdays;

  String get displayName {
    switch (this) {
      case RepeatType.none:
        return '不重複';
      case RepeatType.daily:
        return '每天';
      case RepeatType.weekly:
        return '每週';
      case RepeatType.monthly:
        return '每月';
      case RepeatType.customWeekdays:
        return '自訂星期';
    }
  }

  String localizedName(AppStrings s) {
    switch (this) {
      case RepeatType.none:
        return s.repeatNone;
      case RepeatType.daily:
        return s.repeatDaily;
      case RepeatType.weekly:
        return s.repeatWeekly;
      case RepeatType.monthly:
        return s.repeatMonthly;
      case RepeatType.customWeekdays:
        return s.repeatCustomWeekdays;
    }
  }

  static RepeatType fromString(String value) {
    return RepeatType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RepeatType.none,
    );
  }
}

class RepeatRuleHelper {
  /// 計算在 [fromTime] 之後的下一次有效提醒時間
  static DateTime? calculateNextReminder({
    required DateTime fromTime,
    required DateTime scheduledDate,
    required DateTime? baseReminderTime,
    required RepeatType repeatType,
    required List<int> repeatDays, // 1 = Monday, 7 = Sunday
  }) {
    if (repeatType == RepeatType.none) {
      if (baseReminderTime == null) return null;
      return baseReminderTime.isAfter(fromTime) ? baseReminderTime : null;
    }

    final int targetHour = baseReminderTime?.hour ?? 9;
    final int targetMinute = baseReminderTime?.minute ?? 0;
    final int targetSecond = baseReminderTime?.second ?? 0;

    DateTime candidate;

    switch (repeatType) {
      case RepeatType.none:
        return null;

      case RepeatType.daily:
        candidate = DateTime(
          fromTime.year,
          fromTime.month,
          fromTime.day,
          targetHour,
          targetMinute,
          targetSecond,
        );
        if (candidate.isAfter(fromTime)) {
          return candidate;
        }
        return candidate.add(const Duration(days: 1));

      case RepeatType.weekly:
        final int targetWeekday = scheduledDate.weekday;
        int daysUntil = (targetWeekday - fromTime.weekday + 7) % 7;
        candidate = DateTime(
          fromTime.year,
          fromTime.month,
          fromTime.day + daysUntil,
          targetHour,
          targetMinute,
          targetSecond,
        );
        if (candidate.isAfter(fromTime)) {
          return candidate;
        }
        return candidate.add(const Duration(days: 7));

      case RepeatType.monthly:
        int targetDay = scheduledDate.day;
        int year = fromTime.year;
        int month = fromTime.month;

        int daysInCurrentMonth = _daysInMonth(year, month);
        int clampedDay = targetDay > daysInCurrentMonth
            ? daysInCurrentMonth
            : targetDay;

        candidate = DateTime(
          year,
          month,
          clampedDay,
          targetHour,
          targetMinute,
          targetSecond,
        );
        if (candidate.isAfter(fromTime)) {
          return candidate;
        }

        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
        int daysInNextMonth = _daysInMonth(year, month);
        clampedDay = targetDay > daysInNextMonth ? daysInNextMonth : targetDay;
        return DateTime(
          year,
          month,
          clampedDay,
          targetHour,
          targetMinute,
          targetSecond,
        );

      case RepeatType.customWeekdays:
        if (repeatDays.isEmpty) return null;
        final sortedDays = List<int>.from(repeatDays)..sort();

        for (int i = 0; i <= 14; i++) {
          final checkDate = fromTime.add(Duration(days: i));
          if (sortedDays.contains(checkDate.weekday)) {
            candidate = DateTime(
              checkDate.year,
              checkDate.month,
              checkDate.day,
              targetHour,
              targetMinute,
              targetSecond,
            );
            if (candidate.isAfter(fromTime)) {
              return candidate;
            }
          }
        }
        return null;
    }
  }

  static int _daysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  static String formatRepeatDays(List<int> days) {
    if (days.isEmpty) return '無';
    if (days.length == 7) return '每天';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return '工作日 (週一至週五)';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return '週末 (週六、週日)';
    }
    const weekdayNames = ['', '一', '二', '三', '四', '五', '六', '日'];
    return days.map((d) => '週${weekdayNames[d]}').join('、');
  }
}
