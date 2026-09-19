import 'package:flutter/material.dart';

/// App locale preference stored in settings. `system` follows device language.
class AppLocaleOption {
  static const system = 'system';
  static const zhTW = 'zh_TW';
  static const zhCN = 'zh_CN';
  static const en = 'en';

  static const all = [system, zhTW, zhCN, en];

  static Locale? toLocale(String preference) {
    switch (preference) {
      case zhTW:
        return const Locale('zh', 'TW');
      case zhCN:
        return const Locale('zh', 'CN');
      case en:
        return const Locale('en');
      default:
        return null; // follow system
    }
  }

  /// Resolve effective locale: unsupported system languages fall back to English.
  static Locale resolve(Locale? preferred, List<Locale> systemLocales) {
    if (preferred != null) return preferred;
    for (final locale in systemLocales) {
      if (locale.languageCode == 'zh') {
        final script = locale.scriptCode?.toLowerCase();
        final country = locale.countryCode?.toUpperCase();
        if (script == 'hant' ||
            country == 'TW' ||
            country == 'HK' ||
            country == 'MO') {
          return const Locale('zh', 'TW');
        }
        return const Locale('zh', 'CN');
      }
      if (locale.languageCode == 'en') {
        return const Locale('en');
      }
    }
    return const Locale('en');
  }

  static String storageTag(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return zhTW;
    }
    if (locale.languageCode == 'zh') return zhCN;
    return en;
  }
}

/// Centralized UI strings for zh_TW / zh_CN / en.
class AppStrings {
  AppStrings._(this.locale, this._t);

  final Locale locale;
  final Map<String, String> _t;

  String _(String key) => _t[key] ?? key;

  // App
  String get appTitle => _('appTitle');
  String get today => _('today');
  String get calendar => _('calendar');
  String get todos => _('todos');
  String get settings => _('settings');
  String get completed => _('completed');
  String get uncompleted => _('uncompleted');
  String get overdue => _('overdue');
  String get all => _('all');
  String get addTodo => _('addTodo');
  String get editTodo => _('editTodo');
  String get delete => _('delete');
  String get complete => _('complete');
  String get save => _('save');
  String get cancel => _('cancel');
  String get confirm => _('confirm');
  String get title => _('title');
  String get notes => _('notes');
  String get date => _('date');
  String get time => _('time');
  String get reminderTime => _('reminderTime');
  String get scheduledDate => _('scheduledDate');
  String get repeat => _('repeat');
  String get priority => _('priority');
  String get change => _('change');
  String get set => _('set');
  String get noReminder => _('noReminder');
  String get searchHint => _('searchHint');
  String get focusToday => _('focusToday');
  String get refresh => _('refresh');
  String get showMenu => _('showMenu');
  String get overdueSection => _('overdueSection');
  String get emptyTodos => _('emptyTodos');
  String get priorityHigh => _('priorityHigh');
  String get priorityMedium => _('priorityMedium');
  String get priorityLow => _('priorityLow');
  String get reminderKind => _('reminderKind');
  String get notificationKind => _('notificationKind');
  String get alarmKind => _('alarmKind');
  String get alarmKindHint => _('alarmKindHint');
  String get notificationKindHint => _('notificationKindHint');
  String get alarmChip => _('alarmChip');
  String get snooze30 => _('snooze30');
  String get snooze60 => _('snooze60');
  String get snooze180 => _('snooze180');
  String get snoozeTomorrow => _('snoozeTomorrow');
  String get snoozeSet30 => _('snoozeSet30');
  String get snoozeSet60 => _('snoozeSet60');
  String get snoozeSetTomorrow => _('snoozeSetTomorrow');
  String get persistentReminder => _('persistentReminder');
  String get persistentReminderHint => _('persistentReminderHint');
  String get confirmDeleteTitle => _('confirmDeleteTitle');
  String get confirmDeleteBody => _('confirmDeleteBody');
  String get settingsTitle => _('settingsTitle');
  String get backupRestore => _('backupRestore');
  String get exportBackup => _('exportBackup');
  String get exportBackupHint => _('exportBackupHint');
  String get importBackup => _('importBackup');
  String get importBackupHint => _('importBackupHint');
  String get importConfirm => _('importConfirm');
  String get exportSuccess => _('exportSuccess');
  String get importSuccess => _('importSuccess');
  String get importFailed => _('importFailed');
  String get importCancelled => _('importCancelled');
  String get appearance => _('appearance');
  String get darkMode => _('darkMode');
  String get language => _('language');
  String get languageSystem => _('languageSystem');
  String get languageZhTW => _('languageZhTW');
  String get languageZhCN => _('languageZhCN');
  String get languageEn => _('languageEn');
  String get languageHint => _('languageHint');
  String get alarmManagement => _('alarmManagement');
  String get exactAlarmGranted => _('exactAlarmGranted');
  String get exactAlarmDenied => _('exactAlarmDenied');
  String get exactAlarmGrantedHint => _('exactAlarmGrantedHint');
  String get exactAlarmDeniedHint => _('exactAlarmDeniedHint');
  String get fullScreenGranted => _('fullScreenGranted');
  String get fullScreenDenied => _('fullScreenDenied');
  String get fullScreenGrantedHint => _('fullScreenGrantedHint');
  String get fullScreenDeniedHint => _('fullScreenDeniedHint');
  String get openSettings => _('openSettings');
  String get checkPermissions => _('checkPermissions');
  String get checkPermissionsHint => _('checkPermissionsHint');
  String get permissionsOk => _('permissionsOk');
  String get permissionsPartial => _('permissionsPartial');
  String get resyncSchedules => _('resyncSchedules');
  String get resyncSchedulesHint => _('resyncSchedulesHint');
  String get resyncDone => _('resyncDone');
  String get testNotification => _('testNotification');
  String get testNotificationHint => _('testNotificationHint');
  String get testNotificationSent => _('testNotificationSent');
  String get testNotificationTitle => _('testNotificationTitle');
  String get testNotificationBody => _('testNotificationBody');
  String get testAlarm => _('testAlarm');
  String get testAlarmHint => _('testAlarmHint');
  String get testAlarmScheduled => _('testAlarmScheduled');
  String get dailySummary => _('dailySummary');
  String get dailySummaryHint => _('dailySummaryHint');
  String get dailySummaryNote => _('dailySummaryNote');
  String get dailySummaryTime => _('dailySummaryTime');
  String get dailySummaryStatus => _('dailySummaryStatus');
  String get about => _('about');
  String get aboutBody => _('aboutBody');
  String get alarmScreenTitle => _('alarmScreenTitle');
  String get alarmDefaultBody => _('alarmDefaultBody');
  String get alarmExtraCount => _('alarmExtraCount');
  String get alarmStayHint => _('alarmStayHint');
  String get alarmChannelName => _('alarmChannelName');
  String get alarmChannelDesc => _('alarmChannelDesc');
  String get taskChannelName => _('taskChannelName');
  String get previewAlarmTitle => _('previewAlarmTitle');
  String get previewAlarmNotes => _('previewAlarmNotes');
  String get repeatNone => _('repeatNone');
  String get repeatDaily => _('repeatDaily');
  String get repeatWeekly => _('repeatWeekly');
  String get repeatMonthly => _('repeatMonthly');
  String get inputTitleHint => _('inputTitleHint');
  String get inputNotesHint => _('inputNotesHint');


