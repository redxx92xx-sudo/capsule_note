import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/capsule_model.dart';
import '../models/daily_digest_model.dart';
import '../screens/widgets/pro_modal.dart';
import 'ad_service.dart';
import 'monetization_provider.dart';

enum ExportFormat {
  markdown('Markdown (.md)', 'md'),
  plainText('Plain Text (.txt)', 'txt'),
  notion('Notion Compatible', 'md');

  final String label;
  final String extension;
  const ExportFormat(this.label, this.extension);
}

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  /// 格式化單則膠囊
  String formatCapsule(CapsuleModel capsule, ExportFormat format) {
    final dateStr = '${capsule.createdAt.year}-${capsule.createdAt.month.toString().padLeft(2, '0')}-${capsule.createdAt.day.toString().padLeft(2, '0')} ${capsule.createdAt.hour.toString().padLeft(2, '0')}:${capsule.createdAt.minute.toString().padLeft(2, '0')}';

    switch (format) {
      case ExportFormat.markdown:
        final buffer = StringBuffer();
        buffer.writeln('# ${capsule.title}');
        buffer.writeln();
        buffer.writeln('> **Created:** $dateStr | **Status:** ${capsule.isProcessed ? "Organized" : "Pending"}');
        if (capsule.tags.isNotEmpty) {
          buffer.writeln('> **Tags:** ${capsule.tags.map((t) => "`#$t`").join(" ")}');
        }
        buffer.writeln();
        if (capsule.summary.isNotEmpty) {
          buffer.writeln('## 💡 Summary');
          buffer.writeln(capsule.summary);
          buffer.writeln();
        }
        if (capsule.actionItems.isNotEmpty) {
          buffer.writeln('## 📌 Action Items');
          for (final item in capsule.actionItems) {
            buffer.writeln('- [ ] $item');
          }
          buffer.writeln();
        }
        buffer.writeln('## 🎙️ Raw Voice Transcript');
        buffer.writeln(capsule.rawTranscript);
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln('*Exported from Capsule Note*');
        return buffer.toString();

      case ExportFormat.plainText:
        final buffer = StringBuffer();
        buffer.writeln('CAPSULE NOTE: ${capsule.title}');
        buffer.writeln('Date: $dateStr');
        buffer.writeln('Tags: ${capsule.tags.join(", ")}');
        buffer.writeln('----------------------------------------');
        if (capsule.summary.isNotEmpty) {
          buffer.writeln('[SUMMARY]');
          buffer.writeln(capsule.summary);
          buffer.writeln();
        }
        if (capsule.actionItems.isNotEmpty) {
          buffer.writeln('[ACTION ITEMS]');
          for (final item in capsule.actionItems) {
            buffer.writeln('• $item');
          }
          buffer.writeln();
        }
        buffer.writeln('[RAW TRANSCRIPT]');
        buffer.writeln(capsule.rawTranscript);
        return buffer.toString();

      case ExportFormat.notion:
        final buffer = StringBuffer();
        buffer.writeln('# 💊 ${capsule.title}');
        buffer.writeln();
        buffer.writeln('> 🗓️ **Date:** $dateStr');
        buffer.writeln('> 🏷️ **Tags:** ${capsule.tags.map((t) => "`$t`").join(" ")}');
        buffer.writeln();
        if (capsule.summary.isNotEmpty) {
          buffer.writeln('### 💡 Core Summary');
          buffer.writeln('> ${capsule.summary}');
          buffer.writeln();
        }
        if (capsule.actionItems.isNotEmpty) {
          buffer.writeln('### ⚡ Action Items');
          for (final item in capsule.actionItems) {
            buffer.writeln('- [ ] $item');
          }
          buffer.writeln();
        }
        buffer.writeln('### 🎙️ Original Transcript');
        buffer.writeln(capsule.rawTranscript);
        return buffer.toString();
    }
  }

  /// 格式化靈感日報
  String formatDigest(DailyDigestModel digest, ExportFormat format) {
    switch (format) {
      case ExportFormat.markdown:
        return digest.toMarkdown();
      case ExportFormat.plainText:
        return digest.toPlainText();
      case ExportFormat.notion:
        return digest.toNotionFormat();
    }
  }

  /// 帶商業化門檻的匯出流程：
  /// - PRO 用戶直接完成
  /// - 免費用戶提示觀看 Rewarded Ad 廣告以解鎖單次匯出，或升級 PRO
  Future<bool> handleExportWithMonetization({
    required BuildContext context,
    required String content,
    required String title,
    required ExportFormat format,
    required String successMessage,
  }) async {
    final monetization = Provider.of<MonetizationProvider>(context, listen: false);

    if (monetization.isPro) {
      await _copyToClipboard(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return true;
    }

    // 免費用戶：彈出解鎖選項對話框
    if (!context.mounted) return false;
    final userChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.file_download_outlined, size: 22),
            SizedBox(width: 8),
            Text('Export Note'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exporting as ${format.label} is a PRO feature.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Free users can watch a short sponsored video to unlock this export instantly.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'CANCEL'),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.workspace_premium, size: 16),
            label: const Text('PRO Unlimited'),
            onPressed: () {
              Navigator.pop(ctx, 'PRO');
              ProModal.show(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_outline, size: 16),
            label: const Text('Watch Ad & Export'),
            onPressed: () => Navigator.pop(ctx, 'WATCH_AD'),
          ),
        ],
      ),
    );

    if (userChoice == 'WATCH_AD' && context.mounted) {
      AdService.instance.showRewardedAd(
        onUserEarnedReward: (reward) async {
          await _copyToClipboard(content);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        onAdFailedToLoad: () async {
          // 若廣告暫時無法載入，友好寬容允許一次匯出
          await _copyToClipboard(content);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );
      return true;
    }

    return false;
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
