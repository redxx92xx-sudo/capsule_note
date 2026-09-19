import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/backup_data.dart';
import 'database_service.dart';
import 'notification_port.dart';
import 'alarm_port.dart';
import 'reminder_scheduler.dart';

class BackupService {
  final DatabaseService _dbService;
  final ReminderScheduler _scheduler;

  BackupService({DatabaseService? dbService, ReminderScheduler? scheduler})
    : _dbService = dbService ?? DatabaseService.instance,
      _scheduler =
          scheduler ??
          ReminderScheduler(dbService: dbService ?? DatabaseService.instance);

  static final BackupService instance = BackupService();

  /// 匯出備份 JSON 檔案並透過系統分享傳送
  Future<String> exportBackup() async {
    final todos = await _dbService.getAllTodos();
    final now = DateTime.now();

    final isDarkMode = await _dbService.getSetting('is_dark_mode') ?? 'false';
    final dailySummaryEnabled =
        await _dbService.getSetting('daily_summary_enabled') ?? 'true';
    final dailySummaryTime =
        await _dbService.getSetting('daily_summary_time') ?? '09:00';
    final persistentInterval =
        await _dbService.getSetting('persistent_interval_minutes') ?? '60';
    final persistentDailyMax =
        await _dbService.getSetting('persistent_daily_max') ?? '6';
    final themeMode = await _dbService.getSetting('theme_mode') ?? 'system';
    final appLocale = await _dbService.getSetting('app_locale') ?? 'system';
    final alarmSoundFile =
        await _dbService.getSetting('alarm_sound_file') ?? '';
    final alarmSoundDisplay =
        await _dbService.getSetting('alarm_sound_display') ?? '';
    final ringtoneSource =
        await _dbService.getSetting('ringtone_source') ?? 'default';
    final ringtoneUri = await _dbService.getSetting('ringtone_uri') ?? '';

    final backup = BackupData(
      schemaVersion: BackupData.currentSchemaVersion,
      exportedAt: now,
      appVersion: '1.0.2+3',
      appName: 'Capsule Note',
      totalCount: todos.length,
      completedCount: todos.where((t) => t.isCompleted).length,
      uncompletedCount: todos.where((t) => !t.isCompleted).length,
      todos: todos,
      appSettings: {
        'is_dark_mode': isDarkMode,
        'theme_mode': themeMode,
        'app_locale': appLocale,
        'daily_summary_enabled': dailySummaryEnabled,
        'daily_summary_time': dailySummaryTime,
        'persistent_interval_minutes': persistentInterval,
        'persistent_daily_max': persistentDailyMax,
        // Ringtone metadata only — never embed audio bytes.
        'ringtone_source': ringtoneSource,
        'ringtone_uri': ringtoneUri,
        'alarm_sound_file': alarmSoundFile,
        'alarm_sound_display': alarmSoundDisplay,
        'exported_time': now.toIso8601String(),
      },
    );

    final jsonContent = backup.toJson();
    final formatter = DateFormat('yyyyMMdd_HHmm');
    final fileName = 'capsule_note_backup_${formatter.format(now)}.json';

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(jsonContent);

    // 透過 share_plus 分享檔案
    await Share.shareXFiles([
      XFile(file.path, name: fileName),
    ], text: '提醒Kath 待辦事項備份檔案 ($fileName)');

    return file.path;
  }

  /// 匯入並還原備份檔案
  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.first.path == null) {
        return false;
      }

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final validationResult = validateBackupContent(content);

      if (!validationResult.isValid || validationResult.data == null) {
        throw Exception(validationResult.errorMessage ?? '無效的備份檔案格式');
      }

      return await restoreBackup(validationResult.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// 驗證備份檔案內容
  BackupValidationResult validateBackupContent(String jsonString) {
    return BackupData.validateAndParse(jsonString);
  }

  /// 執行還原（在單一交易中完成，並在完成後重新排程提醒）
  Future<bool> restoreBackup(BackupData backupData) async {
    try {
      await _dbService.replaceAllTodosInTransaction(
        backupData.todos,
        backupData.appSettings,
      );
    } catch (_) {
      return false;
    }

    try {
      if (NotificationPort.isConfigured) {
        await NotificationPort.instance.cancelAll();
      }
      if (AlarmPort.isConfigured) {
        await AlarmPort.instance.cancelAll();
      }
      await _scheduler.syncAllReminders();
    } catch (_) {
      // 資料已還原；鬧鐘會在下次啟動／重開機核對時補齊。
    }
    return true;
  }
}