  String get systemReminders => _('systemReminders');
  String get dataSection => _('dataSection');
  String get appearanceLanguage => _('appearanceLanguage');
  String get aboutSection => _('aboutSection');
  String get notifications => _('notifications');
  String get alarmsAndReminders => _('alarmsAndReminders');
  String get fullScreenReminder => _('fullScreenReminder');
  String get batteryBackground => _('batteryBackground');
  String get enabled => _('enabled');
  String get disabled => _('disabled');
  String get needsSetup => _('needsSetup');
  String get gotIt => _('gotIt');
  String get restore => _('restore');
  String get theme => _('theme');
  String get themeLight => _('themeLight');
  String get themeDark => _('themeDark');
  String get themeSystem => _('themeSystem');
  String get showCompletedItems => _('showCompletedItems');
  String get noTodosToday => _('noTodosToday');
  String get noTodos => _('noTodos');
  String get noTodosFound => _('noTodosFound');
  String get noTodosForDay => _('noTodosForDay');
  String get search => _('search');
  String get moreSettings => _('moreSettings');
  String get notSet => _('notSet');
  String get pleaseEnterTitle => _('pleaseEnterTitle');
  String get reminderInterval => _('reminderInterval');
  String get defaultInterval => _('defaultInterval');
  String get daily => _('daily');
  String get markComplete => _('markComplete');
  String get markIncomplete => _('markIncomplete');
  String get snooze => _('snooze');
  String get minutes30 => _('minutes30');
  String get hour1 => _('hour1');
  String get hours3 => _('hours3');
  String get priorityUrgent => _('priorityUrgent');
  String get priorityNormal => _('priorityNormal');
  String get repeatCustomWeekdays => _('repeatCustomWeekdays');
  String get version => _('version');
  String get exportFailed => _('exportFailed');
  String get importFailedDetail => _('importFailedDetail');
  String get notificationsDeniedHint => _('notificationsDeniedHint');
  String get batteryBackgroundHint => _('batteryBackgroundHint');
  String get languageFollowsSystem => _('languageFollowsSystem');
  String get weekdaySun => _('weekdaySun');
  String get weekdayMon => _('weekdayMon');
  String get weekdayTue => _('weekdayTue');
  String get weekdayWed => _('weekdayWed');
  String get weekdayThu => _('weekdayThu');
  String get weekdayFri => _('weekdayFri');
  String get weekdaySat => _('weekdaySat');
  String get todaySummary => _('todaySummary');
  String get confirmDeleteTodo => _('confirmDeleteTodo');
  String get reminderWay => _('reminderWay');
  String get reminderWayHint => _('reminderWayHint');
  String get exportedPath => _('exportedPath');
  String get confirmDeleteNamed => _('confirmDeleteNamed');
  String get deleteTodoTitle => _('deleteTodoTitle');
  String get alarmSound => _('alarmSound');
  String get alarmSoundDefault => _('alarmSoundDefault');
  String get alarmSoundPick => _('alarmSoundPick');
  String get alarmSoundPickSystem => _('alarmSoundPickSystem');
  String get alarmSoundPickFile => _('alarmSoundPickFile');
  String get alarmSoundPreview => _('alarmSoundPreview');
  String get alarmSoundReset => _('alarmSoundReset');
  String get alarmSoundCopyFailed => _('alarmSoundCopyFailed');
  String get alarmSoundMissingHint => _('alarmSoundMissingHint');
  String get alarmSoundPreviewFailed => _('alarmSoundPreviewFailed');
  String get alarmSoundSystemInvalidHint => _('alarmSoundSystemInvalidHint');

  List<String> get shortWeekdaysSunFirst => [
        weekdaySun,
        weekdayMon,
        weekdayTue,
        weekdayWed,
        weekdayThu,
        weekdayFri,
        weekdaySat,
      ];

  /// Monday-first short labels (ISO weekday 1..7).
  List<String> get shortWeekdaysMonFirst => [
        weekdayMon,
        weekdayTue,
        weekdayWed,
        weekdayThu,
        weekdayFri,
        weekdaySat,
        weekdaySun,
      ];

