import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/capsule_model.dart';
import '../../services/capsule_provider.dart';
import '../../theme/app_theme_capsule.dart';
import '../capsule_detail_screen.dart';

class CapsuleCard extends StatelessWidget {
  final CapsuleModel capsule;

  const CapsuleCard({super.key, required this.capsule});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CapsuleProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('MM/dd HH:mm').format(capsule.createdAt);

    return Dismissible(
      key: Key(capsule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => provider.deleteCapsule(capsule.id),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => CapsuleDetailScreen(capsule: capsule),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: capsule.isProcessed
                  ? (isDark ? AppTheme.nightBorder.withValues(alpha: 0.5) : AppTheme.inkBorderLight.withValues(alpha: 0.6))
                  : (isDark ? const Color(0xFF4A6572) : AppTheme.inkBlue.withValues(alpha: 0.35)),
              width: capsule.isProcessed ? 1.0 : 1.4,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capsule.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: capsule.isProcessed ? TextDecoration.lineThrough : null,
                              color: capsule.isProcessed
                                  ? (isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary)
                                  : (isDark ? AppTheme.nightText : AppTheme.inkBlack),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                timeStr,
                                style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                              ),
                              if (capsule.audioPath != null) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.mic,
                                  size: 13,
                                  color: isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: capsule.isProcessed ? l10n.markAsPending : l10n.markAsDone,
                      icon: Icon(
                        capsule.isProcessed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: capsule.isProcessed
                            ? (isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue)
                            : (isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary),
                      ),
                      onPressed: () => provider.toggleProcessed(capsule.id),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  capsule.summary.isNotEmpty ? capsule.summary : capsule.rawTranscript,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.nightText.withValues(alpha: 0.85) : AppTheme.inkBlack.withValues(alpha: 0.85),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (capsule.actionItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: capsule.actionItems
                          .take(2)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_right_alt,
                                    size: 14,
                                    color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (capsule.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: capsule.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
