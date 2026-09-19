import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/capsule_provider.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import 'todo_edit_screen.dart';
import 'widgets/capsule_card.dart';
import 'widgets/todo_card.dart';

enum CalendarViewMode { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;

  @override
  void initState() {
    super.initState();
    _selectedDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _currentMonth = DateTime(now.year, now.month, 1);
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
      _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todoProvider = Provider.of<TodoProvider>(context);
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final langCode = Localizations.localeOf(context).languageCode;

    final selectedTodos = todoProvider.getTodosForDate(_selectedDate);
    final selectedCapsules = capsuleProvider.capsules.where((c) {
      return c.createdAt.year == _selectedDate.year &&
          c.createdAt.month == _selectedDate.month &&
          c.createdAt.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCalendar,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          SegmentedButton<CalendarViewMode>(
            segments: [
              ButtonSegment(
                  value: CalendarViewMode.month,
                  label: Text(l10n.viewMonth,
                      style: const TextStyle(fontSize: 12))),
              ButtonSegment(
                  value: CalendarViewMode.week,
                  label: Text(l10n.viewWeek,
                      style: const TextStyle(fontSize: 12))),
              ButtonSegment(
                  value: CalendarViewMode.day,
                  label:
                      Text(l10n.viewDay, style: const TextStyle(fontSize: 12))),
            ],
            selected: {_viewMode},
            onSelectionChanged: (set) => setState(() => _viewMode = set.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: l10n.backToToday,
            onPressed: _goToToday,
          ),
        ],
      ),
      body: Column(
        children: [
          // 月份／日期導航列
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    if (_viewMode == CalendarViewMode.day) {
                      _changeDay(-1);
                    } else {
                      _changeMonth(-1);
                    }
                  },
                ),
                Text(
                  _viewMode == CalendarViewMode.day
                      ? DateFormat.yMMMMEEEEd(langCode).format(_selectedDate)
                      : DateFormat.yMMM(langCode).format(_currentMonth),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    if (_viewMode == CalendarViewMode.day) {
                      _changeDay(1);
                    } else {
                      _changeMonth(1);
                    }
                  },
                ),
              ],
            ),
          ),

          // 日曆網格 / 週檢視
          if (_viewMode == CalendarViewMode.month)
            _buildMonthGrid(todoProvider, capsuleProvider, isDark)
          else if (_viewMode == CalendarViewMode.week)
            _buildWeekGrid(todoProvider, capsuleProvider, isDark)
          else
            const SizedBox.shrink(),

          const Divider(height: 1),

          // 選定日期的清單展示
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MM/dd').format(_selectedDate)} ${l10n.todayNotesTitle}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  tooltip: l10n.addTodo,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TodoEditScreen(initialDate: _selectedDate),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: (selectedTodos.isEmpty && selectedCapsules.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 48,
                          color: isDark
                              ? AppTheme.nightSecondary
                              : AppTheme.inkSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.emptyCapsulesTitle,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.nightSecondary
                                : AppTheme.inkSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                    children: [
                      if (selectedTodos.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(l10n.navTodos,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        ...selectedTodos.map((t) => TodoCard(todo: t)),
                      ],
                      if (selectedCapsules.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(l10n.navNotes,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        ...selectedCapsules.map((c) => CapsuleCard(capsule: c)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(
      TodoProvider todoProvider, CapsuleProvider capsuleProvider, bool isDark) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;

    final dayHeaders = ['1', '2', '3', '4', '5', '6', '7'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayHeaders
                .map((d) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.nightSecondary
                                : AppTheme.inkSecondary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox();
              }

              final dayNum = dayOffset + 1;
              final date =
                  DateTime(_currentMonth.year, _currentMonth.month, dayNum);
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              final hasTodos = todoProvider.getTodosForDate(date).isNotEmpty;
              final hasCapsules = capsuleProvider.capsules.any((c) =>
                  c.createdAt.year == date.year &&
                  c.createdAt.month == date.month &&
                  c.createdAt.day == date.day);

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppTheme.nightHighlight : AppTheme.inkBlue)
                        : (isToday
                            ? (isDark
                                ? AppTheme.nightCard
                                : AppTheme.inkHighlightLight)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: AppTheme.inkBlue, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: (isSelected || isToday)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? AppTheme.inkBlue : Colors.white)
                              : (isDark
                                  ? AppTheme.nightText
                                  : AppTheme.inkText),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasTodos)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppTheme.inkBlue : Colors.white)
                                    : AppTheme.inkBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasCapsules)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppTheme.inkBlue : Colors.white)
                                    : Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(
      TodoProvider todoProvider, CapsuleProvider capsuleProvider, bool isDark) {
    final startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays =
        List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    final dayHeaders = ['1', '2', '3', '4', '5', '6', '7'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final date = weekDays[i];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          final hasTodos = todoProvider.getTodosForDate(date).isNotEmpty;
          final hasCapsules = capsuleProvider.capsules.any((c) =>
              c.createdAt.year == date.year &&
              c.createdAt.month == date.month &&
              c.createdAt.day == date.day);

          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 42,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.nightHighlight : AppTheme.inkBlue)
                    : (isToday
                        ? (isDark
                            ? AppTheme.nightCard
                            : AppTheme.inkHighlightLight)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.inkBlue, width: 1.2)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    dayHeaders[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? (isDark ? AppTheme.inkBlue : Colors.white)
                          : (isDark
                              ? AppTheme.nightSecondary
                              : AppTheme.inkSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? (isDark ? AppTheme.inkBlue : Colors.white)
                          : (isDark ? AppTheme.nightText : AppTheme.inkText),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasTodos)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppTheme.inkBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasCapsules)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.white : Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
