import 'package:flutter/services.dart';
import 'package:capsule_note/services/alarm_port.dart';

/// In-memory native-alarm fake. Never touches a MethodChannel.
class FakeAlarmScheduler implements IAlarmScheduler {
  final Map<int, AlarmScheduleRequest> scheduled = {};
  final List<int> cancelledIds = [];
  final List<String> cancelledTodoIds = [];
  final List<AlarmPendingAction> pendingActions = [];
  bool exactAlarmsGranted = true;
  bool fullScreenIntentGranted = true;
  int exactSettingsOpened = 0;
  int fullScreenSettingsOpened = 0;
  int cancelAllCount = 0;

  AlarmSoundInfo alarmSound = const AlarmSoundInfo();
  int pickAlarmSoundCount = 0;
  int pickSystemRingtoneCount = 0;
  int clearAlarmSoundCount = 0;
  int previewAlarmSoundCount = 0;
  int stopAlarmSoundPreviewCount = 0;
  bool pickThrows = false;
  bool applyBackupResult = true;
  bool systemUriValid = true;

  @override
  Future<bool> canScheduleExactAlarms() async => exactAlarmsGranted;

  @override
  Future<bool> canUseFullScreenIntent() async => fullScreenIntentGranted;

  @override
  Future<void> openExactAlarmSettings() async {
    exactSettingsOpened++;
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    fullScreenSettingsOpened++;
  }

  @override
  Future<bool> scheduleAlarm(AlarmScheduleRequest request) async {
    scheduled[request.requestCode] = request;
    return true;
  }

  @override
  Future<void> cancelAlarm(int requestCode) async {
    scheduled.remove(requestCode);
    cancelledIds.add(requestCode);
  }

  @override
  Future<void> cancelAlarmsForTodo(String todoId) async {
    cancelledTodoIds.add(todoId);
    final toRemove = scheduled.entries
        .where((entry) => entry.value.todoId == todoId)
        .map((entry) => entry.key)
        .toList();
    for (final id in toRemove) {
      scheduled.remove(id);
      cancelledIds.add(id);
    }
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<List<AlarmPendingAction>> drainPendingActions() async {
    final drained = List<AlarmPendingAction>.from(pendingActions);
    pendingActions.clear();
    return drained;
  }

  @override
  Future<bool> previewAlarm({String? title, String? notes}) async => true;

  @override
  Future<void> setAppLocale(String preference) async {}

  @override
  Future<AlarmSoundInfo> getAlarmSound() async => alarmSound;

  @override
  Future<AlarmSoundInfo?> pickAlarmSound() async {
    pickAlarmSoundCount++;
    if (pickThrows) {
      throw PlatformException(code: 'copy_failed', message: 'copy failed');
    }
    alarmSound = const AlarmSoundInfo(
      source: AlarmSoundSource.file,
      fileName: 'custom_alarm.mp3',
      displayName: 'custom_alarm.mp3',
      exists: true,
    );
    return alarmSound;
  }

  @override
  Future<AlarmSoundInfo?> pickSystemRingtone() async {
    pickSystemRingtoneCount++;
    if (pickThrows) {
      throw PlatformException(code: 'save_failed', message: 'save failed');
    }
    alarmSound = const AlarmSoundInfo(
      source: AlarmSoundSource.system,
      ringtoneUri: 'content://media/internal/audio/media/1',
      displayName: 'Fold3 Alarm',
      exists: true,
    );
    return alarmSound;
  }

  @override
  Future<void> clearAlarmSound() async {
    clearAlarmSoundCount++;
    alarmSound = const AlarmSoundInfo();
  }

  @override
  Future<bool> previewAlarmSound() async {
    previewAlarmSoundCount++;
    return true;
  }

  @override
  Future<void> stopAlarmSoundPreview() async {
    stopAlarmSoundPreviewCount++;
  }

  @override
  Future<bool> applyAlarmSoundBackup({
    String? source,
    String? fileName,
    String? displayName,
    String? ringtoneUri,
  }) async {
    final src = source ??
        (ringtoneUri != null && ringtoneUri.isNotEmpty
            ? AlarmSoundSource.system
            : (fileName != null && fileName.isNotEmpty
                  ? AlarmSoundSource.file
                  : AlarmSoundSource.defaults));
    if (src == AlarmSoundSource.defaults ||
        ((fileName == null || fileName.isEmpty) &&
            (ringtoneUri == null || ringtoneUri.isEmpty) &&
            src != AlarmSoundSource.system)) {
      alarmSound = const AlarmSoundInfo();
      return true;
    }
    if (src == AlarmSoundSource.system) {
      if (!applyBackupResult ||
          !systemUriValid ||
          ringtoneUri == null ||
          ringtoneUri.isEmpty) {
        alarmSound = const AlarmSoundInfo();
        return false;
      }
      alarmSound = AlarmSoundInfo(
        source: AlarmSoundSource.system,
        ringtoneUri: ringtoneUri,
        displayName: displayName ?? ringtoneUri,
        exists: true,
      );
      return true;
    }
    if (!applyBackupResult || fileName == null || fileName.isEmpty) {
      alarmSound = const AlarmSoundInfo();
      return false;
    }
    alarmSound = AlarmSoundInfo(
      source: AlarmSoundSource.file,
      fileName: fileName,
      displayName: displayName ?? fileName,
      exists: true,
    );
    return true;
  }
}
