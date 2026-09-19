/// Plugin-free native alarm contract. Tests inject a Fake; production
/// registers [AndroidAlarmScheduler] from main(). Never import this from
/// widget tests without a Fake — the real impl uses a MethodChannel.
class AlarmScheduleRequest {
  final int requestCode;
  final DateTime triggerTime;
  final String todoId;
  final String title;
  final String notes;
  final DateTime scheduledTime;

  const AlarmScheduleRequest({
    required this.requestCode,
    required this.triggerTime,
    required this.todoId,
    required this.title,
    required this.notes,
    required this.scheduledTime,
  });
}

class AlarmPendingAction {
  final String actionId;
  final String todoId;

  const AlarmPendingAction({required this.actionId, required this.todoId});
}

/// Alarm sound preference source: system ringtone, private file, or default.
class AlarmSoundSource {
  static const system = 'system';
  static const file = 'file';
  static const defaults = 'default';
}

class AlarmSoundInfo {
  final String source;
  final String? fileName;
  final String? displayName;
  final String? ringtoneUri;
  final bool exists;

  const AlarmSoundInfo({
    this.source = AlarmSoundSource.defaults,
    this.fileName,
    this.displayName,
    this.ringtoneUri,
    this.exists = false,
  });

  bool get isCustom =>
      source == AlarmSoundSource.system || source == AlarmSoundSource.file;

  bool get hasUsableCustom => isCustom && exists;

  factory AlarmSoundInfo.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const AlarmSoundInfo();
    final source = map['source']?.toString() ?? AlarmSoundSource.defaults;
    return AlarmSoundInfo(
      source: source,
      fileName: map['fileName']?.toString(),
      displayName: map['displayName']?.toString(),
      ringtoneUri: map['ringtoneUri']?.toString(),
      exists: map['exists'] == true,
    );
  }
}

abstract class IAlarmScheduler {
  Future<bool> canScheduleExactAlarms();
  Future<bool> canUseFullScreenIntent();
  Future<void> openExactAlarmSettings();
  Future<void> openFullScreenIntentSettings();
  Future<bool> scheduleAlarm(AlarmScheduleRequest request);
  Future<void> cancelAlarm(int requestCode);
  Future<void> cancelAlarmsForTodo(String todoId);
  Future<void> cancelAll();
  Future<List<AlarmPendingAction>> drainPendingActions();
  Future<bool> previewAlarm({String? title, String? notes});
  Future<void> setAppLocale(String preference);
  Future<AlarmSoundInfo> getAlarmSound();
  Future<AlarmSoundInfo?> pickAlarmSound();
  Future<AlarmSoundInfo?> pickSystemRingtone();
  Future<void> clearAlarmSound();
  Future<bool> previewAlarmSound();
  Future<void> stopAlarmSoundPreview();
  Future<bool> applyAlarmSoundBackup({
    String? source,
    String? fileName,
    String? displayName,
    String? ringtoneUri,
  });
}

class AlarmPort {
  static IAlarmScheduler? _instance;

  static IAlarmScheduler get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'AlarmPort.instance 尚未設定。測試必須注入 Fake，正式 App 必須在 main() 註冊真實服務。',
      );
    }
    return current;
  }

  static set instance(IAlarmScheduler service) {
    _instance = service;
  }

  static bool get isConfigured => _instance != null;

  static void reset() {
    _instance = null;
  }
}
