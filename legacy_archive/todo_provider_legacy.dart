import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/capsule_model.dart';
import '../models/todo_model.dart';
import 'notification_service.dart';
import 'todo_database.dart';

enum TodoFilter {
  pending,
  completed,
  overdue,
  all;

  String get key => name;
}

enum TodoSortOrder {
  dueDateAsc,
  dueDateDesc,
  priorityDesc,
  createdAtDesc;

  String get key => name;
}

class TodoProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final TodoDatabase _db = TodoDatabase.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<TodoModel> _todos = [];
  bool _isLoading = true;
  TodoFilter _filter = TodoFilter.pending;
  TodoSortOrder _sortOrder = TodoSortOrder.dueDateAsc;
  String _searchQuery = '';
  String? _selectedTag;

  List<TodoModel> get todos => _todos;
  bool get isLoading => _isLoading;
  TodoFilter get filter => _filter;
  TodoSortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;

  TodoProvider() {
    _init();
  }

  Future<void> _init() async {
    _notifications.onNotificationAction = (payload, actionId) {
      if (payload != null && payload != 'DAILY_DIGEST') {
        if (actionId == 'ACTION_COMPLETE') {
          toggleTodoCompleted(payload);
        } else if (actionId == 'ACTION_SNOOZE_30') {
          snoozeTodo(payload, const Duration(minutes: 30));
        }
      }
    };
    await loadTodos();
  }

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      _todos = await _db.getAllTodos();
      if (_todos.isEmpty) {
        await _insertInitialSampleTodos();
      }
      _updateDailySummarySchedule();
    } catch (e) {
      debugPrint('Error loading todos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TodoModel> get pendingTodos =>
      _todos.where((t) => !t.isCompleted && !t.isOverdue()).toList();

  List<TodoModel> get completedTodos =>
      _todos.where((t) => t.isCompleted).toList();

  List<TodoModel> get overdueTodos =>
      _todos.where((t) => t.isOverdue()).toList();

  int get pendingCount => _todos.where((t) => !t.isCompleted).length;
  int get overdueCount => overdueTodos.length;

  List<TodoModel> get todayTodos {
    final now = DateTime.now();
    return _todos.where((t) => t.isDueOn(now)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<TodoModel> get todayPendingTodos {
    final now = DateTime.now();
    return _todos
        .where((t) => !t.isCompleted && (t.isDueOn(now) || t.isOverdue(now)))
        .toList()
      ..sort((a, b) {
        if (a.isOverdue(now) && !b.isOverdue(now)) return -1;
        if (!a.isOverdue(now) && b.isOverdue(now)) return 1;
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  List<TodoModel> getTodosForDate(DateTime date) {
    return _todos.where((t) => t.isDueOn(date)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<String> get allTags {
    final tags = <String>{};
    for (final t in _todos) {
      tags.addAll(t.tags);
    }
    return tags.toList()..sort();
  }

  List<TodoModel> get filteredTodos {
    final now = DateTime.now();
    List<TodoModel> result = [];

    switch (_filter) {
      case TodoFilter.pending:
        result =
            _todos.where((t) => !t.isCompleted && !t.isOverdue(now)).toList();
        break;
      case TodoFilter.completed:
        result = _todos.where((t) => t.isCompleted).toList();
        break;
      case TodoFilter.overdue:
        result = _todos.where((t) => t.isOverdue(now)).toList();
        break;
      case TodoFilter.all:
        result = List.from(_todos);
        break;
    }

    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      result = result.where((t) => t.tags.contains(_selectedTag)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query);
      }).toList();
    }

    // 排序
    switch (_sortOrder) {
      case TodoSortOrder.dueDateAsc:
        result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case TodoSortOrder.dueDateDesc:
        result.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case TodoSortOrder.priorityDesc:
        result.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TodoSortOrder.createdAtDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }

  void setFilter(TodoFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSortOrder(TodoSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  Future<TodoModel> addTodo({
    required String title,
    String description = '',
    required DateTime dueDate,
    DateTime? deadline,
    TodoPriority priority = TodoPriority.medium,
    bool isReminderEnabled = false,
    DateTime? reminderTime,
    TodoRepeatRule repeatRule = TodoRepeatRule.none,
    String? capsuleId,
    bool persistentReminder = true,
    List<String> tags = const [],
  }) async {
    final newTodo = TodoModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      deadline: deadline,
      isCompleted: false,
      priority: priority,
      isReminderEnabled: isReminderEnabled,
      reminderTime: reminderTime ?? (isReminderEnabled ? dueDate : null),
      repeatRule: repeatRule,
      capsuleId: capsuleId,
      persistentReminder: persistentReminder,
      tags: tags,
    );

    await _db.insertTodo(newTodo);
    _todos.insert(0, newTodo);
    notifyListeners();

    if (newTodo.isReminderEnabled) {
      await _notifications.scheduleTodoReminder(newTodo);
    }
    _updateDailySummarySchedule();

    return newTodo;
  }

  Future<void> updateTodo(TodoModel updated) async {
    final index = _todos.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      final old = _todos[index];
      _todos[index] = updated;
      notifyListeners();

      await _db.updateTodo(updated);

      // 取消舊通知並重新排程
      await _notifications.cancelReminder(old.id);
      if (updated.isReminderEnabled && !updated.isCompleted) {
        await _notifications.scheduleTodoReminder(updated);
      }
      _updateDailySummarySchedule();
    }
  }

  Future<void> toggleTodoCompleted(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _todos[index];
      final newStatus = !current.isCompleted;

      final updated = current.copyWith(
        isCompleted: newStatus,
        completedAt: newStatus ? DateTime.now() : null,
      );

      _todos[index] = updated;
      notifyListeners();
      await _db.updateTodo(updated);

      if (newStatus) {
        // 完成時取消通知
        await _notifications.cancelReminder(id);

        // 若為重複待辦，自動產生下一期待辦
        if (current.repeatRule != TodoRepeatRule.none) {
          final nextDueDate = current.calculateNextDueDate();
          final nextTodo = TodoModel(
            id: _uuid.v4(),
            title: current.title,
            description: current.description,
            createdAt: DateTime.now(),
            dueDate: nextDueDate,
            deadline: current.deadline != null
                ? nextDueDate.add(current.deadline!.difference(current.dueDate))
                : null,
            isCompleted: false,
            priority: current.priority,
            isReminderEnabled: current.isReminderEnabled,
            reminderTime: current.reminderTime != null
                ? nextDueDate
                    .add(current.reminderTime!.difference(current.dueDate))
                : null,
            repeatRule: current.repeatRule,
            capsuleId: current.capsuleId,
            persistentReminder: current.persistentReminder,
            tags: current.tags,
          );
          await _db.insertTodo(nextTodo);
          _todos.insert(0, nextTodo);
          notifyListeners();
          if (nextTodo.isReminderEnabled) {
            await _notifications.scheduleTodoReminder(nextTodo);
          }
        }
      } else {
        // 恢復為未完成，若原本有開啟提醒則重新排程
        if (updated.isReminderEnabled) {
          await _notifications.scheduleTodoReminder(updated);
        }
      }

      _updateDailySummarySchedule();
    }
  }

  Future<void> snoozeTodo(String id, Duration duration) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _todos[index];
      final snoozeTime = DateTime.now().add(duration);
      final updated = current.copyWith(
        snoozeUntil: snoozeTime,
        isReminderEnabled: true,
      );

      _todos[index] = updated;
      notifyListeners();
      await _db.updateTodo(updated);
      await _notifications.scheduleTodoReminder(updated);
    }
  }

  Future<void> deleteTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos.removeAt(index);
      notifyListeners();
      await _db.deleteTodo(id);
      await _notifications.cancelReminder(id);
      _updateDailySummarySchedule();
    }
  }

  Future<List<TodoModel>> importFromCapsule(CapsuleModel capsule) async {
    final createdTodos = <TodoModel>[];
    final now = DateTime.now();
    final todayDue = DateTime(now.year, now.month, now.day, 18, 0);

    if (capsule.actionItems.isNotEmpty) {
      for (final action in capsule.actionItems) {
        final todo = await addTodo(
          title: action,
          description: '來自膠囊：${capsule.title}',
          dueDate: todayDue,
          priority: TodoPriority.medium,
          isReminderEnabled: true,
          capsuleId: capsule.id,
          tags: capsule.tags,
        );
        createdTodos.add(todo);
      }
    } else {
      final todo = await addTodo(
        title: capsule.title.isNotEmpty ? capsule.title : '膠囊記事待辦',
        description: capsule.summary.isNotEmpty
            ? capsule.summary
            : capsule.rawTranscript,
        dueDate: todayDue,
        priority: TodoPriority.medium,
        isReminderEnabled: true,
        capsuleId: capsule.id,
        tags: capsule.tags,
      );
      createdTodos.add(todo);
    }

    return createdTodos;
  }

  void _updateDailySummarySchedule() {
    _notifications.scheduleDailyDigestSummary(pendingCount, overdueCount);
  }

  Future<void> _insertInitialSampleTodos() async {
    final now = DateTime.now();
    final sample1 = TodoModel(
      id: _uuid.v4(),
      title: '檢視今日靈感便籤與待辦清單',
      description: '熟悉 Capsule Note 四大入口與極簡操作',
      createdAt: now.subtract(const Duration(hours: 2)),
      dueDate: DateTime(now.year, now.month, now.day, 18, 0),
      isCompleted: false,
      priority: TodoPriority.high,
      isReminderEnabled: true,
      tags: ['日常', '導覽'],
    );

    final sample2 = TodoModel(
      id: _uuid.v4(),
      title: '每週專案進度覆盤',
      description: '整理團隊週會決議事項與膠囊錄音重點',
      createdAt: now.subtract(const Duration(days: 1)),
      dueDate: DateTime(now.year, now.month, now.day, 20, 0),
      isCompleted: false,
      priority: TodoPriority.medium,
      repeatRule: TodoRepeatRule.weekly,
      isReminderEnabled: true,
      tags: ['工作'],
    );

    await _db.insertTodo(sample1);
    await _db.insertTodo(sample2);
    _todos = [sample1, sample2];
  }
}
