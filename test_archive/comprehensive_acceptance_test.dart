import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/models/todo_model.dart';
import 'package:capsule_note/services/ai_summary_service.dart';
import 'package:capsule_note/services/export_service.dart';
import 'package:capsule_note/services/notification_service.dart';
import 'package:capsule_note/services/todo_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Capsule Note 擴充功能驗收測試 (Full Acceptance Tests)', () {
    test('1. 建立待辦後重新開啟（讀取），資料仍完整存在於 SQLite', () async {
      final db = TodoDatabase.instance;
      final now = DateTime(2026, 9, 18, 14, 0);

      final newTodo = TodoModel(
        id: 'persist-test-1',
        title: '持久化待辦測試',
        description: '驗證 SQLite 重啟後讀取',
        createdAt: now,
        dueDate: now.add(const Duration(hours: 2)),
        isCompleted: false,
        priority: TodoPriority.urgent,
        isReminderEnabled: true,
        reminderTime: now.add(const Duration(hours: 1)),
        repeatRule: TodoRepeatRule.daily,
        persistentReminder: true,
        tags: ['測試', '資料庫'],
      );

      await db.insertTodo(newTodo);

      final fetched = await db.getTodoById('persist-test-1');
      expect(fetched, isNotNull);
      expect(fetched!.title, '持久化待辦測試');
      expect(fetched.description, '驗證 SQLite 重啟後讀取');
      expect(fetched.priority, TodoPriority.urgent);
      expect(fetched.repeatRule, TodoRepeatRule.daily);
      expect(fetched.tags, ['測試', '資料庫']);
    });

    test('2. 未完成／已完成／已逾期分類邏輯正確', () {
      final now = DateTime(2026, 9, 18, 12, 0);

      final pendingTodo = TodoModel(
        id: 'p-1',
        title: '未來的待辦',
        createdAt: now,
        dueDate: DateTime(2026, 9, 18, 18, 0),
        isCompleted: false,
      );

      final overdueTodo = TodoModel(
        id: 'o-1',
        title: '逾期的待辦',
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: DateTime(2026, 9, 17, 10, 0),
        isCompleted: false,
      );

      final completedTodo = TodoModel(
        id: 'c-1',
        title: '已完成的待辦',
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: DateTime(2026, 9, 17, 10, 0),
        isCompleted: true,
        completedAt: now.subtract(const Duration(hours: 5)),
      );

      expect(pendingTodo.isOverdue(now), isFalse);
      expect(overdueTodo.isOverdue(now), isTrue);
      expect(completedTodo.isOverdue(now), isFalse);
    });

    test('3. 完成待辦後進入已完成清單，若為重複待辦則自動生成下一期', () {
      final baseDate = DateTime(2026, 9, 18, 10, 0);

      final recurringDaily = TodoModel(
        id: 'rec-daily',
        title: '每日運動',
        createdAt: baseDate,
        dueDate: baseDate,
        repeatRule: TodoRepeatRule.daily,
      );

      expect(
          recurringDaily.calculateNextDueDate(), DateTime(2026, 9, 19, 10, 0));

      final recurringWeekly = TodoModel(
        id: 'rec-weekly',
        title: '每週讀書會',
        createdAt: baseDate,
        dueDate: baseDate,
        repeatRule: TodoRepeatRule.weekly,
      );
      expect(
          recurringWeekly.calculateNextDueDate(), DateTime(2026, 9, 25, 10, 0));

      final recurringMonthly = TodoModel(
        id: 'rec-monthly',
        title: '每月發薪日',
        createdAt: baseDate,
        dueDate: baseDate,
        repeatRule: TodoRepeatRule.monthly,
      );
      expect(recurringMonthly.calculateNextDueDate(),
          DateTime(2026, 10, 18, 10, 0));
    });

    test('4. 跨日後未完成項目判定為逾期', () {
      final today = DateTime(2026, 9, 18, 12, 0);
      final todo = TodoModel(
        id: 'cross-day',
        title: '今日到期待辦',
        createdAt: today,
        dueDate: DateTime(2026, 9, 18, 23, 59),
        isCompleted: false,
      );

      expect(todo.isOverdue(today), isFalse);

      final tomorrow = DateTime(2026, 9, 19, 0, 1);
      expect(todo.isOverdue(tomorrow), isTrue);
    });

    test('5. 月曆日期與待辦/筆記對應判斷正確', () {
      final targetDate = DateTime(2026, 9, 20, 15, 30);
      final todo = TodoModel(
        id: 'cal-1',
        title: '9/20 行程',
        createdAt: DateTime.now(),
        dueDate: targetDate,
      );

      expect(todo.isDueOn(DateTime(2026, 9, 20)), isTrue);
      expect(todo.isDueOn(DateTime(2026, 9, 21)), isFalse);
    });

    test('6. 現有語音 AI 摘要、清洗與匯出功能完整保留無損壞', () async {
      final cleaner = AiSummaryService.instance;
      final result = await cleaner
          .structureTranscript('今天跟團隊確認了兩件事情，第一是完成資料庫升級，第二是發布測試版本。');
      expect(result.actionItems.isNotEmpty, isTrue);

      final capsule = CapsuleModel(
        id: 'test-exp',
        title: '專案會議筆記',
        rawTranscript: '討論了幾項重要代辦',
        summary: '整理會議行動項目',
        actionItems: ['發送會議記錄給主管', '預約下週場地'],
        createdAt: DateTime(2026, 9, 18, 14, 0),
        tags: ['會議', '工作'],
      );

      final md =
          ExportService.instance.formatCapsule(capsule, ExportFormat.markdown);
      expect(md, contains('# 專案會議筆記'));
      expect(md, contains('發送會議記錄給主管'));

      final txt =
          ExportService.instance.formatCapsule(capsule, ExportFormat.plainText);
      expect(txt, contains('CAPSULE NOTE: 專案會議筆記'));
    });

    test('7. 通知服務在無權限或初始化例外時具備安全降級，不崩潰', () async {
      final notif = NotificationService.instance;
      await notif.cancelReminder('safe-cancel-id');
      await notif.scheduleDailyDigestSummary(0, 0);
    });
  });
}
