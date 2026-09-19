import 'dart:convert';

import 'todo_item.dart';

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupData? data;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.data,
  });
}

class BackupData {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final String appName;
  final int totalCount;
  final int completedCount;
  final int uncompletedCount;
  final List<TodoItem> todos;
  final Map<String, dynamic> appSettings;

  const BackupData({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    this.appName = 'Capsule Note',
    required this.totalCount,
    required this.completedCount,
    required this.uncompletedCount,
    required this.todos,
    this.appSettings = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'appName': appName,
      'totalCount': totalCount,
      'completedCount': completedCount,
      'uncompletedCount': uncompletedCount,
      'todos': todos.map((t) => t.toMap()).toList(),
      'appSettings': appSettings,
    };
  }

  String toJson() => jsonEncode(toMap());

  static BackupValidationResult validateAndParse(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: '備份檔案格式不正確（不是有效的 JSON 物件）',
        );
      }

      final schemaVersion = decoded['schemaVersion'] as int?;
      if (schemaVersion == null) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: '缺少備份版本號 (schemaVersion)',
        );
      }

      if (schemaVersion > currentSchemaVersion) {
        return BackupValidationResult(
          isValid: false,
          errorMessage:
              '此備份版本 (v$schemaVersion) 高於目前 App 支援版本 (v$currentSchemaVersion)，請升級 App 後再試',
        );
      }

      final todosRaw = decoded['todos'];
      if (todosRaw is! List) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: '備份檔案缺少待辦清單內容 (todos)',
        );
      }

      final List<TodoItem> parsedTodos = [];
      for (final item in todosRaw) {
        if (item is! Map<String, dynamic>) {
          return const BackupValidationResult(
            isValid: false,
            errorMessage: '待辦事項格式異常',
          );
        }
        if (!item.containsKey('id') || !item.containsKey('title')) {
          return const BackupValidationResult(
            isValid: false,
            errorMessage: '待辦資料缺少必要欄位（ID 或標題）',
          );
        }
        parsedTodos.add(TodoItem.fromMap(item));
      }

      final exportedAt = decoded['exportedAt'] != null
          ? DateTime.tryParse(decoded['exportedAt'] as String) ?? DateTime.now()
          : DateTime.now();

      final data = BackupData(
        schemaVersion: schemaVersion,
        exportedAt: exportedAt,
        appVersion: decoded['appVersion'] as String? ?? '1.0.0',
        appName: decoded['appName'] as String? ?? 'Capsule Note',
        totalCount: parsedTodos.length,
        completedCount: parsedTodos.where((t) => t.isCompleted).length,
        uncompletedCount: parsedTodos.where((t) => !t.isCompleted).length,
        todos: parsedTodos,
        appSettings: decoded['appSettings'] is Map<String, dynamic>
            ? decoded['appSettings'] as Map<String, dynamic>
            : {},
      );

      return BackupValidationResult(isValid: true, data: data);
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: '解析備份檔案時發生錯誤：$e',
      );
    }
  }
}
