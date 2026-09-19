import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Local AAC recording / playback. Audio is stored under the app documents
/// directory (`capsule_audio/`), not the OS temp folder.
class AudioRecordService {
  static final AudioRecordService instance = AudioRecordService._internal();
  AudioRecordService._internal();

  static const String audioFolderName = 'capsule_audio';

  /// Test hooks — when set, skip real path_provider lookups.
  @visibleForTesting
  static Future<Directory> Function()? documentsDirectoryOverride;

  @visibleForTesting
  static Future<Directory> Function()? temporaryDirectoryOverride;

  AudioRecorder? _audioRecorder;
  AudioPlayer? _audioPlayer;

  AudioRecorder get recorder => _audioRecorder ??= AudioRecorder();
  AudioPlayer get player => _audioPlayer ??= AudioPlayer();

  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Stream<Duration> get onPositionChanged => player.onPositionChanged;
  Stream<Duration> get onDurationChanged => player.onDurationChanged;
  Stream<PlayerState> get onPlayerStateChanged => player.onPlayerStateChanged;

  Future<Directory> _documentsRoot() async {
    if (documentsDirectoryOverride != null) {
      return documentsDirectoryOverride!();
    }
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> _temporaryRoot() async {
    if (temporaryDirectoryOverride != null) {
      return temporaryDirectoryOverride!();
    }
    return getTemporaryDirectory();
  }

  /// Permanent audio directory under app documents.
  Future<Directory> ensurePermanentAudioDir() async {
    if (kIsWeb) {
      throw UnsupportedError('Permanent audio dir is not used on web');
    }
    final root = await _documentsRoot();
    final dir = Directory('${root.path}/$audioFolderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> temporaryAudioDir() async {
    final root = await _temporaryRoot();
    return Directory('${root.path}/$audioFolderName');
  }

  bool isUnderTemporaryAudioDir(String path, Directory tempAudioDir) {
    final normalized = path.replaceAll('\\', '/');
    final prefix = tempAudioDir.path.replaceAll('\\', '/');
    return normalized.startsWith(prefix);
  }

  bool isUnderPermanentAudioDir(String path, Directory permanentDir) {
    final normalized = path.replaceAll('\\', '/');
    final prefix = permanentDir.path.replaceAll('\\', '/');
    return normalized.startsWith(prefix);
  }

  /// True when [path] points to an existing non-empty file.
  Future<bool> audioFileExists(String? path) async {
    if (path == null || path.isEmpty || kIsWeb) return false;
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      return await file.length() > 0;
    } catch (e) {
      debugPrint('audioFileExists check failed: $e');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      return await recorder.hasPermission();
    } catch (e) {
      debugPrint('Error checking mic permission: $e');
      return false;
    }
  }

  Future<String?> startRecording() async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        debugPrint('Mic permission denied');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String filePath;

      if (kIsWeb) {
        filePath = 'capsule_$timestamp.m4a';
      } else {
        final audioDir = await ensurePermanentAudioDir();
        filePath = '${audioDir.path}${Platform.pathSeparator}capsule_$timestamp.m4a';
      }

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Record path immediately so interruptions still leave a known location.
      _currentRecordingPath = filePath;
      await recorder.start(config, path: filePath);
      _isRecording = true;
      debugPrint('Recording started at: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error starting record: $e');
      _isRecording = false;
      // Keep _currentRecordingPath if a file may have been created.
      return _currentRecordingPath;
    }
  }

  Future<String?> stopRecording() async {
    final knownPath = _currentRecordingPath;
    try {
      if (!_isRecording && knownPath == null) return null;

      String? stoppedPath;
      try {
        if (_isRecording) {
          stoppedPath = await recorder.stop();
        }
      } catch (e) {
        debugPrint('Error stopping record (keeping file): $e');
        // Do not delete audio; keep known path.
      }

      _isRecording = false;
      final candidate = stoppedPath ?? knownPath;
      if (candidate == null) return null;

      if (!kIsWeb) {
        final file = File(candidate);
        if (await file.exists()) {
          final length = await file.length();
          if (length > 0) {
            _currentRecordingPath = candidate;
            debugPrint('Recording stopped OK: $candidate ($length bytes)');
            return candidate;
          }
          debugPrint('Recording file empty but kept path: $candidate');
        } else {
          debugPrint('Recording file missing after stop; keeping path: $candidate');
        }
      }

      _currentRecordingPath = candidate;
      return candidate;
    } catch (e) {
      debugPrint('Error in stopRecording (keeping file): $e');
      _isRecording = false;
      return knownPath;
    }
  }

  /// Move/copy a recording into permanent dir named by [capsuleId].
  /// Never deletes the source on failure.
  Future<String?> bindAudioToCapsuleId({
    required String capsuleId,
    required String? sourcePath,
  }) async {
    if (sourcePath == null || sourcePath.isEmpty || kIsWeb) return sourcePath;

    try {
      final permanentDir = await ensurePermanentAudioDir();
      final destPath =
          '${permanentDir.path}${Platform.pathSeparator}capsule_$capsuleId.m4a';

      if (sourcePath.replaceAll('\\', '/') == destPath.replaceAll('\\', '/')) {
        return destPath;
      }

      final source = File(sourcePath);
      if (!await source.exists() || await source.length() <= 0) {
        debugPrint('bindAudioToCapsuleId: source missing/empty: $sourcePath');
        return sourcePath;
      }

      final dest = File(destPath);
      if (await dest.exists()) {
        await dest.delete();
      }

      try {
        await source.rename(destPath);
      } catch (_) {
        await source.copy(destPath);
        // Keep source if copy succeeded (may be on another volume).
        // Prefer leaving source rather than risking data loss.
      }

      if (await dest.exists() && await dest.length() > 0) {
        _currentRecordingPath = destPath;
        return destPath;
      }
      return sourcePath;
    } catch (e) {
      debugPrint('bindAudioToCapsuleId failed (keeping source): $e');
      return sourcePath;
    }
  }

  /// If [path] is under the old temp folder and still exists, move to permanent.
  /// On failure keeps the original path and logs a warning.
  Future<String?> migrateTempAudioIfNeeded(String? path) async {
    if (path == null || path.isEmpty || kIsWeb) return path;

    try {
      final file = File(path);
      if (!await file.exists()) return path;

      final tempDir = await temporaryAudioDir();
      if (!isUnderTemporaryAudioDir(path, tempDir)) {
        return path;
      }

      final permanentDir = await ensurePermanentAudioDir();
      final name = path.split(Platform.pathSeparator).last;
      final destPath = '${permanentDir.path}${Platform.pathSeparator}$name';

      if (path.replaceAll('\\', '/') == destPath.replaceAll('\\', '/')) {
        return path;
      }

      final dest = File(destPath);
      try {
        if (await dest.exists()) {
          // Already migrated under same name — prefer permanent.
          return destPath;
        }
        await file.rename(destPath);
      } catch (e) {
        try {
          await file.copy(destPath);
        } catch (copyError) {
          debugPrint(
            'Warning: failed to migrate temp audio $path → $destPath: $copyError',
          );
          return path;
        }
      }

      if (await dest.exists() && await dest.length() > 0) {
        debugPrint('Migrated temp audio to: $destPath');
        return destPath;
      }

      debugPrint('Warning: migrate produced empty/missing dest for $path');
      return path;
    } catch (e) {
      debugPrint('Warning: migrateTempAudioIfNeeded failed for $path: $e');
      return path;
    }
  }

  /// Delete only the given audio file. Never clears the whole directory.
  Future<void> deleteAudioFile(String? path) async {
    if (path == null || path.isEmpty || kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted audio file: $path');
      }
    } catch (e) {
      debugPrint('Error deleting audio file $path: $e');
    }
  }

  /// Returns false if the file is missing (caller should show a message).
  Future<bool> playAudio(String path) async {
    try {
      if (!kIsWeb && !path.startsWith('http')) {
        final exists = await audioFileExists(path);
        if (!exists) {
          debugPrint('playAudio: file missing: $path');
          return false;
        }
      }
      await player.stop();
      if (kIsWeb || path.startsWith('http')) {
        await player.play(UrlSource(path));
      } else {
        await player.play(DeviceFileSource(path));
      }
      return true;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      return false;
    }
  }

  Future<void> pauseAudio() async {
    try {
      await player.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> resumeAudio() async {
    try {
      await player.resume();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await player.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> seekAudio(Duration position) async {
    try {
      await player.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  Future<void> dispose() async {
    await _audioRecorder?.dispose();
    await _audioPlayer?.dispose();
  }

  @visibleForTesting
  void debugResetRecordingState() {
    _isRecording = false;
    _currentRecordingPath = null;
  }

  @visibleForTesting
  void debugSetCurrentRecordingPath(String? path) {
    _currentRecordingPath = path;
  }
}
