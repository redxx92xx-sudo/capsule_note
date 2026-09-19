import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_strings.dart';
import '../models/repeat_rule.dart';
import '../models/todo_item.dart';
import '../models/reminder_kind.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import 'confirm_delete_dialog.dart';
import 'todo_card.dart';

class TodoEditDialog extends StatefulWidget {
  final TodoItem? initialTodo;
  final DateTime? defaultDate;
  final int defaultPersistentIntervalMinutes;
  final Function(TodoItem)? onSave;
  final String? draftTitle;
  final String? draftNotes;

  const TodoEditDialog({
    super.key,
    this.initialTodo,
    this.defaultDate,
    this.defaultPersistentIntervalMinutes = 60,
    this.onSave,
    this.draftTitle,
    this.draftNotes,
  });

  static Future<void> show(
    BuildContext context, {
    TodoItem? initialTodo,
    DateTime? defaultDate,
    String? draftTitle,
    String? draftNotes,
  }) async {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TodoEditDialog(
        initialTodo: initialTodo,
        defaultDate: defaultDate,
        draftTitle: draftTitle,
        draftNotes: draftNotes,
        defaultPersistentIntervalMinutes: provider.persistentIntervalMinutes,
        onSave: (todo) async {
          if (initialTodo != null) {
            await provider.updateTodo(todo);
          } else {
            await provider.createTodo(
              title: todo.title,
              notes: todo.notes,
              scheduledDate: todo.scheduledDate,
              reminderTime: todo.reminderTime,
              priority: todo.priority,
              repeatRule: todo.repeatRule,
              repeatDays: todo.repeatDays,
              isPersistentReminder: todo.isPersistentReminder,
              persistentIntervalMinutes: todo.persistentIntervalMinutes,
              reminderKind: todo.reminderKind,
            );
          }
        },
      ),
    );
  }

  @override
  State<TodoEditDialog> createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends State<TodoEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  late DateTime _scheduledDate;
  TimeOfDay? _reminderTime;
  late TodoPriority _priority;
  late RepeatType _repeatRule;
  late List<int> _repeatDays;
  late bool _isPersistentReminder;
  late int _persistentIntervalMinutes;
  late ReminderKind _reminderKind;
  bool _moreOpen = false;

  @override
  void initState() {
    super.initState();
    final todo = widget.initialTodo;
    _titleController = TextEditingController(
      text: todo?.title ?? widget.draftTitle ?? '',
    );
    _notesController = TextEditingController(
      text: todo?.notes ?? widget.draftNotes ?? '',
    );

    _scheduledDate =
        todo?.scheduledDate ?? widget.defaultDate ?? DateTime.now();
    _reminderTime = todo?.reminderTime != null
        ? TimeOfDay(
            hour: todo!.reminderTime!.hour,
            minute: todo.reminderTime!.minute,
          )
        : null;
    _priority = todo?.priority ?? TodoPriority.normal;
    _repeatRule = todo?.repeatRule ?? RepeatType.none;
    _repeatDays = List.from(todo?.repeatDays ?? []);
    _isPersistentReminder = todo?.isPersistentReminder ?? false;
    _persistentIntervalMinutes =
        todo?.persistentIntervalMinutes ??
        widget.defaultPersistentIntervalMinutes;
    _reminderKind = todo?.reminderKind ?? ReminderKind.notification;
    _moreOpen =
        todo != null &&
        (todo.notes.isNotEmpty ||
            todo.priority != TodoPriority.normal ||
            todo.repeatRule != RepeatType.none ||
            todo.isPersistentReminder);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateLabel(AppStrings s, DateTime date) {
    final locale = s.locale;
    try {
      if (locale.languageCode == 'zh') {
        final tag = locale.countryCode == 'CN' ? 'zh_CN' : 'zh_TW';
        return DateFormat('M月d日 E', tag).format(date);
      }
      return DateFormat('MMM d, E', 'en').format(date);
    } catch (_) {
      return '${date.month}/${date.day}';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _showHint(String title, String body) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body, style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.of(ctx).gotIt),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    DateTime? reminderDateTime;
    if (_reminderTime != null) {
      reminderDateTime = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
    }

    final now = DateTime.now();
    final todo = TodoItem(
      id: widget.initialTodo?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? ''
          : _notesController.text.trim(),
      createdAt: widget.initialTodo?.createdAt ?? now,
      scheduledDate: DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
      ),
      reminderTime: reminderDateTime,
      isCompleted: widget.initialTodo?.isCompleted ?? false,
      completedAt: widget.initialTodo?.completedAt,
      priority: _priority,
      repeatRule: _repeatRule,
      repeatDays: _repeatDays,
      snoozeUntil: widget.initialTodo?.snoozeUntil,
      isPersistentReminder: _isPersistentReminder,
      persistentIntervalMinutes: _persistentIntervalMinutes,
      persistentReminderCountToday:
          widget.initialTodo?.persistentReminderCountToday ?? 0,
      lastPersistentReminderDate:
          widget.initialTodo?.lastPersistentReminderDate,
      reminderKind: _reminderKind,
      dataVersion: (widget.initialTodo?.dataVersion ?? 0) + 1,
    );

    widget.onSave?.call(todo);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTodo != null;
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? s.editTodo : s.addTodo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      autofocus: !isEditing,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(labelText: s.title),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return s.pleaseEnterTitle;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    _FieldRow(
                      label: s.date,
                      value: _formatDateLabel(s, _scheduledDate),
                      onTap: _selectDate,
                    ),
                    _FieldRow(
                      label: s.time,
                      value: _reminderTime == null
                          ? s.notSet
                          : '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}',
                      onTap: _selectTime,
                      trailing: _reminderTime == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _reminderTime = null),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          s.reminderWay,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.help_outline,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          onPressed: () => _showHint(
                            s.reminderWay,
                            s.reminderWayHint,
                          ),
                        ),
                      ],
                    ),
                    AppFilterSegment<ReminderKind>(
                      segments: [
                        (ReminderKind.notification, s.notificationKind),
                        (ReminderKind.alarm, s.alarmKind),
                      ],
                      selected: _reminderKind,
                      onChanged: (value) =>
                          setState(() => _reminderKind = value),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => setState(() => _moreOpen = !_moreOpen),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              _moreOpen ? Icons.expand_less : Icons.expand_more,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.moreSettings,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_moreOpen) ...[
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(labelText: s.notes),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.priority,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TodoPriority.values.map((p) {
                          final selected = _priority == p;
                          return ChoiceChip(
                            label: Text(p.localizedName(s)),
                            selected: selected,
                            showCheckmark: false,
                            selectedColor: colors.textPrimary,
                            labelStyle: TextStyle(
                              color: selected
                                  ? colors.surface
                                  : colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(color: colors.divider),
                            onSelected: (_) => setState(() => _priority = p),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.repeat,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      DropdownButton<RepeatType>(
                        value: _repeatRule,
                        isExpanded: true,
                        underline: Divider(height: 1, color: colors.divider),
                        items: RepeatType.values
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.localizedName(s)),
                              ),
                            )
                            .toList(),
                        onChanged: (rule) {
                          if (rule == null) return;
                          setState(() {
                            _repeatRule = rule;
                            if (rule == RepeatType.customWeekdays &&
                                _repeatDays.isEmpty) {
                              _repeatDays = [_scheduledDate.weekday];
                            }
                          });
                        },
                      ),
                      if (_repeatRule == RepeatType.customWeekdays) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (int i = 1; i <= 7; i++)
                              FilterChip(
                                label: Text(s.shortWeekdaysMonFirst[i - 1]),
                                selected: _repeatDays.contains(i),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _repeatDays.add(i);
                                    } else {
                                      _repeatDays.remove(i);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.persistentReminder),
                        value: _isPersistentReminder,
                        onChanged: (val) {
                          setState(() => _isPersistentReminder = val);
                        },
                      ),
                      if (_isPersistentReminder) ...[
                        Text(
                          s.reminderInterval,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _persistentIntervalMinutes,
                          isExpanded: true,
                          underline: Divider(height: 1, color: colors.divider),
                          items: [
                            DropdownMenuItem(value: 30, child: Text(s.minutes30)),
                            DropdownMenuItem(value: 60, child: Text(s.hour1)),
                            DropdownMenuItem(value: 180, child: Text(s.hours3)),
                            DropdownMenuItem(value: 1440, child: Text(s.daily)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _persistentIntervalMinutes = val);
                            }
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _save, child: Text(s.save)),
                    if (isEditing) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          final provider = context.read<TodoProvider>();
                          final navigator = Navigator.of(context);
                          final confirm = await ConfirmDeleteDialog.show(
                            context,
                            title: s.deleteTodoTitle,
                            message: s.confirmDeleteNamedMsg(_titleController.text),
                          );
                          if (!confirm || !mounted) return;
                          await provider.deleteTodo(widget.initialTodo!.id);
                          if (!mounted) return;
                          navigator.pop();
                        },
                        child: Text(
                          s.delete,
                          style: TextStyle(color: colors.overdue),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
