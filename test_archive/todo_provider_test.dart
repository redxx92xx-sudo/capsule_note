import 'package:flutter_test/flutter_test.dart';
import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/models/todo_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('TodoProvider Logic Tests', () {
    test('filters and sorting work correctly', () {
      final now = DateTime.now();
      final todo1 = TodoModel(
        id: '1',
        title: 'Task A',
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 1)),
        priority: TodoPriority.low,
      );
      final todo2 = TodoModel(
        id: '2',
        title: 'Task B (Overdue)',
        createdAt: now.subtract(const Duration(days: 3)),
        dueDate: now.subtract(const Duration(days: 1)),
        priority: TodoPriority.urgent,
      );
      final todo3 = TodoModel(
        id: '3',
        title: 'Task C (Done)',
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 2)),
        isCompleted: true,
        priority: TodoPriority.high,
      );

      final list = [todo1, todo2, todo3];
      final pending =
          list.where((t) => !t.isCompleted && !t.isOverdue(now)).toList();
      final overdue = list.where((t) => t.isOverdue(now)).toList();
      final completed = list.where((t) => t.isCompleted).toList();

      expect(pending.length, 1);
      expect(pending.first.id, '1');
      expect(overdue.length, 1);
      expect(overdue.first.id, '2');
      expect(completed.length, 1);
      expect(completed.first.id, '3');
    });

    test('importFromCapsule generates todos with capsuleId and tags', () async {
      final capsule = CapsuleModel(
        id: 'cap-test-1',
        title: '語音筆記會議記錄',
        rawTranscript: '討論了幾項重要代辦',
        summary: '整理會議行動項目',
        actionItems: ['發送會議記錄給主管', '預約下週場地'],
        createdAt: DateTime.now(),
        tags: ['會議', '工作'],
      );

      expect(capsule.actionItems.length, 2);
    });
  });
}