  String languageLabel(String preference) {
    switch (preference) {
      case AppLocaleOption.zhTW:
        return languageZhTW;
      case AppLocaleOption.zhCN:
        return languageZhCN;
      case AppLocaleOption.en:
        return languageEn;
      default:
        return languageSystem;
    }
  }

  String intervalLabel(int minutes) {
    switch (minutes) {
      case 30:
        return minutes30;
      case 60:
        return hour1;
      case 180:
        return hours3;
      case 1440:
        return daily;
      default:
        return '$minutes';
    }
  }

  String confirmDeleteNamedMsg(String title) =>
      _('confirmDeleteNamed').replaceAll('{title}', title);

  String overdueCount(int n) => _('overdueCount').replaceAll('{n}', '$n');
  String uncompletedCount(int n) =>
      _('uncompletedCount').replaceAll('{n}', '$n');
  String completedCount(int n) => _('completedCount').replaceAll('{n}', '$n');
  String versionLabel(String v) => _('versionLabel').replaceAll('{v}', v);
  String dailySummaryEveryDay(String time) =>
      _('dailySummaryEveryDay').replaceAll('{time}', time);
  String dailySummaryCounts(int u, int o) => _('dailySummaryCounts')
      .replaceAll('{u}', '$u')
      .replaceAll('{o}', '$o');
  String alarmExtra(int n) => _('alarmExtra').replaceAll('{n}', '$n');
  String timezoneExactHint(String tz) =>
      _('timezoneExactHint').replaceAll('{tz}', tz);
  String todaySummaryCounts(int u, int c) => _('todaySummary')
      .replaceAll('{u}', '$u')
      .replaceAll('{c}', '$c');
  String exportedPathMsg(String path) =>
      _('exportedPath').replaceAll('{path}', path);
  String exportFailedMsg(Object e) =>
      _('exportFailed').replaceAll('{e}', '$e');
  String importFailedMsg(Object e) =>
      _('importFailedDetail').replaceAll('{e}', '$e');

  static AppStrings of(BuildContext context) {
    final fromLocalizations = Localizations.of<AppStrings>(context, AppStrings);
    if (fromLocalizations != null) return fromLocalizations;
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_AppStringsScope>();
    return inherited?.strings ?? AppStrings.forLocale(const Locale('en'));
  }

  static AppStrings forLocale(Locale locale) {
    final tag = AppLocaleOption.storageTag(locale);
    switch (tag) {
      case AppLocaleOption.zhTW:
        return AppStrings._(locale, _zhTW);
      case AppLocaleOption.zhCN:
        return AppStrings._(locale, _zhCN);
      default:
        return AppStrings._(const Locale('en'), _en);
    }
  }

