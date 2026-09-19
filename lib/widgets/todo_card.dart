import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/todo_item.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import 'todo_edit_dialog.dart';

/// Minimal two-line list row (not a heavy card).
class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final bool showDate;

  /// Fixed width so `17:30` never truncates to `17:...`.
  static const double timeColumnWidth = 48;

  const TodoCard({super.key, required this.todo, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);
    final provider = context.read<TodoProvider>();
    final timeFormat = DateFormat('HH:mm');

    final timeLabel = todo.reminderTime != null
        ? timeFormat.format(todo.reminderTime!)
        : (showDate ? DateFormat('M/d').format(todo.scheduledDate) : '--:--');

    final subtitle = showDate && todo.reminderTime != null
        ? '${DateFormat('M/d').format(todo.scheduledDate)} · $timeLabel'
        : timeLabel;

    final isDone = todo.isCompleted;
    final titleColor = isDone ? colors.textCompleted : colors.textPrimary;
    final metaColor = isDone ? colors.textCompleted : colors.textSecondary;

    final reminderIcon = todo.reminderKind.isAlarm
        ? Icons.alarm_outlined
        : Icons.notifications_none_outlined;
    // Completed rows never use red.
    final reminderColor = isDone
        ? colors.textCompleted
        : (todo.reminderKind.isAlarm ? colors.accent : colors.textSecondary);

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: () => TodoEditDialog.show(context, initialTodo: todo),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                button: true,
                label: isDone ? s.markIncomplete : s.markComplete,
                child: GestureDetector(
                  onTap: () => provider.toggleCompleted(todo.id),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _CompleteCircle(
                      completed: isDone,
                      completedColor: colors.completed,
                      border: colors.divider,
                      checkColor: colors.surface,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: colors.textCompleted,
                        decorationThickness: 1.2,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: showDate && todo.reminderTime != null
                          ? null
                          : timeColumnWidth,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                          color: metaColor,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: colors.textCompleted,
                          decorationThickness: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(reminderIcon, size: 20, color: reminderColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteCircle extends StatelessWidget {
  final bool completed;
  final Color completedColor;
  final Color border;
  final Color checkColor;

  const _CompleteCircle({
    required this.completed,
    required this.completedColor,
    required this.border,
    required this.checkColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? completedColor : Colors.transparent,
        border: Border.all(
          color: completed ? completedColor : border,
          width: 1.5,
        ),
      ),
      child: completed
          ? Icon(Icons.check, size: 14, color: checkColor)
          : null,
    );
  }
}

class TodoListDivider extends StatelessWidget {
  const TodoListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 50,
      endIndent: 16,
      color: AppColors.of(context).divider,
    );
  }
}

/// Light grey track + elevated selected pill (red label when selected).
class AppFilterSegment<T extends Object> extends StatelessWidget {
  final List<(T value, String label)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  const AppFilterSegment({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.segmentTrack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (value, label) in segments)
            Expanded(
              child: _SegmentChip(
                label: label,
                selected: value == selected,
                isDark: isDark,
                onTap: () => onChanged(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.segmentSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? colors.accent : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
