import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import 'todo_edit_screen.dart';
import 'widgets/todo_card.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todoProvider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTodos,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<TodoSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: '排序方式',
            onSelected: (order) => todoProvider.setSortOrder(order),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TodoSortOrder.dueDateAsc,
                child: Text('依日期 (由近至遠)'),
              ),
              const PopupMenuItem(
                value: TodoSortOrder.dueDateDesc,
                child: Text('依日期 (由遠至近)'),
              ),
              const PopupMenuItem(
                value: TodoSortOrder.priorityDesc,
                child: Text('依優先級別 (高至低)'),
              ),
              const PopupMenuItem(
                value: TodoSortOrder.createdAtDesc,
                child: Text('依建立時間 (最新優先)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜尋欄
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                ),
              ),
              child: TextField(
                onChanged: (val) => todoProvider.setSearchQuery(val),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '${l10n.filterAll}...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.nightSecondary
                        : AppTheme.inkSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark
                        ? AppTheme.nightSecondary
                        : AppTheme.inkSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // 分類篩選頁籤
          Container(
            height: 42,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFilterTab(
                  context,
                  label: '${l10n.filterPending} (${todoProvider.pendingCount})',
                  filter: TodoFilter.pending,
                  isSelected: todoProvider.filter == TodoFilter.pending,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  context,
                  label: '${l10n.filterOverdue} (${todoProvider.overdueCount})',
                  filter: TodoFilter.overdue,
                  isSelected: todoProvider.filter == TodoFilter.overdue,
                  isAlert: todoProvider.overdueCount > 0,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  context,
                  label:
                      '${l10n.filterCompleted} (${todoProvider.completedTodos.length})',
                  filter: TodoFilter.completed,
                  isSelected: todoProvider.filter == TodoFilter.completed,
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  context,
                  label: '${l10n.filterAll} (${todoProvider.todos.length})',
                  filter: TodoFilter.all,
                  isSelected: todoProvider.filter == TodoFilter.all,
                ),
              ],
            ),
          ),

          // 標籤篩選列
          if (todoProvider.allTags.isNotEmpty)
            Container(
              height: 34,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...todoProvider.allTags.map((tag) {
                    final isSelected = todoProvider.selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label:
                            Text('#$tag', style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (_) {
                          todoProvider.setSelectedTag(isSelected ? null : tag);
                        },
                        backgroundColor: isDark
                            ? AppTheme.nightCard
                            : AppTheme.paperWhiteCard,
                        selectedColor: isDark
                            ? AppTheme.nightHighlight
                            : AppTheme.inkHighlightLight,
                        checkmarkColor: AppTheme.inkBlue,
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.nightBorder
                              : AppTheme.inkBorderLight,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // 待辦清單內容
          Expanded(
            child: todoProvider.isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : todoProvider.filteredTodos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_outlined,
                              size: 56,
                              color: isDark
                                  ? AppTheme.nightSecondary
                                  : AppTheme.inkSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.emptyCapsulesTitle,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.addTodo,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppTheme.nightSecondary
                                    : AppTheme.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                        itemCount: todoProvider.filteredTodos.length,
                        itemBuilder: (context, index) {
                          final todo = todoProvider.filteredTodos[index];
                          return TodoCard(todo: todo);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.inkBlue,
        foregroundColor: Colors.white,
        tooltip: l10n.addTodo,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TodoEditScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context, {
    required String label,
    required TodoFilter filter,
    required bool isSelected,
    bool isAlert = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isAlert && !isSelected ? Colors.redAccent : null,
        ),
      ),
      selected: isSelected,
      selectedColor: isAlert
          ? Colors.redAccent.withValues(alpha: 0.2)
          : (isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight),
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      side: BorderSide(
        color: isAlert
            ? Colors.redAccent.withValues(alpha: 0.5)
            : (isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight),
      ),
      onSelected: (_) => todoProvider.setFilter(filter),
    );
  }
}