  static const _en = <String, String>{
    'appTitle': 'Capsule Note',
    'today': 'Today',
    'calendar': 'Calendar',
    'todos': 'Todos',
    'settings': 'Settings',
    'completed': 'Completed',
    'uncompleted': 'Open',
    'overdue': 'Overdue',
    'all': 'All',
    'addTodo': 'Add todo',
    'editTodo': 'Edit todo',
    'delete': 'Delete',
    'complete': 'Complete',
    'save': 'Save',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'title': 'Title',
    'notes': 'Notes',
    'date': 'Date',
    'time': 'Time',
    'reminderTime': 'Reminder time',
    'scheduledDate': 'Scheduled date',
    'repeat': 'Repeat',
    'priority': 'Priority',
    'change': 'Change',
    'set': 'Set',
    'noReminder': 'No reminder set',
    'searchHint': 'Search todos',
    'focusToday': 'Focus on today’s todos and reminders',
    'refresh': 'Refresh',
    'showMenu': 'Show menu',
    'overdueSection': 'Overdue',
    'emptyTodos': 'No todos yet',
    'priorityHigh': 'High',
    'priorityMedium': 'Medium',
    'priorityLow': 'Low',
    'reminderKind': 'Reminder type',
    'notificationKind': 'Notification',
    'alarmKind': 'Alarm mode',
    'alarmKindHint':
        'Alarm mode needs a reminder time. It rings full-screen with vibration.',
    'notificationKindHint': 'Shows a system notification at the reminder time.',
    'alarmChip': 'Alarm',
    'snooze30': 'Snooze 30 min',
    'snooze60': 'Snooze 1 hour',
    'snooze180': 'Snooze 3 hours',
    'snoozeTomorrow': 'Tomorrow 09:00',
    'snoozeSet30': 'Snoozed for 30 minutes',
    'snoozeSet60': 'Snoozed for 1 hour',
    'snoozeSetTomorrow': 'Snoozed until tomorrow 09:00',
    'persistentReminder': 'Persistent reminder',
    'persistentReminderHint':
        'Keep reminding at the set interval while incomplete (max 6/day)',
    'confirmDeleteTitle': 'Delete todo?',
    'confirmDeleteBody': 'This cannot be undone. Related schedules will be cancelled.',
    'settingsTitle': 'Settings & backup',
    'backupRestore': 'Backup & restore',
    'exportBackup': 'Export backup',
    'exportBackupHint': 'Export all todos and settings as a JSON file',
    'importBackup': 'Import & restore',
    'importBackupHint': 'Validate format and restore todos and schedules',
    'importConfirm':
        'Import will overwrite all todos and settings and reschedule alarms. This cannot be undone. Continue?',
    'exportSuccess': 'Backup exported',
    'importSuccess': 'Backup restored',
    'importFailed': 'Restore failed',
    'importCancelled': 'Import cancelled',
    'appearance': 'Appearance',
    'darkMode': 'Dark mode',
    'language': 'Language',
    'languageSystem': 'Follow system',
    'languageZhTW': '繁體中文',
    'languageZhCN': '简体中文',
    'languageEn': 'English',
    'languageHint': 'Affects app UI and native alarm screens',
    'alarmManagement': 'Reminders & alarms',
    'exactAlarmGranted': 'Exact alarms: allowed',
    'exactAlarmDenied': 'Exact alarms: not allowed (degraded)',
    'exactAlarmGrantedHint': 'Exact alarms are allowed. Reminders will fire on time.',
    'exactAlarmDeniedHint':
        'Enable Alarms & reminders in system settings, or alarms may be delayed.',
    'fullScreenGranted': 'Full-screen alarm: allowed',
    'fullScreenDenied': 'Full-screen alarm: not allowed (degraded)',
    'fullScreenGrantedHint': 'Lock screen can show the alarm UI directly.',
    'fullScreenDeniedHint':
        'Without permission, a high-priority notification is used instead.',
    'openSettings': 'Open settings',
    'checkPermissions': 'Check & request permissions',
    'checkPermissionsHint': 'Request notification and exact-alarm permissions',
    'permissionsOk': 'Notification and exact-alarm permissions granted',
    'permissionsPartial':
        'Notifications granted; exact alarms not allowed — inexact scheduling will be used',
    'resyncSchedules': 'Resync all schedules',
    'resyncSchedulesHint': 'Rebuild all incomplete alarm schedules from the database',
    'resyncDone': 'Schedules resynced',
    'testNotification': 'Test notification',
    'testNotificationHint': 'Send a test notification',
    'testNotificationSent': 'Test notification sent',
    'testNotificationTitle': 'Remind Kath test',
    'testNotificationBody': 'Notification channel is working!',
    'testAlarm': 'Test alarm UI (45s)',
    'testAlarmHint': 'Ring via native alarm chain in 45 seconds (not saved as a todo)',
    'testAlarmScheduled': 'Test alarm scheduled in 45 seconds',
    'dailySummary': 'Daily open-item summary',
    'dailySummaryHint': 'Daily digest of incomplete and overdue counts',
    'dailySummaryNote':
        'Counts are computed on last successful sync (open app, resume, or post-reboot). Android does not guarantee Dart at notification fire time.',
    'dailySummaryTime': 'Daily summary time',
    'dailySummaryEveryDay': 'Every day at {time}',
    'dailySummaryStatus': 'Currently open / overdue',
    'dailySummaryCounts':
        '{u} open, {o} overdue. No summary is sent when nothing is open.',
    'about': 'About Remind Kath',
    'aboutBody':
        'Fully local SQLite, offline-only, no ads, no accounts, exact scheduling, persistent reminders until done.',
    'versionLabel': 'Version: {v}',
    'alarmScreenTitle': 'Alarm',
    'alarmDefaultBody': 'Alarm time reached',
    'alarmExtra': 'Plus {n} more due alarms',
    'alarmExtraCount': 'Plus more due alarms',
    'alarmStayHint': 'Back or lock will not stop the alarm. Choose Complete or Snooze.',
    'alarmChannelName': 'Alarms',
    'alarmChannelDesc': 'Todo alarm mode: full-screen ring and vibration',
    'taskChannelName': 'Todos',
    'previewAlarmTitle': 'Remind Kath test alarm',
    'previewAlarmNotes': 'Alarm mode test — choose Complete to stop.',
    'repeatNone': 'None',
    'repeatDaily': 'Daily',
    'repeatWeekly': 'Weekly',
    'repeatMonthly': 'Monthly',
    'inputTitleHint': 'Enter title',
    'inputNotesHint': 'Notes (optional)',
    'overdueCount': 'Overdue ({n})',
    'uncompletedCount': 'Open ({n})',
    'completedCount': 'Completed ({n})',
    'timezoneExactHint': 'Timezone {tz}',
    'systemReminders': 'System reminders',
    'dataSection': 'Data',
    'appearanceLanguage': 'Appearance & language',
    'aboutSection': 'About',
    'notifications': 'Notifications',
    'alarmsAndReminders': 'Alarms & reminders',
    'fullScreenReminder': 'Full-screen reminders',
    'batteryBackground': 'Battery background',
    'enabled': 'On',
    'disabled': 'Off',
    'needsSetup': 'Needs setup',
    'gotIt': 'Got it',
    'restore': 'Restore',
    'theme': 'Theme',
    'themeLight': 'Light',
    'themeDark': 'Dark',
    'themeSystem': 'Follow system',
    'showCompletedItems': 'Show completed',
    'noTodosToday': 'No todos today',
    'noTodos': 'No todos yet',
    'noTodosFound': 'No matching todos',
    'noTodosForDay': 'No todos this day',
    'search': 'Search',
    'moreSettings': 'More settings',
    'notSet': 'Not set',
    'pleaseEnterTitle': 'Please enter a title',
    'reminderInterval': 'Reminder interval',
    'defaultInterval': 'Default interval',
    'daily': 'Daily',
    'markComplete': 'Mark complete',
    'markIncomplete': 'Mark incomplete',
    'snooze': 'Snooze',
    'minutes30': '30 min',
    'hour1': '1 hour',
    'hours3': '3 hours',
    'priorityUrgent': 'Urgent',
    'priorityNormal': 'Normal',
    'repeatCustomWeekdays': 'Custom weekdays',
    'version': 'Version',
    'exportFailed': 'Export failed: {e}',
    'importFailedDetail': 'Import failed: {e}',
    'notificationsDeniedHint': 'Enable notifications in system settings to receive reminders.',
    'batteryBackgroundHint': 'Set Remind Kath as unrestricted in battery settings so background and reboot schedules keep working.',
    'languageFollowsSystem': 'Follow system',
    'weekdaySun': 'S',
    'weekdayMon': 'M',
    'weekdayTue': 'T',
    'weekdayWed': 'W',
    'weekdayThu': 'T',
    'weekdayFri': 'F',
    'weekdaySat': 'S',
    'todaySummary': '{u} open · {c} completed',
    'confirmDeleteTodo': 'Delete todo',
    'reminderWay': 'Reminder type',
    'reminderWayHint': 'Notification: status-bar alert.\nAlarm mode: full-screen ring and vibration until Complete or Snooze.',
    'exportedPath': 'Exported: {path}',
    'confirmDeleteNamed': 'Delete "{title}"?',
    'deleteTodoTitle': 'Delete todo',
    'alarmSound': 'Alarm sound',
    'alarmSoundDefault': 'Default',
    'alarmSoundPick': 'Choose audio file',
    'alarmSoundPickSystem': 'Choose system ringtone',
    'alarmSoundPickFile': 'Choose audio file',
    'alarmSoundPreview': 'Preview',
    'alarmSoundReset': 'Restore default',
    'alarmSoundCopyFailed': 'Could not copy the sound. Previous setting kept.',
    'alarmSoundMissingHint':
        'Saved alarm sound file was not found. Using the default sound — please choose again.',
    'alarmSoundPreviewFailed': 'Could not play the alarm sound.',
    'alarmSoundSystemInvalidHint':
        'Saved system ringtone is unavailable. Using the default sound — please choose again.',

  };

