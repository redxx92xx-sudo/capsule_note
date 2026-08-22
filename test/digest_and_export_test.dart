import 'package:flutter_test/flutter_test.dart';
import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/models/daily_digest_model.dart';
import 'package:capsule_note/services/speech_cleaner_service.dart';
import 'package:capsule_note/services/export_service.dart';

void main() {
  group('SpeechCleanerService Tests', () {
    final cleaner = SpeechCleanerService.instance;

    test('Removes Chinese filler words and duplicate words', () {
      const raw = '呃，今天下午要開會，然後，討論那個架構優化，就是說我想我想把代碼重構。';
      final result = cleaner.cleanWithStats(raw);

      expect(result.removedFillersCount, greaterThan(0));
      expect(result.removedDuplicatesCount, greaterThan(0));
      expect(result.cleanedText.contains('呃'), isFalse);
      expect(result.cleanedText.contains('我想我想'), isFalse);
      expect(result.cleanedText.contains('我想'), isTrue);
    });

    test('Removes English filler words and word repetitions', () {
      const raw = 'Um, we should like basically review the the pull request today.';
      final cleaned = cleaner.clean(raw);

      expect(cleaned.toLowerCase().contains('um'), isFalse);
      expect(cleaned.toLowerCase().contains('basically'), isFalse);
      expect(cleaned.toLowerCase().contains('the the'), isFalse);
      expect(cleaned.contains('pull request'), isTrue);
    });

    test('Handles empty and clean text gracefully', () {
      expect(cleaner.clean(''), '');
      expect(cleaner.clean('   '), '');
      expect(cleaner.clean('乾淨的筆記文字'), '乾淨的筆記文字');
    });
  });

  group('DailyDigestModel Tests', () {
    final now = DateTime.now();

    final testCapsules = [
      CapsuleModel(
        id: '1',
        title: '產品規劃會議',
        rawTranscript: '討論靈感晚報與多格式導出功能。',
        summary: '規劃完成 Phase 3 日報與匯出模組。',
        actionItems: ['撰寫單元測試', '驗證語系檔案'],
        createdAt: now,
        isProcessed: false,
        tags: ['工作', '產品'],
      ),
      CapsuleModel(
        id: '2',
        title: '技術架構優化',
        rawTranscript: '代碼清理與語音過濾引擎。',
        summary: '實作 SpeechCleanerService 贅詞過濾。',
        actionItems: ['優化正規表達式'],
        createdAt: now,
        isProcessed: true,
        tags: ['技術'],
      ),
      CapsuleModel(
        id: '3',
        title: '昨天的筆記',
        rawTranscript: '這是昨天的內容。',
        summary: '昨日摘要。',
        actionItems: ['昨日待辦'],
        createdAt: now.subtract(const Duration(days: 1)),
        isProcessed: false,
        tags: ['歷史'],
      ),
    ];

    test('Correctly aggregates capsules for the target date only', () {
      final digest = DailyDigestModel.fromCapsules(now, testCapsules);

      expect(digest.totalCapsules, 2);
      expect(digest.processedCount, 1);
      expect(digest.pendingCount, 1);
      expect(digest.completionRate, 0.5);
      expect(digest.keySummaries.length, 2);
      expect(digest.pendingActionItems.length, 3);
      expect(digest.tagDistribution['工作'], 1);
      expect(digest.tagDistribution['技術'], 1);
    });

    test('Generates Markdown, Plain Text, and Notion format', () {
      final digest = DailyDigestModel.fromCapsules(now, testCapsules);

      final md = digest.toMarkdown();
      expect(md.contains('# 📰 Daily Inspiration Digest'), isTrue);
      expect(md.contains('產品規劃會議'), isTrue);
      expect(md.contains('撰寫單元測試'), isTrue);

      final txt = digest.toPlainText();
      expect(txt.contains('DAILY INSPIRATION DIGEST'), isTrue);
      expect(txt.contains('[KEY SUMMARIES]'), isTrue);

      final notion = digest.toNotionFormat();
      expect(notion.contains('# 📓 Daily Digest'), isTrue);
      expect(notion.contains('### ⚡ Action Items'), isTrue);
    });
  });

  group('ExportService Tests', () {
    final now = DateTime.now();
    final sampleCapsule = CapsuleModel(
      id: 'test-capsule-1',
      title: '測試膠囊',
      rawTranscript: '原始語音內容',
      summary: '核心精華摘要',
      actionItems: ['待辦項目一', '待辦項目二'],
      createdAt: now,
      isProcessed: false,
      tags: ['測試', '靈感'],
    );

    test('Formats single capsule to Markdown, Text, and Notion format', () {
      final exportService = ExportService.instance;

      final md = exportService.formatCapsule(sampleCapsule, ExportFormat.markdown);
      expect(md.contains('# 測試膠囊'), isTrue);
      expect(md.contains('## 💡 Summary'), isTrue);
      expect(md.contains('待辦項目一'), isTrue);

      final txt = exportService.formatCapsule(sampleCapsule, ExportFormat.plainText);
      expect(txt.contains('CAPSULE NOTE: 測試膠囊'), isTrue);
      expect(txt.contains('[SUMMARY]'), isTrue);

      final notion = exportService.formatCapsule(sampleCapsule, ExportFormat.notion);
      expect(notion.contains('# 💊 測試膠囊'), isTrue);
      expect(notion.contains('### ⚡ Action Items'), isTrue);
    });
  });
}
