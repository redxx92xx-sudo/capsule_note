import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_edit_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  String _monthTitle(AppStrings s) {
    final locale = s.locale;
    try {
      if (locale.languageCode == 'zh') {
        final tag = locale.countryCode == 'CN' ? 'zh_CN' : 'zh_TW';
        return DateFormat('yyyy年M月', tag).format(_focusedMonth);
      }
      return DateFormat('MMMM yyyy', 'en').format(_focusedMonth);
    } catch (_) {
      return '${_focusedMonth.year}-${_focusedMonth.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);
    final provider = context.watch<TodoProvider>();
    final monthTitle = _monthTitle(s);
    final selectedDayTodos = provider.getTodosForDate(_selectedDay);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                    color: colors.textPrimary,
                  ),
                  Expanded(
                    child: Text(
                      monthTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                    color: colors.textPrimary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: s.shortWeekdaysSunFirst.map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildCalendarGrid(colors, provider),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Divider(height: 1, color: colors.divider),
            ),
            Expanded(
              child: selectedDayTodos.isEmpty
                  ? Center(
                      child: Text(
                        s.noTodosForDay,
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
                        itemCount: selectedDayTodos.length,
                        separatorBuilder: (_, __) => const TodoListDivider(),
                        itemBuilder: (context, index) {
                          return TodoCard(todo: selectedDayTodos[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        tooltip: s.addTodo,
        onPressed: () =>
            TodoEditDialog.show(context, defaultDate: _selectedDay),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarGrid(AppColors colors, TodoProvider provider) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalGridCells = ((startingWeekday + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.05,
      ),
      itemCount: totalGridCells,
      itemBuilder: (context, index) {
        final dayNumber = index - startingWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox();
        }

        final cellDate =
            DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
        final isSelected = cellDate.year == _selectedDay.year &&
            cellDate.month == _selectedDay.month &&
            cellDate.day == _selectedDay.day;
        final isToday = cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;
        final hasTodos = provider.getTodosForDate(cellDate).isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDay = cellDate);
            provider.setSelectedDate(cellDate);
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? colors.accent
                        : (isToday ? colors.divider : null),
                  ),
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? colors.onAccent
                          : colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasTodos
                        ? (isSelected ? colors.accent : colors.textSecondary)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
