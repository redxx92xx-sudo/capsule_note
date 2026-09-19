import 'package:flutter_test/flutter_test.dart';
import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/models/daily_digest_model.dart';
import 'package:capsule_note/services/export_service.dart';
import 'package:capsule_note/services/speech_cleaner_service.dart';

void main() {
  group('SpeechCleanerService Tests', () {
    final cleaner = SpeechCleanerService.instance;

    test('cleans English filler words and extracts core meaning', () {
      const raw =
          'Um you know basically we need to finish the sprint review actually.';
      final cleaned = cleaner.clean(raw);

      expect(cleaned.toLowerCase().contains('basically'), false);
      expect(cleaned.toLowerCase().contains('you know'), false);
      expect(cleaned.toLowerCase().contains('um'), false);
      expect(cleaned.contains('finish the sprint review'), true);
    });

    test('cleans repetitive patterns and empty inputs', () {
      expect(cleaner.clean(''), '');
      final rep = cleaner.clean('aaaaabbbb');
      expect(rep, 'ab');
    });
  });

  group('DailyDigestModel Tests', () {
    final now = DateTime.now();
    final sampleCapsules = [
      CapsuleModel(
        id: 'c1',
        title: 'Project Architecture',
        rawTranscript: 'Discuss architecture',
        summary: 'Refactor core service',
        actionItems: ['Submit PR', 'Run unit tests'],
        createdAt: now,
        isProcessed: false,
        tags: ['Tech'],
      ),
      CapsuleModel(
        id: 'c2',
        title: 'Shopping Task',
        rawTranscript: 'Buy groceries',
        summary: 'Buy milk and bread',
        actionItems: ['Buy milk', 'Buy bread'],
        createdAt: now,
        isProcessed: true,
        tags: ['Life'],
      ),
    ];

    test('generates digest from today capsules correctly', () {
      final digest = DailyDigestModel.generateFromCapsules(sampleCapsules);

      expect(digest.totalNotesCount, 2);
      expect(digest.processedNotesCount, 1);
      expect(digest.keyHighlights, contains('Refactor core service'));
      expect(digest.keyHighlights, contains('Buy milk and bread'));
      expect(digest.pendingActionItems, contains('Submit PR'));
      expect(digest.pendingActionItems, contains('Run unit tests'));
      expect(digest.pendingActionItems.contains('Buy milk'), false);
    });

    test('generates markdown and notion formats', () {
      final digest = DailyDigestModel.generateFromCapsules(sampleCapsules);
      final md = digest.toMarkdown();
      final notion = digest.toNotionFormat();

      expect(md.contains('Refactor core service'), true);
      expect(md.contains('Submit PR'), true);

      expect(notion.contains('Daily Digest'), true);
      expect(notion.contains('Key Takeaways'), true);
    });
  });

  group('ExportService Formatting Tests', () {
    final exporter = ExportService.instance;
    final capsule = CapsuleModel(
      id: 'test-1',
      title: 'Design Inspiration Note',
      rawTranscript: 'Raw audio transcript text',
      summary: 'Core summary takeaways',
      actionItems: ['Task Action Item 1'],
      createdAt: DateTime.now(),
      tags: ['Work', 'Ideas'],
    );

    test('formats capsule to markdown, txt, and notion', () {
      final md = exporter.formatCapsule(capsule, ExportFormat.markdown);
      final txt = exporter.formatCapsule(capsule, ExportFormat.plainText);
      final notion = exporter.formatCapsule(capsule, ExportFormat.notion);

      expect(md.contains('Design Inspiration Note'), true);
      expect(md.contains('Core summary takeaways'), true);
      expect(md.contains('Task Action Item 1'), true);

      expect(txt.contains('Design Inspiration Note'), true);
      expect(txt.contains('Core summary takeaways'), true);

      expect(notion.contains('Design Inspiration Note'), true);
      expect(notion.contains('Core summary takeaways'), true);
      expect(notion.contains('Task Action Item 1'), true);
    });
  });
}
