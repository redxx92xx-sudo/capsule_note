import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/todo_model.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';

class TodoEditScreen extends StatefulWidget {
  final TodoModel? todo;
  final DateTime? initialDate;
  final String? initialCapsuleId;

  const TodoEditScreen({
    super.key,
    this.todo,
    this.initialDate,
    this.initialCapsuleId,
  });

  @override
  State<TodoEditScreen> createState() => _TodoEditScreenState();
}

class _TodoEditScreenState extends State<TodoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;

  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late TodoPriority _priority;
  late bool _isReminderEnabled;
  late TodoRepeatRule _repeatRule;
  late bool _persistentReminder;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    final baseDate = todo?.dueDate ?? widget.initialDate ?? DateTime.now();

    _titleController = TextEditingController(text: todo?.title ?? '');
    _descController = TextEditingController(text: todo?.description ?? '');
    _tagsController = TextEditingController(text: todo?.tags.join(', ') ?? '');

    _dueDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    _dueTime = TimeOfDay(hour: baseDate.hour, minute: baseDate.minute);
    _priority = todo?.priority ?? TodoPriority.medium;
    _isReminderEnabled = todo?.isReminderEnabled ?? true;
    _repeatRule = todo?.repeatRule ?? TodoRepeatRule.none;
    _persistentReminder = todo?.persistentReminder ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final fullDueDate = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    if (widget.todo == null || widget.todo!.id.isEmpty) {
      // 新增待辦
      todoProvider.addTodo(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: fullDueDate,
        priority: _priority,
        isReminderEnabled: _isReminderEnabled,
        reminderTime: _isReminderEnabled ? fullDueDate : null,
        repeatRule: _repeatRule,
        capsuleId: widget.initialCapsuleId ?? widget.todo?.capsuleId,
        persistentReminder: _persistentReminder,
        tags: tags,
      );
    } else {
      // 編輯待辦
      final updated = widget.todo!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        dueDate: fullDueDate,
        priority: _priority,
        isReminderEnabled: _isReminderEnabled,
        reminderTime: _isReminderEnabled ? fullDueDate : null,
        repeatRule: _repeatRule,
        persistentReminder: _persistentReminder,
        tags: tags,
      );
      todoProvider.updateTodo(updated);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.todo != null && widget.todo!.id.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editTodo : l10n.addTodo),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: l10n.saveTodo,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 標題輸入框
            TextFormField(
              controller: _titleController,
              autofocus: !isEdit,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: '${l10n.todoTitleLabel} *',
                hintText: l10n.todoTitleRequired,
                filled: true,
                fillColor:
                    isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.todoTitleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 詳細描述
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.todoDescLabel,
                filled: true,
                fillColor:
                    isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 日期與時間選擇
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dueDateLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label:
                              Text(DateFormat('yyyy/MM/dd').format(_dueDate)),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(_dueTime.format(context)),
                          onPressed: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 優先級選擇
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.priorityLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPriorityChip(
                          l10n.priorityLow, TodoPriority.low, Colors.grey),
                      const SizedBox(width: 8),
                      _buildPriorityChip(l10n.priorityMedium,
                          TodoPriority.medium, AppTheme.inkBlue),
                      const SizedBox(width: 8),
                      _buildPriorityChip(l10n.priorityHigh, TodoPriority.high,
                          Colors.orangeAccent),
                      const SizedBox(width: 8),
                      _buildPriorityChip(l10n.priorityUrgent,
                          TodoPriority.urgent, Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 提醒與重複設定
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.enableReminder,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    value: _isReminderEnabled,
                    onChanged: (val) =>
                        setState(() => _isReminderEnabled = val),
                  ),
                  if (_isReminderEnabled) ...[
                    const Divider(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.persistentReminder,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _persistentReminder,
                      onChanged: (val) =>
                          setState(() => _persistentReminder = val),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.repeatRuleLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        DropdownButton<TodoRepeatRule>(
                          value: _repeatRule,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                                value: TodoRepeatRule.none,
                                child: Text(l10n.repeatNone)),
                            DropdownMenuItem(
                                value: TodoRepeatRule.daily,
                                child: Text(l10n.repeatDaily)),
                            DropdownMenuItem(
                                value: TodoRepeatRule.weekly,
                                child: Text(l10n.repeatWeekly)),
                            DropdownMenuItem(
                                value: TodoRepeatRule.monthly,
                                child: Text(l10n.repeatMonthly)),
                          ],
                          onChanged: (rule) {
                            if (rule != null) {
                              setState(() => _repeatRule = rule);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 標籤輸入
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: l10n.tagsLabel,
                filled: true,
                fillColor:
                    isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.inkBlue,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check),
              label: Text(isEdit ? l10n.saveTodo : l10n.addTodo,
                  style: const TextStyle(fontSize: 16)),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String label, TodoPriority priority, Color color) {
    final isSelected = _priority == priority;
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: color.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          color: isSelected ? color : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => setState(() => _priority = priority),
      ),
    );
  }
}