  static const _zhTW = <String, String>{
    'appTitle': 'Capsule Note',
    'today': '今天',
    'calendar': '月曆',
    'todos': '待辦',
    'settings': '設定',
    'completed': '已完成',
    'uncompleted': '未完成',
    'overdue': '已逾期',
    'all': '全部',
    'addTodo': '新增待辦',
    'editTodo': '編輯待辦',
    'delete': '刪除',
    'complete': '完成',
    'save': '儲存',
    'cancel': '取消',
    'confirm': '確認',
    'title': '標題',
    'notes': '備註',
    'date': '日期',
    'time': '時間',
    'reminderTime': '提醒時間',
    'scheduledDate': '排定日期',
    'repeat': '重複',
    'priority': '優先度',
    'change': '變更',
    'set': '設定',
    'noReminder': '未設定提醒 (無鬧鐘)',
    'searchHint': '搜尋待辦',
    'focusToday': '專注今天的待辦與提醒',
    'refresh': '重新整理',
    'showMenu': '顯示選單',
    'overdueSection': '已逾期事項',
    'emptyTodos': '尚無待辦事項',
    'priorityHigh': '高',
    'priorityMedium': '中',
    'priorityLow': '低',
    'reminderKind': '提醒類型',
    'notificationKind': '一般通知',
    'alarmKind': '鬧鐘模式',
    'alarmKindHint': '鬧鐘模式需要設定提醒時間，到點會全螢幕響鈴並持續震動。',
    'notificationKindHint': '到點顯示系統通知。',
    'alarmChip': '鬧鐘',
    'snooze30': '稍後30分鐘',
    'snooze60': '稍後1小時',
    'snooze180': '稍後3小時',
    'snoozeTomorrow': '明天09:00',
    'snoozeSet30': '已設定 30 分鐘後提醒',
    'snoozeSet60': '已設定 1 小時後提醒',
    'snoozeSetTomorrow': '已設定明天早上 09:00 提醒',
    'persistentReminder': '持續提醒',
    'persistentReminderHint': '未完成時依設定間隔持續提醒（每日最多6次）',
    'confirmDeleteTitle': '刪除待辦？',
    'confirmDeleteBody': '此動作無法復原，相關排程也會一併取消。',
    'settingsTitle': '設定與備份',
    'backupRestore': '備份與還原',
    'exportBackup': '匯出備份',
    'exportBackupHint': '將全部待辦事項與設定導出為 JSON 檔保存',
    'importBackup': '匯入還原',
    'importBackupHint': '檢查格式並覆蓋還原待辦資料與鬧鐘排程',
    'importConfirm': '匯入將會「覆蓋現有所有待辦事項與設定」並重新排定鬧鐘，此動作無法復原。是否繼續？',
    'exportSuccess': '備份已匯出',
    'importSuccess': '備份已還原',
    'importFailed': '還原失敗',
    'importCancelled': '已取消匯入',
    'appearance': '外觀偏好',
    'darkMode': '深色模式',
    'language': '語言',
    'languageSystem': '跟隨系統',
    'languageZhTW': '繁體中文',
    'languageZhCN': '简体中文',
    'languageEn': 'English',
    'languageHint': '同時套用至 App 介面與原生鬧鐘畫面',
    'alarmManagement': '提醒與鬧鐘管理',
    'exactAlarmGranted': '精確鬧鐘：已授權',
    'exactAlarmDenied': '精確鬧鐘：未授權（已降級）',
    'exactAlarmGrantedHint': '精確鬧鐘已授權，提醒會準時觸發。',
    'exactAlarmDeniedHint': '請開啟「鬧鐘與提醒」權限，否則可能延後。',
    'fullScreenGranted': '全螢幕鬧鐘：已授權',
    'fullScreenDenied': '全螢幕鬧鐘：未授權（已降級）',
    'fullScreenGrantedHint': '鎖定畫面可直接跳出鬧鐘畫面。',
    'fullScreenDeniedHint': '未授權時改以高優先級通知提醒，鎖定畫面可能不會自動跳出。',
    'openSettings': '開啟設定',
    'checkPermissions': '檢查與要求系統權限',
    'checkPermissionsHint': '請求發送通知與精確鬧鐘權限',
    'permissionsOk': '已取得通知與精確鬧鐘權限',
    'permissionsPartial': '已取得通知權限，精確鬧鐘未授權，將使用非精確提醒',
    'resyncSchedules': '手動全面校對排程',
    'resyncSchedulesHint': '依據目前資料庫重新排定所有未完成鬧鐘',
    'resyncDone': '已重新校對排程',
    'testNotification': '測試即時通知',
    'testNotificationHint': '發送一則測試通知以確認系統通知正常',
    'testNotificationSent': '已發送測試通知',
    'testNotificationTitle': '提醒Kath 測試通知',
    'testNotificationBody': '系統通知與頻道運作正常！',
    'testAlarm': '測試鬧鐘畫面（45秒）',
    'testAlarmHint': '以原生鬧鐘鏈路在 45 秒後響鈴，不寫入待辦資料',
    'testAlarmScheduled': '已排程 45 秒後測試鬧鐘',
    'dailySummary': '每日未完成事項總整理',
    'dailySummaryHint': '每日固定時間彙整通知未完成與逾期事項數量',
    'dailySummaryNote':
        '數量是在最近一次成功同步時計算（開啟 App、從背景返回、重開機後的背景核對）。Android 不會在通知響起當下保證執行 Dart，因此若長時間未開啟 App，摘要數字可能略為過時。',
    'dailySummaryTime': '每日整理提醒時間',
    'dailySummaryEveryDay': '每天 {time} 發送通知',
    'dailySummaryStatus': '目前未完成／已逾期',
    'dailySummaryCounts': '未完成 {u} 項，已逾期 {o} 項。沒有未完成事項時不會發送總整理通知。',
    'about': '關於 提醒Kath',
    'aboutBody': '特點：完全本機 SQLite 資料庫、純離線運作、無廣告、無帳號依賴、精確排程鬧鐘提醒、持續提醒直到完成。',
    'versionLabel': '版本：{v}',
    'alarmScreenTitle': '鬧鐘',
    'alarmDefaultBody': '鬧鐘時間到了',
    'alarmExtra': '另外還有 {n} 筆到期鬧鐘',
    'alarmExtraCount': '另外還有到期鬧鐘',
    'alarmStayHint': '返回或鎖定不會關閉鬧鐘，請選擇完成或稍後。',
    'alarmChannelName': '鬧鐘',
    'alarmChannelDesc': '待辦鬧鐘模式：全螢幕響鈴與持續震動',
    'taskChannelName': '待辦提醒',
    'previewAlarmTitle': '提醒Kath 測試鬧鐘',
    'previewAlarmNotes': '這是鬧鐘模式測試，選擇完成即可停止。',
    'repeatNone': '不重複',
    'repeatDaily': '每天',
    'repeatWeekly': '每週',
    'repeatMonthly': '每月',
    'inputTitleHint': '請輸入標題',
    'inputNotesHint': '備註（選填）',
    'overdueCount': '已逾期 ({n})',
    'uncompletedCount': '未完成 ({n})',
    'completedCount': '已完成 ({n})',
    'timezoneExactHint': '目前時區 {tz}',
    'systemReminders': '系統提醒',
    'dataSection': '資料',
    'appearanceLanguage': '外觀與語言',
    'aboutSection': '關於',
    'notifications': '通知',
    'alarmsAndReminders': '鬧鐘與提醒',
    'fullScreenReminder': '全螢幕提醒',
    'batteryBackground': '電池背景執行',
    'enabled': '已開啟',
    'disabled': '關閉',
    'needsSetup': '需要設定',
    'gotIt': '知道了',
    'restore': '還原',
    'theme': '主題',
    'themeLight': '淺色',
    'themeDark': '深色',
    'themeSystem': '跟隨系統',
    'showCompletedItems': '顯示已完成項目',
    'noTodosToday': '今天沒有待辦',
    'noTodos': '目前沒有待辦',
    'noTodosFound': '找不到待辦',
    'noTodosForDay': '當日無待辦',
    'search': '搜尋',
    'moreSettings': '更多設定',
    'notSet': '未設定',
    'pleaseEnterTitle': '請輸入標題',
    'reminderInterval': '提醒間隔',
    'defaultInterval': '預設間隔',
    'daily': '每日',
    'markComplete': '標記完成',
    'markIncomplete': '標記未完成',
    'snooze': '稍後',
    'minutes30': '30分鐘',
    'hour1': '1小時',
    'hours3': '3小時',
    'priorityUrgent': '緊急',
    'priorityNormal': '普通',
    'repeatCustomWeekdays': '自訂星期',
    'version': '版本',
    'exportFailed': '匯出失敗: {e}',
    'importFailedDetail': '匯入失敗: {e}',
    'notificationsDeniedHint': '請在系統設定開啟通知，才能收到一般提醒。',
    'batteryBackgroundHint': '請在系統設定將「提醒Kath」設為不受電池最佳化限制，以利背景與重開機後排程。',
    'languageFollowsSystem': '跟隨系統',
    'weekdaySun': '日',
    'weekdayMon': '一',
    'weekdayTue': '二',
    'weekdayWed': '三',
    'weekdayThu': '四',
    'weekdayFri': '五',
    'weekdaySat': '六',
    'todaySummary': '{u}件未完成 · {c}件已完成',
    'confirmDeleteTodo': '刪除待辦',
    'reminderWay': '提醒方式',
    'reminderWayHint': '一般通知：狀態列提醒。\n鬧鐘模式：到點全螢幕響鈴與震動，完成或稍後前持續。',
    'exportedPath': '已匯出：{path}',
    'confirmDeleteNamed': '確定刪除「{title}」？',
    'deleteTodoTitle': '刪除待辦',
    'alarmSound': '鬧鐘聲音',
    'alarmSoundDefault': '預設',
    'alarmSoundPick': '選擇手機音檔',
    'alarmSoundPickSystem': '選擇系統鈴聲',
    'alarmSoundPickFile': '選擇手機音檔',
    'alarmSoundPreview': '試聽',
    'alarmSoundReset': '恢復預設',
    'alarmSoundCopyFailed': '無法複製音檔，已保留原本設定。',
    'alarmSoundMissingHint': '找不到已儲存的鬧鐘音檔，已改用預設聲音，請重新選擇。',
    'alarmSoundPreviewFailed': '無法播放鬧鐘聲音。',
    'alarmSoundSystemInvalidHint': '系統鈴聲無法使用，已改用預設聲音，請重新選擇。',

  };

