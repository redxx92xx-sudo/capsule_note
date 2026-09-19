import 'dart:io';

import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/services/audio_record_service.dart';
import 'package:capsule_note/services/capsule_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsRoot;
  late Directory tempRoot;
  late AudioRecordService audio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docsRoot = await Directory.systemTemp.createTemp('capsule_docs_');
    tempRoot = await Directory.systemTemp.createTemp('capsule_temp_');
    AudioRecordService.documentsDirectoryOverride = () async => docsRoot;
    AudioRecordService.temporaryDirectoryOverride = () async => tempRoot;
    audio = AudioRecordService.instance;
    audio.debugResetRecordingState();
  });

  tearDown(() async {
    AudioRecordService.documentsDirectoryOverride = null;
    AudioRecordService.temporaryDirectoryOverride = null;
    audio.debugResetRecordingState();
    if (await docsRoot.exists()) await docsRoot.delete(recursive: true);
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  group('permanent audio path', () {
    test('recording path is under documents/capsule_audio', () async {
      final dir = await audio.ensurePermanentAudioDir();
      expect(dir.path.replaceAll('\\', '/'), contains('capsule_audio'));
      expect(
        dir.path.replaceAll('\\', '/'),
        startsWith(docsRoot.path.replaceAll('\\', '/')),
      );
      expect(await dir.exists(), isTrue);

      // Simulate startRecording path layout without mic hardware.
      final filePath =
          '${dir.path}${Platform.pathSeparator}capsule_123.m4a';
      expect(
        filePath.replaceAll('\\', '/'),
        contains('/capsule_audio/'),
      );
      expect(
        audio.isUnderPermanentAudioDir(filePath, dir),
        isTrue,
      );
    });

    test('stopRecording keeps path when stop fails / not actively recording',
        () async {
      final dir = await audio.ensurePermanentAudioDir();
      final path = '${dir.path}${Platform.pathSeparator}capsule_keep.m4a';
      final file = File(path);
      await file.writeAsBytes(List<int>.filled(64, 1));

      audio.debugSetCurrentRecordingPath(path);
      // _isRecording is false → stop path falls back to known path, no delete.
      final result = await audio.stopRecording();

      expect(result, path);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));
    });

    test('file exists after writing recording bytes', () async {
      final dir = await audio.ensurePermanentAudioDir();
      final path = '${dir.path}${Platform.pathSeparator}capsule_ok.m4a';
      await File(path).writeAsBytes(List<int>.filled(32, 7));

      expect(await audio.audioFileExists(path), isTrue);
      expect(await audio.playAudio('/no/such/file.m4a'), isFalse);
    });
  });

  group('migrate temp audio', () {
    test('moves legacy temp file into permanent dir', () async {
      final tempAudio = Directory(
        '${tempRoot.path}${Platform.pathSeparator}capsule_audio',
      );
      await tempAudio.create(recursive: true);
      final legacyPath =
          '${tempAudio.path}${Platform.pathSeparator}capsule_legacy.m4a';
      await File(legacyPath).writeAsBytes(List<int>.filled(48, 3));

      final migrated = await audio.migrateTempAudioIfNeeded(legacyPath);
      expect(migrated, isNotNull);
      expect(migrated!.replaceAll('\\', '/'), isNot(equals(legacyPath.replaceAll('\\', '/'))));
      expect(await File(migrated).exists(), isTrue);
      expect(await File(migrated).length(), greaterThan(0));

      final permanentDir = await audio.ensurePermanentAudioDir();
      expect(audio.isUnderPermanentAudioDir(migrated, permanentDir), isTrue);
    });

    test('keeps original path when migrate fails', () async {
      final missing =
          '${tempRoot.path}${Platform.pathSeparator}capsule_audio${Platform.pathSeparator}gone.m4a';
      // Parent temp audio dir exists but file does not — returns original.
      await Directory(
        '${tempRoot.path}${Platform.pathSeparator}capsule_audio',
      ).create(recursive: true);

      final result = await audio.migrateTempAudioIfNeeded(missing);
      expect(result, missing);
    });
  });

  group('bind / delete', () {
    test('bindAudioToCapsuleId renames into capsule-id file', () async {
      final dir = await audio.ensurePermanentAudioDir();
      final source =
          '${dir.path}${Platform.pathSeparator}capsule_raw.m4a';
      await File(source).writeAsBytes(List<int>.filled(40, 9));

      final bound = await audio.bindAudioToCapsuleId(
        capsuleId: 'abc-123',
        sourcePath: source,
      );

      expect(bound, endsWith('capsule_abc-123.m4a'));
      expect(await File(bound!).exists(), isTrue);
      expect(await File(bound).length(), greaterThan(0));
    });

    test('deleteAudioFile removes only the given file', () async {
      final dir = await audio.ensurePermanentAudioDir();
      final a = File('${dir.path}${Platform.pathSeparator}a.m4a');
      final b = File('${dir.path}${Platform.pathSeparator}b.m4a');
      await a.writeAsBytes([1, 2, 3]);
      await b.writeAsBytes([4, 5, 6]);

      await audio.deleteAudioFile(a.path);

      expect(await a.exists(), isFalse);
      expect(await b.exists(), isTrue);
      expect(await dir.exists(), isTrue);
    });
  });

  group('CapsuleProvider audio lifecycle', () {
    test('addCapsule with empty transcript still binds audio', () async {
      final dir = await audio.ensurePermanentAudioDir();
      final source =
          '${dir.path}${Platform.pathSeparator}capsule_empty_tx.m4a';
      await File(source).writeAsBytes(List<int>.filled(20, 2));

      final provider = CapsuleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      while (provider.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final capsule = await provider.addCapsule(
        title: '僅錄音',
        rawTranscript: '',
        audioPath: source,
        isProcessed: false,
      );

      expect(capsule.audioPath, isNotNull);
      expect(await audio.audioFileExists(capsule.audioPath), isTrue);
      expect(capsule.title, isNotEmpty);
    });

    test('deleteCapsule deletes only that capsule audio', () async {
      final dir = await audio.ensurePermanentAudioDir();
      final src1 = '${dir.path}${Platform.pathSeparator}src1.m4a';
      final src2 = '${dir.path}${Platform.pathSeparator}src2.m4a';
      await File(src1).writeAsBytes(List<int>.filled(16, 1));
      await File(src2).writeAsBytes(List<int>.filled(16, 2));

      final provider = CapsuleProvider();
      while (provider.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final c1 = await provider.addCapsule(
        title: 'A',
        rawTranscript: 'hello',
        audioPath: src1,
      );
      final c2 = await provider.addCapsule(
        title: 'B',
        rawTranscript: 'world',
        audioPath: src2,
      );

      final path1 = c1.audioPath!;
      final path2 = c2.audioPath!;
      expect(await File(path1).exists(), isTrue);
      expect(await File(path2).exists(), isTrue);

      await provider.deleteCapsule(c1.id);

      expect(await File(path1).exists(), isFalse);
      expect(await File(path2).exists(), isTrue);
      expect(provider.capsules.any((c) => c.id == c2.id), isTrue);
    });

    test('updateCapsule never overwrites valid audioPath with null', () async {
      final provider = CapsuleProvider();
      while (provider.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final dir = await audio.ensurePermanentAudioDir();
      final src = '${dir.path}${Platform.pathSeparator}keep.m4a';
      await File(src).writeAsBytes([1, 2, 3, 4]);

      final created = await provider.addCapsule(
        title: 'Keep audio',
        rawTranscript: 'x',
        audioPath: src,
      );
      final keptPath = created.audioPath;
      expect(keptPath, isNotNull);

      await provider.updateCapsule(
        CapsuleModel(
          id: created.id,
          title: 'Updated',
          rawTranscript: 'y',
          createdAt: created.createdAt,
          audioPath: null,
        ),
      );

      final updated =
          provider.capsules.firstWhere((c) => c.id == created.id);
      expect(updated.audioPath, keptPath);
      expect(updated.title, 'Updated');
    });

    test('text processing failure path still preserves audio on add', () async {
      final dir = await audio.ensurePermanentAudioDir();
      final src =
          '${dir.path}${Platform.pathSeparator}preserve_on_ai_fail.m4a';
      await File(src).writeAsBytes(List<int>.filled(24, 5));

      // Empty transcript + no title triggers AI; even if AI returns defaults,
      // audio must remain bound and not deleted.
      final provider = CapsuleProvider();
      while (provider.isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final capsule = await provider.addCapsule(
        rawTranscript: '',
        audioPath: src,
      );

      expect(await audio.audioFileExists(capsule.audioPath), isTrue);
      // Source may have been renamed into capsule_*.m4a — either way file lives.
      final permanentDir = await audio.ensurePermanentAudioDir();
      final files = permanentDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .toList();
      expect(files, isNotEmpty);
    });
  });
}
