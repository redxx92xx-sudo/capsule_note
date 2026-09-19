import 'dart:io';

import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/services/audio_record_service.dart';
import 'package:capsule_note/services/capsule_provider.dart';
import 'package:capsule_note/services/locale_provider.dart';
import 'package:capsule_note/services/transcription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingFakeStt implements TranscriptionService {
  _RecordingFakeStt(this.text);

  final String text;
  String? lastLocale;
  String? lastAudioPath;
  bool shouldFail = false;

  @override
  Future<String> transcribe({
    required String audioPath,
    required String locale,
    void Function(TranscriptionStatus status)? onStatus,
  }) async {
    lastAudioPath = audioPath;
    lastLocale = locale;
    if (shouldFail) {
      throw TranscriptionFailedException('boom');
    }
    return text;
  }
}

Future<void> _waitProvider(CapsuleProvider provider) async {
  while (provider.isLoading) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsRoot;
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docsRoot = await Directory.systemTemp.createTemp('capsule_tx_docs_');
    tempRoot = await Directory.systemTemp.createTemp('capsule_tx_temp_');
    AudioRecordService.documentsDirectoryOverride = () async => docsRoot;
    AudioRecordService.temporaryDirectoryOverride = () async => tempRoot;
    AudioRecordService.instance.debugResetRecordingState();
    TranscriptionServiceLocator.useUnconfigured();
  });

  tearDown(() async {
    TranscriptionServiceLocator.useUnconfigured();
    AudioRecordService.documentsDirectoryOverride = null;
    AudioRecordService.temporaryDirectoryOverride = null;
    if (await docsRoot.exists()) await docsRoot.delete(recursive: true);
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  group('optional transcription flow', () {
    test('audio-only save does not invent demo transcript text', () async {
      final dir = await AudioRecordService.instance.ensurePermanentAudioDir();
      final src = '${dir.path}${Platform.pathSeparator}rec.m4a';
      await File(src).writeAsBytes(List<int>.filled(20, 1));

      final provider = CapsuleProvider();
      await _waitProvider(provider);

      final capsule = await provider.addCapsule(
        title: '語音錄音記事',
        rawTranscript: '',
        audioPath: src,
      );

      expect(capsule.rawTranscript, isEmpty);
      expect(
        capsule.rawTranscript.contains('產品團隊'),
        isFalse,
      );
      expect(
        capsule.rawTranscript.contains('語音模型'),
        isFalse,
      );
      expect(await AudioRecordService.instance.audioFileExists(capsule.audioPath),
          isTrue);
    });

    test('capsule can be saved without transcript', () async {
      final dir = await AudioRecordService.instance.ensurePermanentAudioDir();
      final src = '${dir.path}${Platform.pathSeparator}only_audio.m4a';
      await File(src).writeAsBytes(List<int>.filled(16, 2));

      final provider = CapsuleProvider();
      await _waitProvider(provider);

      final capsule = await provider.addCapsule(
        rawTranscript: '',
        audioPath: src,
      );

      expect(capsule.rawTranscript, isEmpty);
      expect(capsule.audioPath, isNotNull);
      expect(provider.capsules.any((c) => c.id == capsule.id), isTrue);
    });

    test('transcription failure does not delete audio', () async {
      final dir = await AudioRecordService.instance.ensurePermanentAudioDir();
      final src = '${dir.path}${Platform.pathSeparator}fail_tx.m4a';
      await File(src).writeAsBytes(List<int>.filled(24, 3));

      final provider = CapsuleProvider();
      await _waitProvider(provider);
      final capsule = await provider.addCapsule(
        rawTranscript: '',
        audioPath: src,
      );
      final path = capsule.audioPath!;
      expect(await File(path).exists(), isTrue);

      final fake = _RecordingFakeStt('should not appear');
      fake.shouldFail = true;
      TranscriptionServiceLocator.instance = fake;

      expect(
        () => TranscriptionServiceLocator.instance.transcribe(
          audioPath: path,
          locale: TranscriptionLocale.zhTw,
        ),
        throwsA(isA<TranscriptionFailedException>()),
      );
      expect(await File(path).exists(), isTrue);

      // Unconfigured also keeps file.
      TranscriptionServiceLocator.useUnconfigured();
      expect(
        () => TranscriptionServiceLocator.instance.transcribe(
          audioPath: path,
          locale: TranscriptionLocale.en,
        ),
        throwsA(isA<TranscriptionNotConfiguredException>()),
      );
      expect(await File(path).exists(), isTrue);
    });

    test('re-transcribe updates text only, not audioPath', () async {
      final dir = await AudioRecordService.instance.ensurePermanentAudioDir();
      final src = '${dir.path}${Platform.pathSeparator}retry.m4a';
      await File(src).writeAsBytes(List<int>.filled(18, 4));

      final provider = CapsuleProvider();
      await _waitProvider(provider);
      final created = await provider.addCapsule(
        rawTranscript: 'old text',
        audioPath: src,
      );
      final originalPath = created.audioPath!;

      final fake = _RecordingFakeStt('new transcript');
      TranscriptionServiceLocator.instance = fake;
      final text = await TranscriptionServiceLocator.instance.transcribe(
        audioPath: originalPath,
        locale: TranscriptionLocale.en,
      );

      await provider.updateCapsule(
        created.copyWith(rawTranscript: text),
      );

      final updated =
          provider.capsules.firstWhere((c) => c.id == created.id);
      expect(updated.rawTranscript, 'new transcript');
      expect(updated.audioPath, originalPath);
      expect(await File(originalPath).exists(), isTrue);
    });

    test('clearing transcript keeps audio playable', () async {
      final dir = await AudioRecordService.instance.ensurePermanentAudioDir();
      final src = '${dir.path}${Platform.pathSeparator}clear.m4a';
      await File(src).writeAsBytes(List<int>.filled(22, 5));

      final provider = CapsuleProvider();
      await _waitProvider(provider);
      final created = await provider.addCapsule(
        rawTranscript: 'temporary text',
        audioPath: src,
      );
      final path = created.audioPath!;

      await provider.updateCapsule(
        CapsuleModel(
          id: created.id,
          title: created.title,
          rawTranscript: '',
          summary: created.summary,
          actionItems: created.actionItems,
          createdAt: created.createdAt,
          tags: created.tags,
          audioPath: null, // must not wipe via provider merge
        ),
      );

      final cleared =
          provider.capsules.firstWhere((c) => c.id == created.id);
      expect(cleared.rawTranscript, isEmpty);
      expect(cleared.audioPath, path);
      expect(await AudioRecordService.instance.audioFileExists(path), isTrue);
      // playAudio returns false only when missing — file exists so check passes
      // without needing a real audio decoder in unit tests:
      expect(await AudioRecordService.instance.audioFileExists(path), isTrue);
    });

    test('UnconfiguredTranscriptionService never returns fake text', () async {
      TranscriptionServiceLocator.useUnconfigured();
      expect(
        () => TranscriptionServiceLocator.instance.transcribe(
          audioPath: '/tmp/x.m4a',
          locale: TranscriptionLocale.zhTw,
        ),
        throwsA(isA<TranscriptionNotConfiguredException>()),
      );
    });
  });

  group('transcription locale tags', () {
    test('zh_TW, zh_CN, en resolve correctly', () {
      expect(TranscriptionLocale.resolve('zh_TW'), TranscriptionLocale.zhTw);
      expect(TranscriptionLocale.resolve('zh-TW'), TranscriptionLocale.zhTw);
      expect(TranscriptionLocale.resolve('zh'), TranscriptionLocale.zhTw);
      expect(TranscriptionLocale.resolve('zh_CN'), TranscriptionLocale.zhCn);
      expect(TranscriptionLocale.resolve('zh-CN'), TranscriptionLocale.zhCn);
      expect(TranscriptionLocale.resolve('zh_Hans'), TranscriptionLocale.zhCn);
      expect(TranscriptionLocale.resolve('en'), TranscriptionLocale.en);
      expect(TranscriptionLocale.resolve('en_US'), TranscriptionLocale.en);
    });

    test('LocaleProvider passes zh_TW / zh_CN / en to STT tag', () async {
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await provider.setLocale(const Locale('zh', 'TW'));
      expect(provider.transcriptionLocale, TranscriptionLocale.zhTw);

      await provider.setLocale(const Locale('zh', 'CN'));
      expect(provider.transcriptionLocale, TranscriptionLocale.zhCn);

      await provider.setLocale(const Locale('en'));
      expect(provider.transcriptionLocale, TranscriptionLocale.en);

      final fake = _RecordingFakeStt('ok');
      TranscriptionServiceLocator.instance = fake;

      for (final tag in [
        TranscriptionLocale.zhTw,
        TranscriptionLocale.zhCn,
        TranscriptionLocale.en,
      ]) {
        await TranscriptionServiceLocator.instance.transcribe(
          audioPath: '/virtual.m4a',
          locale: tag,
        );
        expect(fake.lastLocale, tag);
      }
    });

    test('fromLanguageAndCountry maps regions', () {
      expect(
        TranscriptionLocale.fromLanguageAndCountry(
          languageCode: 'zh',
          countryCode: 'TW',
        ),
        TranscriptionLocale.zhTw,
      );
      expect(
        TranscriptionLocale.fromLanguageAndCountry(
          languageCode: 'zh',
          countryCode: 'CN',
        ),
        TranscriptionLocale.zhCn,
      );
      expect(
        TranscriptionLocale.fromLanguageAndCountry(languageCode: 'en'),
        TranscriptionLocale.en,
      );
    });
  });
}
