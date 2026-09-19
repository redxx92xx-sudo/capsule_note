import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_edit_dialog.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.onOpenVoiceNotes});

  /// Opens CapsuleNote voice-capsule UI (mic entry lives on Today, not a tab).
  final VoidCallback? onOpenVoiceNotes;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _showCompleted = false;

  String _formatHeaderDate(DateTime date) {
    final s = AppStrings.of(context);
    final locale = s.locale;
    try {
      if (locale.languageCode == 'zh') {
        final tag = locale.countryCode == 'CN' ? 'zh_CN' : 'zh_TW';
        return DateFormat('M月d日 EEEE', tag).format(date);
      }
      return DateFormat('EEEE, MMM d', 'en').format(date);
    } catch (_) {
      return '${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);
    final provider = context.watch<TodoProvider>();
    final now = DateTime.now();

    final todayList = provider.todayTodos;
    final completedToday = provider.todayCompletedTodos;
    final isEmpty = todayList.isEmpty && completedToday.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.accent,
          onRefresh: () => provider.loadTodos(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.today,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatHeaderDate(now),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.todaySummaryCounts(
                          todayList.length,
                          completedToday.length,
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, thickness: 1, color: colors.divider),
                    ],
                  ),
                ),
              ),
              if (isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.noTodosToday,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                TodoEditDialog.show(context, defaultDate: now),
                            child: Text(s.addTodo),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Container(
                    color: colors.surface,
                    child: Column(
                      children: [
                        for (var i = 0; i < todayList.length; i++) ...[
                          if (i > 0) const TodoListDivider(),
                          TodoCard(todo: todayList[i]),
                        ],
                        if (completedToday.isNotEmpty) ...[
                          if (todayList.isNotEmpty) const TodoListDivider(),
                          InkWell(
                            onTap: () => setState(
                              () => _showCompleted = !_showCompleted,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _showCompleted
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: colors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.showCompletedItems,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${completedToday.length}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showCompleted) ...[
                            const TodoListDivider(),
                            for (var i = 0; i < completedToday.length; i++) ...[
                              TodoCard(todo: completedToday[i]),
                              if (i < completedToday.length - 1)
                                const TodoListDivider(),
                            ],
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onOpenVoiceNotes != null) ...[
            FloatingActionButton(
              heroTag: 'today_mic_fab',
              tooltip: 'Voice capsules',
              onPressed: widget.onOpenVoiceNotes,
              child: const Icon(Icons.mic),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'today_fab',
            tooltip: s.addTodo,
            onPressed: () => TodoEditDialog.show(context, defaultDate: now),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
