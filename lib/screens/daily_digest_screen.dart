import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/daily_digest_model.dart';
import '../services/capsule_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class DailyDigestScreen extends StatefulWidget {
  const DailyDigestScreen({super.key});

  @override
  State<DailyDigestScreen> createState() => _DailyDigestScreenState();
}

class _DailyDigestScreenState extends State<DailyDigestScreen> {
  final DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final isDark = capsuleProvider.isDarkMode;

    final digest = DailyDigestModel.fromCapsules(_selectedDate, capsuleProvider.capsules);
    final dateStr = DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.dailyDigestTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l10n.exportDigest,
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => _showExportMenu(context, digest),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: digest.totalCapsules == 0
            ? _buildEmptyState(context, l10n, isDark)
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // 1. 日期與總覽指標卡片
                  _buildHeaderOverviewCard(context, digest, dateStr, isDark),
                  const SizedBox(height: 20),

                  // 2. 精華重點摘要彙整
                  _buildSectionHeader(
                    context,
                    title: l10n.keySummariesHeader,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildKeySummariesList(context, digest, isDark),
                  const SizedBox(height: 24),

                  // 3. 待辦任務清單
                  _buildSectionHeader(
                    context,
                    title: l10n.pendingActionItemsHeader,
                    icon: Icons.checklist_rounded,
                    countBadge: digest.pendingActionItems.length,
                  ),
                  const SizedBox(height: 10),
                  _buildActionItemsList(context, digest, isDark),
                  const SizedBox(height: 24),

                  // 4. 標籤主題分佈
                  if (digest.tagDistribution.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: l10n.tagDistributionHeader,
                      icon: Icons.tag_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildTagsWrap(context, digest, isDark),
                    const SizedBox(height: 24),
                  ],

                  // 5. 複製與匯出快捷按鈕
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('copy_markdown_digest_btn'),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text(l10n.copyDigestMarkdown),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                            ),
                          ),
                          onPressed: () {
                            ExportService.instance.handleExportWithMonetization(
                              context: context,
                              content: digest.toMarkdown(),
                              title: 'Daily Digest - $dateStr',
                              format: ExportFormat.markdown,
                              successMessage: l10n.copyMarkdownSuccess,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderOverviewCard(
    BuildContext context,
    DailyDigestModel digest,
    String dateStr,
    bool isDark,
  ) {
    final progressPercent = (digest.completionRate * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$progressPercent% Organized',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Total', '${digest.totalCapsules}', isDark),
              _buildDivider(isDark),
              _buildStatItem('Organized', '${digest.processedCount}', isDark),
              _buildDivider(isDark),
              _buildStatItem('Pending Items', '${digest.pendingActionItems.length}', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    int? countBadge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.inkBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (countBadge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.inkBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$countBadge',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.inkBlue,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildKeySummariesList(BuildContext context, DailyDigestModel digest, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: digest.capsules.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
        ),
        itemBuilder: (ctx, index) {
          final c = digest.capsules[index];
          final timeStr = DateFormat.jm().format(c.createdAt);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c.title.isNotEmpty ? c.title : 'Capsule #${index + 1}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.summary.isNotEmpty ? c.summary : c.rawTranscript,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionItemsList(BuildContext context, DailyDigestModel digest, bool isDark) {
    if (digest.pendingActionItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight),
        ),
        child: Text(
          'No pending action items for today. All organized!',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight),
      ),
      child: Column(
        children: digest.pendingActionItems.map((item) {
          return CheckboxListTile(
            value: item.isCompleted,
            onChanged: (val) {
              final provider = Provider.of<CapsuleProvider>(context, listen: false);
              provider.toggleProcessed(item.capsuleId);
            },
            title: Text(
              item.actionText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              item.capsuleTitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.inkBlue,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTagsWrap(BuildContext context, DailyDigestModel digest, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: digest.tagDistribution.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
            ),
          ),
          child: Text(
            '#${entry.key} (${entry.value})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.newspaper_outlined,
              size: 56,
              color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.digestEmptyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.digestEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportMenu(BuildContext context, DailyDigestModel digest) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    l10n.exportFormat,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...ExportFormat.values.map((fmt) {
                  return ListTile(
                    leading: Icon(
                      fmt == ExportFormat.markdown
                          ? Icons.code
                          : (fmt == ExportFormat.plainText
                              ? Icons.text_snippet_outlined
                              : Icons.description_outlined),
                      color: AppTheme.inkBlue,
                    ),
                    title: Text(fmt.label),
                    onTap: () {
                      Navigator.pop(ctx);
                      final content = ExportService.instance.formatDigest(digest, fmt);
                      ExportService.instance.handleExportWithMonetization(
                        context: context,
                        content: content,
                        title: 'Daily Digest - ${digest.date.toIso8601String().substring(0, 10)}',
                        format: fmt,
                        successMessage: l10n.exportSuccess,
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
