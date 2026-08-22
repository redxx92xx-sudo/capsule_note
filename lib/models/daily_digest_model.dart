import 'package:intl/intl.dart';
import 'capsule_model.dart';

class DailyDigestModel {
  final DateTime date;
  final List<String> keyHighlights;
  final List<String> pendingActionItems;
  final int totalNotesCount;
  final int processedNotesCount;

  const DailyDigestModel({
    required this.date,
    required this.keyHighlights,
    required this.pendingActionItems,
    required this.totalNotesCount,
    required this.processedNotesCount,
  });

  factory DailyDigestModel.generateFromCapsules(List<CapsuleModel> capsules, {DateTime? targetDate}) {
    return DailyDigestModel.fromCapsules(targetDate ?? DateTime.now(), capsules);
  }

  factory DailyDigestModel.fromCapsules(DateTime date, List<CapsuleModel> capsules) {
    final todayCapsules = capsules.where((c) {
      return c.createdAt.year == date.year &&
          c.createdAt.month == date.month &&
          c.createdAt.day == date.day;
    }).toList();

    final highlights = <String>[];
    final pendingActions = <String>[];
    int processed = 0;

    for (final c in todayCapsules) {
      if (c.isProcessed) {
        processed++;
      }
      final highlight = c.summary.isNotEmpty ? c.summary : c.title;
      if (highlight.isNotEmpty && !highlights.contains(highlight)) {
        highlights.add(highlight);
      }

      for (final item in c.actionItems) {
        if (!c.isProcessed && !pendingActions.contains(item)) {
          pendingActions.add(item);
        }
      }
    }

    return DailyDigestModel(
      date: date,
      keyHighlights: highlights,
      pendingActionItems: pendingActions,
      totalNotesCount: todayCapsules.length,
      processedNotesCount: processed,
    );
  }

  String toMarkdown() {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final buffer = StringBuffer();
    buffer.writeln('# 📰 今日靈感晚報 ($dateStr)');
    buffer.writeln('📊 **今日概況**：共 $totalNotesCount 則膠囊，已整理 $processedNotesCount 則');
    buffer.writeln();

    buffer.writeln('## 💡 核心亮點摘要');
    if (keyHighlights.isEmpty) {
      buffer.writeln('- 今日暫無記錄');
    } else {
      for (final h in keyHighlights) {
        buffer.writeln('- $h');
      }
    }
    buffer.writeln();

    buffer.writeln('## ✅ 待辦與執行項目');
    if (pendingActionItems.isEmpty) {
      buffer.writeln('- 所有行動清單已全部完成！');
    } else {
      for (final a in pendingActionItems) {
        buffer.writeln('- [ ] $a');
      }
    }

    return buffer.toString();
  }

  String toPlainText() {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final buffer = StringBuffer();
    buffer.writeln('【今日靈感晚報】$dateStr');
    buffer.writeln('統計：共 $totalNotesCount 則膠囊 ($processedNotesCount 則已整理)');
    buffer.writeln('------------------------');
    buffer.writeln('【重點摘要】');
    for (int i = 0; i < keyHighlights.length; i++) {
      buffer.writeln('${i + 1}. ${keyHighlights[i]}');
    }
    buffer.writeln('------------------------');
    buffer.writeln('【待辦事項】');
    for (final a in pendingActionItems) {
      buffer.writeln('□ $a');
    }
    return buffer.toString();
  }

  String toNotionFormat() {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final buffer = StringBuffer();
    buffer.writeln('# 📅 $dateStr Daily Digest');
    buffer.writeln('> 📊 Total Capsules: $totalNotesCount | Processed: $processedNotesCount');
    buffer.writeln();
    buffer.writeln('### 💡 Key Takeaways');
    for (final h in keyHighlights) {
      buffer.writeln('- $h');
    }
    buffer.writeln();
    buffer.writeln('### 🎯 Action Items');
    for (final a in pendingActionItems) {
      buffer.writeln('- [ ] $a');
    }
    return buffer.toString();
  }
}
