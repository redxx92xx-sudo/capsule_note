import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/todo_model.dart';

class TodoDatabase {
  static final TodoDatabase instance = TodoDatabase._init();
  static Database? _database;

  TodoDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('capsule_todos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        deadline TEXT,
        isCompleted INTEGER NOT NULL,
        completedAt TEXT,
        priority TEXT NOT NULL,
        isReminderEnabled INTEGER NOT NULL,
        reminderTime TEXT,
        repeatRule TEXT NOT NULL,
        snoozeUntil TEXT,
        lastRemindedAt TEXT,
        capsuleId TEXT,
        schemaVersion INTEGER NOT NULL,
        persistentReminder INTEGER NOT NULL,
        tags TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_todos_dueDate ON todos(dueDate);');
    await db
        .execute('CREATE INDEX idx_todos_isCompleted ON todos(isCompleted);');
    await db.execute('CREATE INDEX idx_todos_capsuleId ON todos(capsuleId);');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 預留未來資料庫版本升級
    debugPrint('Upgrading database from $oldVersion to $newVersion');
  }

  Future<TodoModel> insertTodo(TodoModel todo) async {
    final db = await database;
    await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return todo;
  }

  Future<int> updateTodo(TodoModel todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(String id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TodoModel>> getAllTodos() async {
    final db = await database;
    final maps =
        await db.query('todos', orderBy: 'dueDate ASC, createdAt DESC');
    return maps.map((map) => TodoModel.fromMap(map)).toList();
  }

  Future<TodoModel?> getTodoById(String id) async {
    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return TodoModel.fromMap(maps.first);
    }
    return null;
  }

  Future<List<TodoModel>> getTodosByCapsuleId(String capsuleId) async {
    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'capsuleId = ?',
      whereArgs: [capsuleId],
    );
    return maps.map((map) => TodoModel.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
