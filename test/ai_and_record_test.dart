import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capsule_note/services/ai_summary_service.dart';
import 'package:capsule_note/services/audio_record_service.dart';
import 'package:capsule_note/services/monetization_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AiSummaryService Tests', () {
    final ai = AiSummaryService.instance;

    test('structures transcript with actions and tags correctly', () async {
      const transcript = '今天下午要確認墨水屏調色盤，記得聯絡設計師討論專案進度，然後去買杯咖啡。';
      final result = await ai.structureTranscript(transcript);

      expect(result.title.isNotEmpty, true);
      expect(result.summary.isNotEmpty, true);
      expect(result.actionItems.length, greaterThanOrEqualTo(2));
      expect(result.tags.isNotEmpty, true);
    });

    test('handles empty transcript gracefully', () async {
      final result = await ai.structureTranscript('');
      expect(result.title, '未命名靈感膠囊');
      expect(result.actionItems.isNotEmpty, true);
      expect(result.tags.isNotEmpty, true);
    });

    test('filters filler words and extracts English tasks', () async {
      const transcript =
          'Um basically we need to check the API response and send the email to client, you know.';
      final result = await ai.structureTranscript(transcript);

      expect(result.summary.contains('basically'), false);
      expect(result.summary.contains('you know'), false);
      expect(result.actionItems.isNotEmpty, true);
      expect(result.tags.isNotEmpty, true);
    });
  });

  group('AudioRecordService Tests', () {
    final audio = AudioRecordService.instance;

    test('initializes with default state', () {
      expect(audio.isRecording, false);
      expect(audio.currentRecordingPath, null);
    });

    test('permanent folder name is capsule_audio', () {
      expect(AudioRecordService.audioFolderName, 'capsule_audio');
    });
  });

  group('Monetization Ad Frequency Tests', () {
    test('tracks creation count and handles pro status', () async {
      final mon = MonetizationProvider();
      await mon.initialized;

      expect(mon.creationCount, 0);

      await mon.onCapsuleCreated();
      expect(mon.creationCount, 1);

      await mon.onCapsuleCreated();
      expect(mon.creationCount, 2);

      await mon.onCapsuleCreated();
      expect(mon.creationCount, 3);

      await mon.setProStatus(true);
      await mon.onCapsuleCreated();
      expect(mon.creationCount, 3);
    });
  });
}