  static const _zhCN = <String, String>{
    'appTitle': 'Capsule Note',
    'today': '今天',
    'calendar': '日历',
    'todos': '待办',
    'settings': '设置',
    'completed': '已完成',
    'uncompleted': '未完成',
    'overdue': '已逾期',
    'all': '全部',
    'addTodo': '新增待办',
    'editTodo': '编辑待办',
    'delete': '删除',
    'complete': '完成',
    'save': '保存',
    'cancel': '取消',
    'confirm': '确认',
    'title': '标题',
    'notes': '备注',
    'date': '日期',
    'time': '时间',
    'reminderTime': '提醒时间',
    'scheduledDate': '排定日期',
    'repeat': '重复',
    'priority': '优先级',
    'change': '更改',
    'set': '设置',
    'noReminder': '未设置提醒（无闹钟）',
    'searchHint': '搜索待办',
    'focusToday': '专注今天的待办与提醒',
    'refresh': '刷新',
    'showMenu': '显示菜单',
    'overdueSection': '已逾期事项',
    'emptyTodos': '暂无待办事项',
    'priorityHigh': '高',
    'priorityMedium': '中',
    'priorityLow': '低',
    'reminderKind': '提醒类型',
    'notificationKind': '一般通知',
    'alarmKind': '闹钟模式',
    'alarmKindHint': '闹钟模式需要设置提醒时间，到点会全屏响铃并持续震动。',
    'notificationKindHint': '到点显示系统通知。',
    'alarmChip': '闹钟',
    'snooze30': '稍后30分钟',
    'snooze60': '稍后1小时',
    'snooze180': '稍后3小时',
    'snoozeTomorrow': '明天09:00',
    'snoozeSet30': '已设置 30 分钟后提醒',
    'snoozeSet60': '已设置 1 小时后提醒',
    'snoozeSetTomorrow': '已设置明天早上 09:00 提醒',
    'persistentReminder': '持续提醒',
    'persistentReminderHint': '未完成时按设置间隔持续提醒（每日最多6次）',
    'confirmDeleteTitle': '删除待办？',
    'confirmDeleteBody': '此操作无法撤销，相关日程也会一并取消。',
    'settingsTitle': '设置与备份',
    'backupRestore': '备份与还原',
    'exportBackup': '导出备份',
    'exportBackupHint': '将全部待办事项与设置导出为 JSON 文件保存',
    'importBackup': '导入还原',
    'importBackupHint': '检查格式并覆盖还原待办数据与闹钟排程',
    'importConfirm': '导入将“覆盖现有所有待办事项与设置”并重新排定闹钟，此操作无法撤销。是否继续？',
    'exportSuccess': '备份已导出',
    'importSuccess': '备份已还原',
    'importFailed': '还原失败',
    'importCancelled': '已取消导入',
    'appearance': '外观偏好',
    'darkMode': '深色模式',
    'language': '语言',
    'languageSystem': '跟随系统',
    'languageZhTW': '繁體中文',
    'languageZhCN': '简体中文',
    'languageEn': 'English',
    'languageHint': '同时应用于 App 界面与原生闹钟画面',
    'alarmManagement': '提醒与闹钟管理',
    'exactAlarmGranted': '精确闹钟：已授权',
    'exactAlarmDenied': '精确闹钟：未授权（已降级）',
    'exactAlarmGrantedHint': '精确闹钟已授权，提醒会准时触发。',
    'exactAlarmDeniedHint': '请开启“闹钟与提醒”权限，否则可能延后。',
    'fullScreenGranted': '全屏闹钟：已授权',
    'fullScreenDenied': '全屏闹钟：未授权（已降级）',
    'fullScreenGrantedHint': '锁屏可直接跳出闹钟画面。',
    'fullScreenDeniedHint': '未授权时改以高优先级通知提醒，锁屏可能不会自动跳出。',
    'openSettings': '打开设置',
    'checkPermissions': '检查并请求系统权限',
    'checkPermissionsHint': '请求发送通知与精确闹钟权限',
    'permissionsOk': '已取得通知与精确闹钟权限',
    'permissionsPartial': '已取得通知权限，精确闹钟未授权，将使用非精确提醒',
    'resyncSchedules': '手动全面校对排程',
    'resyncSchedulesHint': '依据当前数据库重新排定所有未完成闹钟',
    'resyncDone': '已重新校对排程',
    'testNotification': '测试即时通知',
    'testNotificationHint': '发送一则测试通知以确认系统通知正常',
    'testNotificationSent': '已发送测试通知',
    'testNotificationTitle': '提醒Kath 测试通知',
    'testNotificationBody': '系统通知与频道运作正常！',
    'testAlarm': '测试闹钟画面（45秒）',
    'testAlarmHint': '以原生闹钟链路在 45 秒后响铃，不写入待办数据',
    'testAlarmScheduled': '已排程 45 秒后测试闹钟',
    'dailySummary': '每日未完成事项总整理',
    'dailySummaryHint': '每日固定时间汇总通知未完成与逾期事项数量',
    'dailySummaryNote':
        '数量是在最近一次成功同步时计算（打开 App、从后台返回、重启后的后台核对）。Android 不会在通知响起当下保证执行 Dart，因此若长时间未打开 App，摘要数字可能略为过时。',
    'dailySummaryTime': '每日整理提醒时间',
    'dailySummaryEveryDay': '每天 {time} 发送通知',
    'dailySummaryStatus': '当前未完成／已逾期',
    'dailySummaryCounts': '未完成 {u} 项，已逾期 {o} 项。没有未完成事项时不会发送总整理通知。',
    'about': '关于 提醒Kath',
    'aboutBody': '特点：完全本地 SQLite 数据库、纯离线运作、无广告、无账号依赖、精确排程闹钟提醒、持续提醒直到完成。',
    'versionLabel': '版本：{v}',
    'alarmScreenTitle': '闹钟',
    'alarmDefaultBody': '闹钟时间到了',
    'alarmExtra': '另外还有 {n} 笔到期闹钟',
    'alarmExtraCount': '另外还有到期闹钟',
    'alarmStayHint': '返回或锁定不会关闭闹钟，请选择完成或稍后。',
    'alarmChannelName': '闹钟',
    'alarmChannelDesc': '待办闹钟模式：全屏响铃与持续震动',
    'taskChannelName': '待办提醒',
    'previewAlarmTitle': '提醒Kath 测试闹钟',
    'previewAlarmNotes': '这是闹钟模式测试，选择完成即可停止。',
    'repeatNone': '不重复',
    'repeatDaily': '每天',
    'repeatWeekly': '每周',
    'repeatMonthly': '每月',
    'inputTitleHint': '请输入标题',
    'inputNotesHint': '备注（选填）',
    'overdueCount': '已逾期 ({n})',
    'uncompletedCount': '未完成 ({n})',
    'completedCount': '已完成 ({n})',
    'timezoneExactHint': '当前时区 {tz}',
    'systemReminders': '系统提醒',
    'dataSection': '数据',
    'appearanceLanguage': '外观与语言',
    'aboutSection': '关于',
    'notifications': '通知',
    'alarmsAndReminders': '闹钟与提醒',
    'fullScreenReminder': '全屏提醒',
    'batteryBackground': '电池后台运行',
    'enabled': '已开启',
    'disabled': '关闭',
    'needsSetup': '需要设置',
    'gotIt': '知道了',
    'restore': '还原',
    'theme': '主题',
    'themeLight': '浅色',
    'themeDark': '深色',
    'themeSystem': '跟随系统',
    'showCompletedItems': '显示已完成项目',
    'noTodosToday': '今天没有待办',
    'noTodos': '目前没有待办',
    'noTodosFound': '找不到待办',
    'noTodosForDay': '当日无待办',
    'search': '搜索',
    'moreSettings': '更多设置',
    'notSet': '未设置',
    'pleaseEnterTitle': '请输入标题',
    'reminderInterval': '提醒间隔',
    'defaultInterval': '默认间隔',
    'daily': '每日',
    'markComplete': '标记完成',
    'markIncomplete': '标记未完成',
    'snooze': '稍后',
    'minutes30': '30分钟',
    'hour1': '1小时',
    'hours3': '3小时',
    'priorityUrgent': '紧急',
    'priorityNormal': '普通',
    'repeatCustomWeekdays': '自定义星期',
    'version': '版本',
    'exportFailed': '导出失败: {e}',
    'importFailedDetail': '导入失败: {e}',
    'notificationsDeniedHint': '请在系统设置开启通知，才能收到一般提醒。',
    'batteryBackgroundHint': '请在系统设置将“提醒Kath”设为不受电池优化限制，以利后台与重启后排程。',
    'languageFollowsSystem': '跟随系统',
    'weekdaySun': '日',
    'weekdayMon': '一',
    'weekdayTue': '二',
    'weekdayWed': '三',
    'weekdayThu': '四',
    'weekdayFri': '五',
    'weekdaySat': '六',
    'todaySummary': '{u}件未完成 · {c}件已完成',
    'confirmDeleteTodo': '删除待办',
    'reminderWay': '提醒方式',
    'reminderWayHint': '一般通知：状态栏提醒。\n闹钟模式：到点全屏响铃与震动，完成或稍后前持续。',
    'exportedPath': '已导出：{path}',
    'confirmDeleteNamed': '确定删除「{title}」？',
    'deleteTodoTitle': '删除待办',
    'alarmSound': '闹钟声音',
    'alarmSoundDefault': '默认',
    'alarmSoundPick': '选择手机音频',
    'alarmSoundPickSystem': '选择系统铃声',
    'alarmSoundPickFile': '选择手机音频',
    'alarmSoundPreview': '试听',
    'alarmSoundReset': '恢复默认',
    'alarmSoundCopyFailed': '无法复制音档，已保留原来的设置。',
    'alarmSoundMissingHint': '找不到已保存的闹钟音档，已改用默认声音，请重新选择。',
    'alarmSoundPreviewFailed': '无法播放闹钟声音。',
    'alarmSoundSystemInvalidHint': '系统铃声无法使用，已改用默认声音，请重新选择。',

  };
}

class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      strings.locale != oldWidget.strings.locale;
}

// Private typedef used by AppStrings.of — keep name stable for InheritedWidget lookup.
typedef _AppStringsScope = AppStringsScope;
