import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/capsule_provider.dart';
import '../services/monetization_provider.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';
import 'daily_digest_screen.dart';
import 'todo_edit_screen.dart';
import 'widgets/capsule_card.dart';
import 'widgets/pro_modal.dart';
import 'widgets/todo_card.dart';

class TodayScreen extends StatelessWidget {
  final VoidCallback? onSwitchToNotes;
  final VoidCallback? onSwitchToTodos;

  const TodayScreen({
    super.key,
    this.onSwitchToNotes,
    this.onSwitchToTodos,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todoProvider = Provider.of<TodoProvider>(context);
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final monetization = Provider.of<MonetizationProvider>(context);

    final now = DateTime.now();
    final todayCapsules = capsuleProvider.capsules.where((c) {
      return c.createdAt.year == now.year &&
          c.createdAt.month == now.month &&
          c.createdAt.day == now.day;
    }).toList();

    final overdueTodos = todoProvider.overdueTodos;
    final todayPending = todoProvider.todayPendingTodos;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMEEEEd(
                      Localizations.localeOf(context).languageCode)
                  .format(now),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              l10n.todayFocus,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.newspaper_outlined),
            tooltip: l10n.dailyDigestTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyDigestScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.bolt,
              color: monetization.isPro
                  ? const Color(0xFFD4AF37)
                  : AppTheme.inkBlue,
            ),
            tooltip: l10n.proBadge,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ProModal(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        children: [
          // 頂部統計指標卡片
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(l10n.todayTodosTitle, '${todayPending.length}',
                    AppTheme.inkBlue, isDark),
                _buildDivider(isDark),
                _buildStatItem(
                  l10n.overdueTodosTitle,
                  '${overdueTodos.length}',
                  overdueTodos.isNotEmpty
                      ? Colors.redAccent
                      : (isDark
                          ? AppTheme.nightSecondary
                          : AppTheme.inkSecondary),
                  isDark,
                ),
                _buildDivider(isDark),
                _buildStatItem(l10n.todayNotesTitle, '${todayCapsules.length}',
                    AppTheme.inkBlue, isDark),
                _buildDivider(isDark),
                _buildStatItem(
                  l10n.filterCompleted,
                  '${todoProvider.completedTodos.length}',
                  isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 快速新增快捷操作按鈕
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                        color: isDark
                            ? AppTheme.nightBorder
                            : AppTheme.inkBorderLight),
                  ),
                  icon: const Icon(Icons.add_task, size: 18),
                  label: Text(l10n.addTodo,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TodoEditScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                        color: isDark
                            ? AppTheme.nightBorder
                            : AppTheme.inkBorderLight),
                  ),
                  icon: const Icon(Icons.mic, size: 18),
                  label: Text(l10n.navNotes,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: onSwitchToNotes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 逾期提醒區塊 (若有逾期)
          if (overdueTodos.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 20),
                const SizedBox(width: 6),
                Text(
                  l10n.overdueTodosTitle,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                ),
                const Spacer(),
                Text(
                  '${overdueTodos.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...overdueTodos.take(3).map((t) => TodoCard(todo: t)),
            if (overdueTodos.length > 3)
              TextButton(
                onPressed: onSwitchToTodos,
                child: Text('${l10n.filterAll} ${overdueTodos.length} →'),
              ),
            const SizedBox(height: 16),
          ],

          // 今日待辦區塊
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.todayTodosTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: onSwitchToTodos,
                child: Text('${l10n.navTodos} →'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (todayPending.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                '✨',
                style: TextStyle(
                  color:
                      isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                  fontSize: 14,
                ),
              ),
            )
          else
            ...todayPending.map((t) => TodoCard(todo: t)),
          const SizedBox(height: 16),

          // 今日靈感記事區塊
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.todayNotesTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: onSwitchToNotes,
                child: Text('${l10n.navNotes} →'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (todayCapsules.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                l10n.emptyCapsulesSubtitle,
                style: TextStyle(
                  color:
                      isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...todayCapsules.map((c) => CapsuleCard(capsule: c)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
    );
  }
}
