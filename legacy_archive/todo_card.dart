import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/todo_model.dart';
import '../../services/capsule_provider.dart';
import '../../services/todo_provider.dart';
import '../../theme/app_theme.dart';
import '../capsule_detail_screen.dart';
import '../todo_edit_screen.dart';

class TodoCard extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = todo.isOverdue();
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final capsuleProvider =
        Provider.of<CapsuleProvider>(context, listen: false);

    // 優先級顏色與標籤
    Color priorityColor =
        isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary;
    String priorityText = '';
    if (todo.priority == TodoPriority.urgent) {
      priorityColor = Colors.redAccent;
      priorityText = l10n.priorityUrgent;
    } else if (todo.priority == TodoPriority.high) {
      priorityColor = Colors.orangeAccent;
      priorityText = l10n.priorityHigh;
    } else if (todo.priority == TodoPriority.medium) {
      priorityColor = AppTheme.inkBlue;
      priorityText = l10n.priorityMedium;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? (isDark
                  ? Colors.redAccent.withValues(alpha: 0.6)
                  : Colors.redAccent.withValues(alpha: 0.5))
              : (isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight),
          width: isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TodoEditScreen(todo: todo),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  todo.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: todo.isCompleted
                      ? (isDark
                          ? AppTheme.nightSecondary
                          : AppTheme.inkSecondary)
                      : (isOverdue ? Colors.redAccent : AppTheme.inkBlue),
                  size: 22,
                ),
                onPressed: () {
                  if (onToggle != null) {
                    onToggle!();
                  } else {
                    todoProvider.toggleTodoCompleted(todo.id);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            todo.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.isCompleted
                                  ? (isDark
                                      ? AppTheme.nightSecondary
                                      : AppTheme.inkSecondary)
                                  : (isDark
                                      ? AppTheme.nightText
                                      : AppTheme.inkText),
                            ),
                          ),
                        ),
                        if (priorityText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              priorityText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.nightSecondary
                              : AppTheme.inkSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event,
                              size: 13,
                              color: isOverdue
                                  ? Colors.redAccent
                                  : (isDark
                                      ? AppTheme.nightSecondary
                                      : AppTheme.inkSecondary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MM/dd HH:mm').format(todo.dueDate),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isOverdue
                                    ? Colors.redAccent
                                    : (isDark
                                        ? AppTheme.nightSecondary
                                        : AppTheme.inkSecondary),
                              ),
                            ),
                          ],
                        ),
                        if (isOverdue && !todo.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.overdueTodosTitle,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        if (todo.isReminderEnabled)
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 13,
                            color: isDark
                                ? AppTheme.nightSecondary
                                : AppTheme.inkSecondary,
                          ),
                        if (todo.repeatRule != TodoRepeatRule.none)
                          Icon(
                            Icons.repeat,
                            size: 13,
                            color: isDark
                                ? AppTheme.nightSecondary
                                : AppTheme.inkSecondary,
                          ),
                        if (todo.capsuleId != null)
                          InkWell(
                            onTap: () {
                              final linked = capsuleProvider.capsules
                                  .where((c) => c.id == todo.capsuleId)
                                  .firstOrNull;
                              if (linked != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CapsuleDetailScreen(capsule: linked),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('關聯記事已不存在')),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.inkBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link,
                                      size: 12, color: AppTheme.inkBlue),
                                  const SizedBox(width: 2),
                                  Text(
                                    l10n.capsuleDetailTitle,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.inkBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color:
                      isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                ),
                onSelected: (value) {
                  if (value == 'snooze_30') {
                    todoProvider.snoozeTodo(
                        todo.id, const Duration(minutes: 30));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.snooze30m)),
                    );
                  } else if (value == 'snooze_60') {
                    todoProvider.snoozeTodo(todo.id, const Duration(hours: 1));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.snooze1h)),
                    );
                  } else if (value == 'snooze_180') {
                    todoProvider.snoozeTodo(todo.id, const Duration(hours: 3));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.snooze3h)),
                    );
                  } else if (value == 'snooze_tomorrow') {
                    todoProvider.snoozeTodo(todo.id, const Duration(days: 1));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.snoozeTomorrow)),
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(context, todoProvider, l10n);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'snooze_30',
                    child: Text(l10n.snooze30m),
                  ),
                  PopupMenuItem(
                    value: 'snooze_60',
                    child: Text(l10n.snooze1h),
                  ),
                  PopupMenuItem(
                    value: 'snooze_180',
                    child: Text(l10n.snooze3h),
                  ),
                  PopupMenuItem(
                    value: 'snooze_tomorrow',
                    child: Text(l10n.snoozeTomorrow),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.deleteTodoTitle,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, TodoProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTodoTitle),
        content: Text('${l10n.deleteTodoConfirm}\n(${todo.title})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteTodo(todo.id);
            },
            child: Text(l10n.confirmDelete),
          ),
        ],
      ),
    );
  }
}
