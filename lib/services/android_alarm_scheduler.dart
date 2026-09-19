import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/rk_trace.dart';
import 'alarm_port.dart';

class AndroidAlarmScheduler implements IAlarmScheduler {
  AndroidAlarmScheduler();

  static const MethodChannel channel = MethodChannel(
    'com.capsulenote.app/alarm',
  );

  static bool get _isWidgetTestBinding {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('TestWidgetsFlutterBinding');
  }

  Future<T?> _invoke<T>(String method, [dynamic arguments]) async {
    if (_isWidgetTestBinding) {
      rkTrace('AndroidAlarmScheduler.$method skipped (test binding)');
      return null;
    }
    try {
      return await channel
          .invokeMethod<T>(method, arguments)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('AndroidAlarmScheduler.$method failed: $e');
      rkTrace('AndroidAlarmScheduler.$method failed: $e');
      return null;
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    final value = await _invoke<bool>('canScheduleExactAlarms');
    return value ?? false;
  }

  @override
  Future<bool> canUseFullScreenIntent() async {
    final value = await _invoke<bool>('canUseFullScreenIntent');
    return value ?? false;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    await _invoke<void>('openExactAlarmSettings');
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    await _invoke<void>('openFullScreenIntentSettings');
  }

  @override
  Future<bool> scheduleAlarm(AlarmScheduleRequest request) async {
    if (!request.triggerTime.isAfter(DateTime.now())) {
      return false;
    }
    final value = await _invoke<bool>('scheduleAlarm', {
      'requestCode': request.requestCode,
      'triggerAtMillis': request.triggerTime.millisecondsSinceEpoch,
      'todoId': request.todoId,
      'title': request.title,
      'notes': request.notes,
      'scheduledTimeIso': request.scheduledTime.toIso8601String(),
    });
    return value ?? false;
  }

  @override
  Future<void> cancelAlarm(int requestCode) async {
    await _invoke<void>('cancelAlarm', {'requestCode': requestCode});
  }

  @override
  Future<void> cancelAlarmsForTodo(String todoId) async {
    await _invoke<void>('cancelAlarmsForTodo', {'todoId': todoId});
  }

  @override
  Future<void> cancelAll() async {
    await _invoke<void>('cancelAll');
  }

  @override
  Future<List<AlarmPendingAction>> drainPendingActions() async {
    final raw = await _invoke<dynamic>('drainPendingActions');
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => AlarmPendingAction(
            actionId: item['actionId']?.toString() ?? '',
            todoId: item['todoId']?.toString() ?? '',
          ),
        )
        .where((item) => item.actionId.isNotEmpty && item.todoId.isNotEmpty)
        .toList();
  }

  @override
  Future<bool> previewAlarm({String? title, String? notes}) async {
    final value = await _invoke<bool>('previewAlarm', {
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
    });
    return value ?? false;
  }

  @override
  Future<void> setAppLocale(String preference) async {
    await _invoke<void>('setAppLocale', {'preference': preference});
  }

  @override
  Future<AlarmSoundInfo> getAlarmSound() async {
    final raw = await _invoke<dynamic>('getAlarmSound');
    if (raw is Map) return AlarmSoundInfo.fromMap(raw);
    return const AlarmSoundInfo();
  }

  @override
  Future<AlarmSoundInfo?> pickAlarmSound() async {
    if (_isWidgetTestBinding) return null;
    try {
      final raw = await channel.invokeMethod<dynamic>('pickAlarmSoundFile');
      if (raw == null) return null;
      if (raw is Map) return AlarmSoundInfo.fromMap(raw);
      return null;
    } on PlatformException catch (e) {
      debugPrint('AndroidAlarmScheduler.pickAlarmSound failed: $e');
      rethrow;
    } catch (e) {
      debugPrint('AndroidAlarmScheduler.pickAlarmSound failed: $e');
      return null;
    }
  }

  @override
  Future<AlarmSoundInfo?> pickSystemRingtone() async {
    if (_isWidgetTestBinding) return null;
    try {
      final raw = await channel.invokeMethod<dynamic>('pickSystemRingtone');
      if (raw == null) return null;
      if (raw is Map) return AlarmSoundInfo.fromMap(raw);
      return null;
    } on PlatformException catch (e) {
      debugPrint('AndroidAlarmScheduler.pickSystemRingtone failed: $e');
      rethrow;
    } catch (e) {
      debugPrint('AndroidAlarmScheduler.pickSystemRingtone failed: $e');
      return null;
    }
  }

  @override
  Future<void> clearAlarmSound() async {
    await _invoke<void>('clearAlarmSound');
  }

  @override
  Future<bool> previewAlarmSound() async {
    final value = await _invoke<bool>('previewAlarmSound');
    return value ?? false;
  }

  @override
  Future<void> stopAlarmSoundPreview() async {
    await _invoke<void>('stopAlarmSoundPreview');
  }

  @override
  Future<bool> applyAlarmSoundBackup({
    String? source,
    String? fileName,
    String? displayName,
    String? ringtoneUri,
  }) async {
    final value = await _invoke<bool>('applyAlarmSoundBackup', {
      'source': source,
      'fileName': fileName,
      'displayName': displayName,
      'ringtoneUri': ringtoneUri,
    });
    return value ?? false;
  }
}
