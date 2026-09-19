import 'package:flutter_test/flutter_test.dart';
import 'package:capsule_note/models/todo_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TodoModel Tests', () {
    test('serialization and deserialization with all fields', () {
      final now = DateTime.now();
      final todo = TodoModel(
        id: 'todo-123',
        title: '買牛奶與麵包',
        description: '全聯特價中',
        createdAt: now,
        dueDate: now.add(const Duration(days: 1)),
        deadline: now.add(const Duration(days: 1, hours: 2)),
        isCompleted: false,
        priority: TodoPriority.urgent,
        isReminderEnabled: true,
        reminderTime: now.add(const Duration(hours: 3)),
        repeatRule: TodoRepeatRule.daily,
        snoozeUntil: null,
        lastRemindedAt: null,
        capsuleId: 'capsule-999',
        schemaVersion: 1,
        persistentReminder: true,
        tags: ['生活', '購物'],
      );

      final map = todo.toMap();
      final restored = TodoModel.fromMap(map);

      expect(restored.id, todo.id);
      expect(restored.title, todo.title);
      expect(restored.description, todo.description);
      expect(restored.priority, TodoPriority.urgent);
      expect(restored.repeatRule, TodoRepeatRule.daily);
      expect(restored.capsuleId, 'capsule-999');
      expect(restored.tags, ['生活', '購物']);
      expect(restored.persistentReminder, true);
    });

    test('isOverdue logic works correctly', () {
      final now = DateTime.now();
      final pastTodo = TodoModel(
        id: 'todo-past',
        title: '過期的工作',
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: now.subtract(const Duration(days: 1)),
        isCompleted: false,
      );

      expect(pastTodo.isOverdue(now), isTrue);

      final completedPastTodo = pastTodo.copyWith(isCompleted: true);
      expect(completedPastTodo.isOverdue(now), isFalse);

      final futureTodo = TodoModel(
        id: 'todo-future',
        title: '未來的工作',
        createdAt: now,
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
      );
      expect(futureTodo.isOverdue(now), isFalse);
    });

    test('repeat rule calculates next due date correctly', () {
      final baseDate = DateTime(2026, 9, 18, 10, 0);
      final dailyTodo = TodoModel(
        id: 'daily',
        title: '每日運動',
        createdAt: baseDate,
        dueDate: baseDate,
        repeatRule: TodoRepeatRule.daily,
      );
      expect(dailyTodo.calculateNextDueDate(), DateTime(2026, 9, 19, 10, 0));

      final weeklyTodo = TodoModel(
        id: 'weekly',
        title: '每週週會',
        createdAt: baseDate,
        dueDate: baseDate,
        repeatRule: TodoRepeatRule.weekly,
      );
      expect(weeklyTodo.calculateNextDueDate(), DateTime(2026, 9, 25, 10, 0));

      final monthlyTodo = TodoModel(
        id: 'monthly',
        title: '每月帳單',
        createdAt: baseDate,
        dueDate: baseDate,
        repeatRule: TodoRepeatRule.monthly,
      );
      expect(monthlyTodo.calculateNextDueDate(), DateTime(2026, 10, 18, 10, 0));
    });
  });
}
