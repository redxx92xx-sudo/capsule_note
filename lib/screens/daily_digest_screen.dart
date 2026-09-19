import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/daily_digest_model.dart';
import '../services/capsule_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme_capsule.dart';

class DailyDigestScreen extends StatefulWidget {
  const DailyDigestScreen({super.key});

  @override
  State<DailyDigestScreen> createState() => _DailyDigestScreenState();
}

class _DailyDigestScreenState extends State<DailyDigestScreen> {
  @override
  Widget build(BuildContext context) {
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final digest = DailyDigestModel.generateFromCapsules(capsuleProvider.capsules);
    final dateStr = DateFormat('yyyy-MM-dd').format(digest.date);
    final progress = digest.totalNotesCount > 0
        ? (digest.processedNotesCount / digest.totalNotesCount)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日靈感晚報'),
        actions: [
          IconButton(
            tooltip: '複製 Markdown 日報',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: digest.toMarkdown()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已複製今日晚報 Markdown 到剪貼簿！'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: '多格式匯出',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () {
              ExportService.instance.showExportModal(context, digest: digest);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 頂部日報卡片
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                width: 1.4,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_stories, size: 20, color: isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue),
                        const SizedBox(width: 8),
                        Text(
                          '今日靈感總覽',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      dateStr,
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('今日膠囊', ' 則', theme),
                    _buildStatCol('已整理', ' 則', theme),
                    _buildStatCol('待辦項目', ' 項', theme),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 核心亮點摘要
          _buildSectionHeader(Icons.lightbulb_outline, '💡 今日核心亮點'),
          const SizedBox(height: 10),
          if (digest.keyHighlights.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('今日尚無錄音記錄，隨時長按首頁按鈕捕捉靈感！'),
            )
          else
            ...digest.keyHighlights.map(
              (h) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 20, color: isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        h,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 待辦與行動清單
          _buildSectionHeader(Icons.check_circle_outline, '🎯 今日待辦行動清單'),
          const SizedBox(height: 10),
          if (digest.pendingActionItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('今日所有行動項目皆已整理完成！'),
            )
          else
            ...digest.pendingActionItems.map(
              (action) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 0,
                color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.radio_button_unchecked, size: 18),
                  title: Text(action, style: const TextStyle(fontSize: 13.5)),
                ),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.inkBlue),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}
