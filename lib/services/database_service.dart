import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/reminder_schedule.dart';
import '../models/todo_item.dart';
import '../utils/rk_trace.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  /// Tests set this to false so a closed in-memory DB cannot fall back to a
  /// real file database (which would hang on the sqflite MethodChannel).
  static bool allowFallbackInit = true;

  DatabaseService._internal();

  factory DatabaseService({Database? customDb}) {
    if (customDb != null) {
      final customService = DatabaseService._internal();
      customService._db = customDb;
      return customService;
    }
    return instance;
  }

  Database? _db;
  int _pendingOps = 0;

  void setCustomDb(Database customDb) {
    _db = customDb;
    _pendingOps = 0;
  }

  void clearTestDb() {
    _db = null;
    _pendingOps = 0;
  }

  Future<T> _guard<T>(String label, Future<T> Function() op) async {
    _pendingOps++;
    rkTrace('db.$label start pending=$_pendingOps');
    try {
      return await op();
    } finally {
      _pendingOps--;
      rkTrace('db.$label done pending=$_pendingOps');
    }
  }

  Future<void> waitForIdle({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    await Future<void>.delayed(Duration.zero);
    while (_pendingOps > 0) {
      if (DateTime.now().isAfter(deadline)) {
        rkTrace(
          'db.waitForIdle TIMEOUT pending=$_pendingOps; continue without throw',
        );
        return;
      }
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    if (!allowFallbackInit) {
      throw StateError('測試資料庫尚未設定或已關閉，拒絕回落到真實檔案 DB / MethodChannel');
    }
    rkTrace('db._initDatabase await');
    _db = await _initDatabase();
    rkTrace('db._initDatabase done');
    return _db!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;
    try {
      rkTrace('db.getDatabasesPath await');
      final databasesPath = await databaseFactory.getDatabasesPath();
      dbPath = p.join(databasesPath, 'capsule_note.db');
    } catch (_) {
      dbPath = inMemoryDatabasePath;
    }

    rkTrace('db.openDatabase await path=$dbPath');
    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await createScheduleTable(db);
          }
          if (oldVersion < 3) {
            await addReminderKindColumn(db);
          }
        },
      ),
    );
  }

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        reminder_time TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        repeat_rule TEXT NOT NULL DEFAULT 'none',
        repeat_days TEXT,
        snooze_until TEXT,
        is_persistent_reminder INTEGER NOT NULL DEFAULT 0,
        persistent_interval_minutes INTEGER NOT NULL DEFAULT 60,
        persistent_reminder_count_today INTEGER NOT NULL DEFAULT 0,
        last_persistent_reminder_date TEXT,
        next_reminder_time TEXT,
        reminder_kind TEXT NOT NULL DEFAULT 'notification',
        data_version INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_todos_scheduled_date ON todos(scheduled_date)',
    );
    await db.execute(
      'CREATE INDEX idx_todos_is_completed ON todos(is_completed)',
    );
    await db.execute('CREATE INDEX idx_todos_priority ON todos(priority)');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await createScheduleTable(db);
  }

  static Future<void> addReminderKindColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(todos)');
    final hasKind = columns.any((row) => row['name'] == 'reminder_kind');
    if (hasKind) return;
    await db.execute(
      "ALTER TABLE todos ADD COLUMN reminder_kind TEXT NOT NULL DEFAULT 'notification'",
    );
  }

  static Future<void> createScheduleTable(Database db) async {
    await db.execute('''
      CREATE TABLE reminder_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id TEXT,
        notification_id INTEGER NOT NULL UNIQUE,
        trigger_time TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_schedules_todo ON reminder_schedules(todo_id)',
    );
    await db.execute(
      'CREATE INDEX idx_schedules_trigger ON reminder_schedules(trigger_time)',
    );
  }

  Future<List<TodoItem>> getAllTodos() {
    return _guard('getAllTodos', () async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'todos',
        orderBy: 'scheduled_date ASC, reminder_time ASC, priority DESC',
      );
      return maps.map((m) => TodoItem.fromMap(m)).toList();
    });
  }

  Future<TodoItem?> getTodoById(String id) {
    return _guard('getTodoById', () async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return TodoItem.fromMap(maps.first);
    });
  }

  Future<int> insertTodo(TodoItem todo) {
    return _guard('insertTodo', () async {
      final db = await database;
      return db.insert(
        'todos',
        todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<int> updateTodo(TodoItem todo) {
    return _guard('updateTodo', () async {
      final db = await database;
      return db.update(
        'todos',
        todo.toMap(),
        where: 'id = ?',
        whereArgs: [todo.id],
      );
    });
  }

  Future<int> deleteTodo(String id) {
    return _guard('deleteTodo', () async {
      final db = await database;
      return db.delete('todos', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> replaceAllTodosInTransaction(
    List<TodoItem> todos,
    Map<String, dynamic> settings,
  ) {
    return _guard('replaceAllTodosInTransaction', () async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('todos');
        await txn.delete('reminder_schedules');
        for (final todo in todos) {
          await txn.insert('todos', todo.toMap());
        }
        for (final entry in settings.entries) {
          await txn.insert('app_settings', {
            'key': entry.key,
            'value': entry.value.toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    });
  }

  Future<String?> getSetting(String key) {
    return _guard('getSetting:$key', () async {
      final db = await database;
      final maps = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return maps.first['value'] as String?;
    });
  }

  Future<void> setSetting(String key, String value) {
    return _guard('setSetting:$key', () async {
      final db = await database;
      await db.insert('app_settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<ReminderScheduleRecord>> getSchedules({
    String? todoId,
    String? type,
  }) {
    return _guard('getSchedules', () async {
      final db = await database;
      final where = <String>[];
      final args = <Object?>[];
      if (todoId != null) {
        where.add('todo_id = ?');
        args.add(todoId);
      }
      if (type != null) {
        where.add('type = ?');
        args.add(type);
      }
      final maps = await db.query(
        'reminder_schedules',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'trigger_time ASC',
      );
      return maps.map(ReminderScheduleRecord.fromMap).toList();
    });
  }

  Future<ReminderScheduleRecord?> findSchedule({
    String? todoId,
    required String type,
    required DateTime triggerTime,
  }) {
    return _guard('findSchedule', () async {
      final db = await database;
      final maps = await db.query(
        'reminder_schedules',
        where: todoId == null
            ? 'todo_id IS NULL AND type = ? AND trigger_time = ?'
            : 'todo_id = ? AND type = ? AND trigger_time = ?',
        whereArgs: todoId == null
            ? [type, triggerTime.toIso8601String()]
            : [todoId, type, triggerTime.toIso8601String()],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return ReminderScheduleRecord.fromMap(maps.first);
    });
  }

  Future<int> countSchedules() {
    return _guard('countSchedules', () async {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM reminder_schedules',
      );
      return (result.first['c'] as int?) ?? 0;
    });
  }

  Future<void> insertSchedule(ReminderScheduleRecord record) {
    return _guard('insertSchedule', () async {
      final db = await database;
      await db.insert('reminder_schedules', {
        'todo_id': record.todoId,
        'notification_id': record.notificationId,
        'trigger_time': record.triggerTime.toIso8601String(),
        'type': record.type,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> deleteScheduleById(int id) {
    return _guard('deleteScheduleById', () async {
      final db = await database;
      await db.delete('reminder_schedules', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<ReminderScheduleRecord>> deleteSchedulesForTodo(String todoId) {
    return _guard('deleteSchedulesForTodo', () async {
      final db = await database;
      final maps = await db.query(
        'reminder_schedules',
        where: 'todo_id = ?',
        whereArgs: [todoId],
      );
      final records = maps.map(ReminderScheduleRecord.fromMap).toList();
      await db.delete(
        'reminder_schedules',
        where: 'todo_id = ?',
        whereArgs: [todoId],
      );
      return records;
    });
  }

  Future<List<ReminderScheduleRecord>> deleteSchedulesOfType(String type) {
    return _guard('deleteSchedulesOfType', () async {
      final db = await database;
      final maps = await db.query(
        'reminder_schedules',
        where: 'type = ?',
        whereArgs: [type],
      );
      final records = maps.map(ReminderScheduleRecord.fromMap).toList();
      await db.delete(
        'reminder_schedules',
        where: 'type = ?',
        whereArgs: [type],
      );
      return records;
    });
  }

  Future<List<ReminderScheduleRecord>> deleteExpiredSchedules(DateTime cutoff) {
    return _guard('deleteExpiredSchedules', () async {
      final db = await database;
      final maps = await db.query(
        'reminder_schedules',
        where: 'trigger_time < ?',
        whereArgs: [cutoff.toIso8601String()],
      );
      final records = maps.map(ReminderScheduleRecord.fromMap).toList();
      await db.delete(
        'reminder_schedules',
        where: 'trigger_time < ?',
        whereArgs: [cutoff.toIso8601String()],
      );
      return records;
    });
  }

  Future<void> close() async {
    await waitForIdle();
    if (_db != null && _db!.isOpen) {
      rkTrace('db.close await');
      await _db!.close();
      _db = null;
    }
  }
}
