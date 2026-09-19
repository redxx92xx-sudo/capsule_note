import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../l10n/app_strings_delegate.dart';
import '../models/repeat_rule.dart';
import '../models/todo_item.dart';
import '../models/reminder_kind.dart';
import '../theme/app_theme.dart';
import '../utils/rk_trace.dart';
import 'alarm_port.dart';
import 'database_service.dart';
import 'reminder_scheduler.dart';

enum TodoFilterTab {
  uncompleted,
  completed,
  overdue,
  all;

  String get displayName {
    switch (this) {
      case TodoFilterTab.uncompleted:
        return '未完成';
      case TodoFilterTab.completed:
        return '已完成';
      case TodoFilterTab.overdue:
        return '已逾期';
      case TodoFilterTab.all:
        return '全部';
    }
  }

  String localizedName(AppStrings s) {
    switch (this) {
      case TodoFilterTab.uncompleted:
        return s.uncompleted;
      case TodoFilterTab.completed:
        return s.completed;
      case TodoFilterTab.overdue:
        return s.overdue;
      case TodoFilterTab.all:
        return s.all;
    }
  }
}

class TodoProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final ReminderScheduler _scheduler;
  final _uuid = const Uuid();

  List<TodoItem> _todos = [];
  bool _isLoading = false;
  AppThemePreference _themePreference = AppThemePreference.system;
  String _localePreference = AppLocaleOption.system;
  DateTime _selectedDate = DateTime.now();
  TodoFilterTab _currentFilter = TodoFilterTab.uncompleted;
  String _searchQuery = '';
  bool _dailySummaryEnabled = true;
  String _dailySummaryTime = '09:00';
  int _persistentIntervalMinutes = 60;
  int _persistentDailyMax = 6;
  bool _exactAlarmsAllowed = true;
  bool _fullScreenIntentAllowed = true;
  bool _lastScheduleUsedExact = true;
  String _timezoneName = 'Asia/Taipei';
  String? _alarmSoundFileName;
  String? _alarmSoundDisplayName;
  String? _alarmSoundRingtoneUri;
  String _alarmSoundSource = AlarmSoundSource.defaults;
  bool _alarmSoundExists = false;

  TodoProvider({
    DatabaseService? dbService,
    ReminderScheduler? scheduler,
    bool autoInitialize = false,
  }) : _dbService = dbService ?? DatabaseService.instance,
       _scheduler =
           scheduler ??
           ReminderScheduler(dbService: dbService ?? DatabaseService.instance) {
    if (autoInitialize) {
      rkTrace('TodoProvider autoInitialize -> loadTodos (fire-and-forget)');
      loadTodos();
    }
  }

  List<TodoItem> get todos => List.unmodifiable(_todos);
  bool get isLoading => _isLoading;
  AppThemePreference get themePreference => _themePreference;
  String get localePreference => _localePreference;

  /// Legacy alias: true only when preference is forced dark.
  bool get isDarkMode => _themePreference == AppThemePreference.dark;
  DateTime get selectedDate => _selectedDate;
  TodoFilterTab get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  bool get dailySummaryEnabled => _dailySummaryEnabled;
  String get dailySummaryTime => _dailySummaryTime;
  int get persistentIntervalMinutes => _persistentIntervalMinutes;
  int get persistentDailyMax => _persistentDailyMax;
  bool get exactAlarmsAllowed => _exactAlarmsAllowed;
  bool get fullScreenIntentAllowed => _fullScreenIntentAllowed;
  bool get lastScheduleUsedExact => _lastScheduleUsedExact;
  String get timezoneName => _timezoneName;
  String? get alarmSoundFileName => _alarmSoundFileName;
  String? get alarmSoundDisplayName => _alarmSoundDisplayName;
  String? get alarmSoundRingtoneUri => _alarmSoundRingtoneUri;
  String get alarmSoundSource => _alarmSoundSource;
  bool get alarmSoundExists => _alarmSoundExists;
  bool get hasCustomAlarmSound =>
      (_alarmSoundSource == AlarmSoundSource.system ||
          _alarmSoundSource == AlarmSoundSource.file) &&
      _alarmSoundExists;

  List<TodoItem> get uncompletedTodos =>
      _todos.where((t) => !t.isCompleted).toList();

  List<TodoItem> get completedTodos =>
      _todos.where((t) => t.isCompleted).toList();

  List<TodoItem> get overdueTodos {
    final now = DateTime.now();
    return _todos.where((t) => t.isOverdue(now)).toList();
  }

  List<TodoItem> get todayTodos {
    final now = DateTime.now();
    return _todos.where((t) => t.isDueToday(now) && !t.isCompleted).toList();
  }

  List<TodoItem> get todayCompletedTodos {
    final now = DateTime.now();
    return _todos.where((t) => t.isDueToday(now) && t.isCompleted).toList();
  }

  List<TodoItem> get upcomingTodos {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final sevenDaysLater = todayEnd.add(const Duration(days: 7));
    return _todos
        .where(
          (t) =>
              !t.isCompleted &&
              t.scheduledDate.isAfter(todayEnd) &&
              t.scheduledDate.isBefore(sevenDaysLater),
        )
        .toList();
  }

  List<TodoItem> get filteredTodos {
    List<TodoItem> baseList;
    switch (_currentFilter) {
      case TodoFilterTab.uncompleted:
        baseList = uncompletedTodos;
        break;
      case TodoFilterTab.completed:
        baseList = completedTodos;
        break;
      case TodoFilterTab.overdue:
        baseList = overdueTodos;
        break;
      case TodoFilterTab.all:
        baseList = _todos;
        break;
    }

    if (_searchQuery.trim().isEmpty) {
      return baseList;
    }

    final query = _searchQuery.trim().toLowerCase();
    return baseList.where((t) {
      return t.title.toLowerCase().contains(query) ||
          t.notes.toLowerCase().contains(query);
    }).toList();
  }

  int get uncompletedCount => uncompletedTodos.length;
  int get completedCount => completedTodos.length;
  int get overdueCount => overdueTodos.length;
  int get todayCount => todayTodos.length;

  void setFilter(TodoFilterTab filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<TodoItem> getTodosForDate(DateTime date) {
    return _todos.where((t) {
      return t.scheduledDate.year == date.year &&
          t.scheduledDate.month == date.month &&
          t.scheduledDate.day == date.day;
    }).toList();
  }

  Map<DateTime, List<TodoItem>> get todosByDay {
    final map = <DateTime, List<TodoItem>>{};
    for (final todo in _todos) {
      final key = DateTime(
        todo.scheduledDate.year,
        todo.scheduledDate.month,
        todo.scheduledDate.day,
      );
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(todo);
    }
    return map;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadTodos() async {
    rkTrace('TodoProvider.loadTodos start');
    _isLoading = true;
    notifyListeners();

    try {
      rkTrace('TodoProvider.loadTodos await getAllTodos');
      _todos = await _dbService.getAllTodos();
      rkTrace('TodoProvider.loadTodos await reminder settings');
      await _loadThemePreference();
      await _loadLocalePreference();
      await _loadReminderSettings();
      await _loadAlarmSound();
    } finally {
      _isLoading = false;
      notifyListeners();
      rkTrace('TodoProvider.loadTodos done count=${_todos.length}');
    }
  }

  Future<void> _loadThemePreference() async {
    final mode = await _dbService.getSetting('theme_mode');
    if (mode != null) {
      _themePreference = AppThemePreference.fromStorage(mode);
      return;
    }
    // Migrate legacy boolean without changing todos/alarms data.
    final legacy = await _dbService.getSetting('is_dark_mode');
    if (legacy == 'true') {
      _themePreference = AppThemePreference.dark;
    } else if (legacy == 'false') {
      _themePreference = AppThemePreference.light;
    } else {
      _themePreference = AppThemePreference.system;
    }
  }

  Future<void> _loadReminderSettings() async {
    final enabledStr = await _dbService.getSetting('daily_summary_enabled');
    final timeStr = await _dbService.getSetting('daily_summary_time');
    final intervalStr = await _dbService.getSetting(
      'persistent_interval_minutes',
    );
    final maxStr = await _dbService.getSetting('persistent_daily_max');
    _dailySummaryEnabled = enabledStr != 'false';
    _dailySummaryTime = timeStr ?? '09:00';
    _persistentIntervalMinutes = int.tryParse(intervalStr ?? '') ?? 60;
    _persistentDailyMax = int.tryParse(maxStr ?? '') ?? 6;
  }

  Future<void> _loadAlarmSound() async {
    _alarmSoundSource =
        await _dbService.getSetting('ringtone_source') ??
        AlarmSoundSource.defaults;
    _alarmSoundFileName = await _dbService.getSetting('alarm_sound_file');
    _alarmSoundDisplayName = await _dbService.getSetting(
      'alarm_sound_display',
    );
    _alarmSoundRingtoneUri = await _dbService.getSetting('ringtone_uri');

    // Legacy: file metadata without source key.
    if ((_alarmSoundSource == AlarmSoundSource.defaults ||
            _alarmSoundSource.isEmpty) &&
        _alarmSoundFileName != null &&
        _alarmSoundFileName!.isNotEmpty) {
      _alarmSoundSource = AlarmSoundSource.file;
    }

    if (!AlarmPort.isConfigured) {
      _alarmSoundExists = _alarmSoundSource != AlarmSoundSource.defaults;
      return;
    }
    try {
      final info = await AlarmPort.instance.getAlarmSound();
      if (info.source != AlarmSoundSource.defaults && info.exists) {
        _applyAlarmSoundInfo(info);
        await _persistAlarmSoundSettings();
      } else if (_alarmSoundSource != AlarmSoundSource.defaults) {
        final ok = await AlarmPort.instance.applyAlarmSoundBackup(
          source: _alarmSoundSource,
          fileName: _alarmSoundFileName,
          displayName: _alarmSoundDisplayName,
          ringtoneUri: _alarmSoundRingtoneUri,
        );
        if (ok) {
          final refreshed = await AlarmPort.instance.getAlarmSound();
          _applyAlarmSoundInfo(refreshed);
          await _persistAlarmSoundSettings();
        } else {
          _resetAlarmSoundLocal();
          await _persistAlarmSoundSettings();
        }
      } else {
        _resetAlarmSoundLocal();
      }
    } catch (_) {
      _alarmSoundExists = _alarmSoundSource != AlarmSoundSource.defaults;
    }
  }

  void _applyAlarmSoundInfo(AlarmSoundInfo info) {
    _alarmSoundSource = info.source;
    _alarmSoundFileName = info.fileName;
    _alarmSoundDisplayName = info.displayName;
    _alarmSoundRingtoneUri = info.ringtoneUri;
    _alarmSoundExists = info.exists || info.source == AlarmSoundSource.defaults;
  }

  void _resetAlarmSoundLocal() {
    _alarmSoundSource = AlarmSoundSource.defaults;
    _alarmSoundFileName = null;
    _alarmSoundDisplayName = null;
    _alarmSoundRingtoneUri = null;
    _alarmSoundExists = false;
  }

  Future<void> _persistAlarmSoundSettings() async {
    await _dbService.setSetting('ringtone_source', _alarmSoundSource);
    await _dbService.setSetting(
      'alarm_sound_file',
      _alarmSoundFileName ?? '',
    );
    await _dbService.setSetting(
      'alarm_sound_display',
      _alarmSoundDisplayName ?? '',
    );
    await _dbService.setSetting(
      'ringtone_uri',
      _alarmSoundRingtoneUri ?? '',
    );
  }

  Future<bool> pickAlarmSound() async {
    if (!AlarmPort.isConfigured) return false;
    await stopAlarmSoundPreview();
    final info = await AlarmPort.instance.pickAlarmSound();
    if (info == null) return false;
    _applyAlarmSoundInfo(info);
    await _persistAlarmSoundSettings();
    notifyListeners();
    return true;
  }

  Future<bool> pickSystemRingtone() async {
    if (!AlarmPort.isConfigured) return false;
    await stopAlarmSoundPreview();
    final info = await AlarmPort.instance.pickSystemRingtone();
    if (info == null) return false;
    _applyAlarmSoundInfo(info);
    await _persistAlarmSoundSettings();
    notifyListeners();
    return true;
  }

  Future<void> clearAlarmSound() async {
    await stopAlarmSoundPreview();
    if (AlarmPort.isConfigured) {
      await AlarmPort.instance.clearAlarmSound();
    }
    _resetAlarmSoundLocal();
    await _persistAlarmSoundSettings();
    notifyListeners();
  }

  Future<bool> previewAlarmSound() async {
    if (!AlarmPort.isConfigured) return false;
    return AlarmPort.instance.previewAlarmSound();
  }

  Future<void> stopAlarmSoundPreview() async {
    if (!AlarmPort.isConfigured) return;
    await AlarmPort.instance.stopAlarmSoundPreview();
  }

  /// After JSON restore: re-bind native sound from settings metadata.
  /// Returns false when metadata cannot be applied (use default + hint).
  Future<bool> syncAlarmSoundAfterRestore() async {
    _alarmSoundSource =
        await _dbService.getSetting('ringtone_source') ??
        AlarmSoundSource.defaults;
    _alarmSoundFileName = await _dbService.getSetting('alarm_sound_file');
    _alarmSoundDisplayName = await _dbService.getSetting(
      'alarm_sound_display',
    );
    _alarmSoundRingtoneUri = await _dbService.getSetting('ringtone_uri');

    if ((_alarmSoundSource == AlarmSoundSource.defaults ||
            _alarmSoundSource.isEmpty) &&
        (_alarmSoundFileName == null || _alarmSoundFileName!.isEmpty) &&
        (_alarmSoundRingtoneUri == null || _alarmSoundRingtoneUri!.isEmpty)) {
      _resetAlarmSoundLocal();
      if (AlarmPort.isConfigured) {
        await AlarmPort.instance.clearAlarmSound();
      }
      await _persistAlarmSoundSettings();
      notifyListeners();
      return true;
    }

    if (!AlarmPort.isConfigured) {
      _alarmSoundExists = true;
      notifyListeners();
      return true;
    }

    final ok = await AlarmPort.instance.applyAlarmSoundBackup(
      source: _alarmSoundSource,
      fileName: _alarmSoundFileName,
      displayName: _alarmSoundDisplayName,
      ringtoneUri: _alarmSoundRingtoneUri,
    );
    if (!ok) {
      _resetAlarmSoundLocal();
      await _persistAlarmSoundSettings();
      notifyListeners();
      return false;
    }
    final info = await AlarmPort.instance.getAlarmSound();
    _applyAlarmSoundInfo(info);
    await _persistAlarmSoundSettings();
    notifyListeners();
    return true;
  }

  void setAlarmCapability({
    required bool exactAlarmsAllowed,
    bool? fullScreenIntentAllowed,
    String? timezoneName,
    bool? lastScheduleUsedExact,
  }) {
    _exactAlarmsAllowed = exactAlarmsAllowed;
    if (fullScreenIntentAllowed != null) {
      _fullScreenIntentAllowed = fullScreenIntentAllowed;
    }
    if (timezoneName != null) _timezoneName = timezoneName;
    if (lastScheduleUsedExact != null) {
      _lastScheduleUsedExact = lastScheduleUsedExact;
    }
    notifyListeners();
  }

  Future<void> setDailySummaryEnabled(bool enabled) async {
    _dailySummaryEnabled = enabled;
    notifyListeners();
    await _dbService.setSetting(
      'daily_summary_enabled',
      enabled ? 'true' : 'false',
    );
    await _scheduler.scheduleDailySummary();
  }

  Future<void> setDailySummaryTime(String time) async {
    _dailySummaryTime = time;
    notifyListeners();
    await _dbService.setSetting('daily_summary_time', time);
    await _scheduler.scheduleDailySummary();
  }

  Future<void> setPersistentIntervalMinutes(int interval) async {
    _persistentIntervalMinutes = interval;
    notifyListeners();
    await _dbService.setSetting(
      'persistent_interval_minutes',
      interval.toString(),
    );
    await _scheduler.syncAllReminders();
  }

  Future<void> setPersistentDailyMax(int max) async {
    _persistentDailyMax = max;
    notifyListeners();
    await _dbService.setSetting('persistent_daily_max', max.toString());
    await _scheduler.syncAllReminders();
  }

  Future<void> _loadLocalePreference() async {
    final raw = await _dbService.getSetting('app_locale');
    _localePreference = switch (raw) {
      AppLocaleOption.zhTW ||
      AppLocaleOption.zhCN ||
      AppLocaleOption.en ||
      AppLocaleOption.system =>
        raw!,
      _ => AppLocaleOption.system,
    };
    _syncLocaleHolder();
    await _pushLocaleToNative();
  }

  void _syncLocaleHolder() {
    final preferred = AppLocaleOption.toLocale(_localePreference);
    final resolved = AppLocaleOption.resolve(
      preferred,
      PlatformDispatcher.instance.locales,
    );
    AppLocaleHolder.update(
      preferenceTag: _localePreference,
      resolvedLocale: resolved,
    );
  }

  Future<void> _pushLocaleToNative() async {
    if (!AlarmPort.isConfigured) return;
    try {
      await AlarmPort.instance.setAppLocale(_localePreference);
    } catch (_) {
      // UI-only sync; ignore native channel failures in tests.
    }
  }

  Future<void> refreshResolvedLocale() async {
    _syncLocaleHolder();
    notifyListeners();
    await _pushLocaleToNative();
  }

  Future<void> setLocalePreference(String preference) async {
    final next = AppLocaleOption.all.contains(preference)
        ? preference
        : AppLocaleOption.system;
    _localePreference = next;
    _syncLocaleHolder();
    notifyListeners();
    await _dbService.setSetting('app_locale', next);
    await _pushLocaleToNative();
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    _themePreference = preference;
    notifyListeners();
    await _dbService.setSetting('theme_mode', preference.storageValue);
    // Keep legacy key in sync for older backup readers.
    await _dbService.setSetting(
      'is_dark_mode',
      preference == AppThemePreference.dark ? 'true' : 'false',
    );
  }

  Future<void> toggleDarkMode() async {
    final next = _themePreference == AppThemePreference.dark
        ? AppThemePreference.light
        : AppThemePreference.dark;
    await setThemePreference(next);
  }

  Future<TodoItem> createTodo({
    required String title,
    String notes = '',
    required DateTime scheduledDate,
    DateTime? reminderTime,
    TodoPriority priority = TodoPriority.normal,
    RepeatType repeatRule = RepeatType.none,
    List<int> repeatDays = const [],
    bool isPersistentReminder = false,
    int persistentIntervalMinutes = 60,
    ReminderKind reminderKind = ReminderKind.notification,
  }) async {
    final newTodo = TodoItem(
      id: _uuid.v4(),
      title: title.trim(),
      notes: notes.trim(),
      createdAt: DateTime.now(),
      scheduledDate: DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      ),
      reminderTime: reminderTime,
      priority: priority,
      repeatRule: repeatRule,
      repeatDays: repeatDays,
      isPersistentReminder: isPersistentReminder,
      persistentIntervalMinutes: persistentIntervalMinutes,
      reminderKind: reminderKind,
    );

    await _dbService.insertTodo(newTodo);
    _todos.add(newTodo);
    _sortTodos();

    await _scheduler.scheduleTodo(newTodo);
    notifyListeners();
    return newTodo;
  }

  Future<void> updateTodo(TodoItem updatedTodo) async {
    await _dbService.updateTodo(updatedTodo);
    final index = _todos.indexWhere((t) => t.id == updatedTodo.id);
    if (index != -1) {
      _todos[index] = updatedTodo;
      _sortTodos();
    }

    await _scheduler.scheduleTodo(updatedTodo);
    notifyListeners();
  }

  Future<void> toggleCompleted(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _todos[index];
    final updated = current.toggleCompleted();

    await _dbService.updateTodo(updated);
    _todos[index] = updated;
    _sortTodos();

    if (updated.isCompleted) {
      await _scheduler.cancelTodoReminder(updated);
    } else {
      await _scheduler.scheduleTodo(updated);
    }
    notifyListeners();
  }

  Future<void> snoozeTodo(String id, Duration duration) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final current = _todos[index];
    final snoozeTime = DateTime.now().add(duration);
    final updated = current.copyWith(
      snoozeUntil: snoozeTime,
      nextReminderTime: snoozeTime,
    );

    await _dbService.updateTodo(updated);
    _todos[index] = updated;
    _sortTodos();

    await _scheduler.scheduleTodo(updated);
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final todo = _todos[index];
      await _dbService.deleteTodo(id);
      _todos.removeAt(index);
      await _scheduler.cancelTodoReminder(todo);
      notifyListeners();
    }
  }

  void _sortTodos() {
    _todos.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final dateComp = a.scheduledDate.compareTo(b.scheduledDate);
      if (dateComp != 0) return dateComp;

      if (a.reminderTime != null && b.reminderTime != null) {
        final timeComp = a.reminderTime!.compareTo(b.reminderTime!);
        if (timeComp != 0) return timeComp;
      } else if (a.reminderTime != null) {
        return -1;
      } else if (b.reminderTime != null) {
        return 1;
      }

      return b.priority.index.compareTo(a.priority.index);
    });
  }
}
