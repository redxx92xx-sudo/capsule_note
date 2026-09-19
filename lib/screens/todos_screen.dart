import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_edit_dialog.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TodoProvider>();
      if (provider.currentFilter != TodoFilterTab.uncompleted &&
          provider.currentFilter != TodoFilterTab.completed) {
        provider.setFilter(TodoFilterTab.uncompleted);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);
    final provider = context.watch<TodoProvider>();
    final filter = provider.currentFilter == TodoFilterTab.completed
        ? TodoFilterTab.completed
        : TodoFilterTab.uncompleted;

    final filteredList = filter == TodoFilterTab.completed
        ? provider.completedTodos.where((t) {
            if (provider.searchQuery.isEmpty) return true;
            final q = provider.searchQuery.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.notes.toLowerCase().contains(q);
          }).toList()
        : provider.uncompletedTodos.where((t) {
            if (provider.searchQuery.isEmpty) return true;
            final q = provider.searchQuery.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.notes.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.todos,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: s.search,
                    icon: Icon(
                      _searchOpen ? Icons.close : Icons.search,
                      color: colors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchOpen = !_searchOpen;
                        if (!_searchOpen) {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: provider.setSearchQuery,
                  style: TextStyle(fontSize: 16, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: s.search,
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: AppFilterSegment<TodoFilterTab>(
                segments: [
                  (TodoFilterTab.uncompleted, s.uncompleted),
                  (TodoFilterTab.completed, s.completed),
                ],
                selected: filter,
                onChanged: provider.setFilter,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isNotEmpty
                            ? s.noTodosFound
                            : s.noTodos,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : Container(
                      color: colors.surface,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const TodoListDivider(),
                        itemBuilder: (context, index) {
                          return TodoCard(
                            key: ValueKey(filteredList[index].id),
                            todo: filteredList[index],
                            showDate: true,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'todos_fab',
        onPressed: () => TodoEditDialog.show(context),
        tooltip: s.addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
