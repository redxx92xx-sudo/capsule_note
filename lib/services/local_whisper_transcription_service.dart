import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import 'transcription_service.dart';

/// On-device Whisper (whisper.cpp via whisper_ggml). Never uploads audio.
class LocalWhisperTranscriptionService implements TranscriptionService {
  LocalWhisperTranscriptionService({
    this.assetModelPath = defaultAssetModelPath,
    this.modelFileName = defaultModelFileName,
  });

  /// Official multilingual tiny Q5_1 (~31 MB) from ggerganov/whisper.cpp.
  static const String defaultAssetModelPath =
      'assets/models/ggml-tiny-q5_1.bin';
  static const String defaultModelFileName = 'ggml-tiny-q5_1.bin';

  final String assetModelPath;
  final String modelFileName;

  /// Test hook — skip path_provider when set.
  @visibleForTesting
  static Future<Directory> Function()? supportDirectoryOverride;

  /// Test hook — supply model bytes without rootBundle.
  @visibleForTesting
  static Future<ByteData> Function(String assetPath)? assetLoaderOverride;

  int _jobId = 0;
  int? _activeJobId;
  bool _modelReady = false;
  String? _resolvedModelPath;

  void Function(TranscriptionStatus status)? onStatus;

  /// Soft-cancel: ignore results for the active job. Does not delete audio.
  void cancel() {
    if (_activeJobId == null) return;
    _jobId++;
    _activeJobId = null;
    _emit(const TranscriptionStatus(
      phase: TranscriptionPhase.cancelled,
      message: 'cancelled',
    ));
  }

  bool get isBusy => _activeJobId != null;

  /// Copy bundled model into app support dir (offline; no network).
  Future<String> ensureModelInitialized() async {
    if (_modelReady &&
        _resolvedModelPath != null &&
        await File(_resolvedModelPath!).exists()) {
      return _resolvedModelPath!;
    }

    _emit(const TranscriptionStatus(phase: TranscriptionPhase.preparing));

    final support = supportDirectoryOverride != null
        ? await supportDirectoryOverride!()
        : await getApplicationSupportDirectory();
    final destDir = Directory('${support.path}/whisper_models');
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final destPath = '${destDir.path}/$modelFileName';
    final dest = File(destPath);

    if (!await dest.exists() || await dest.length() < 1024) {
      try {
        final ByteData data = assetLoaderOverride != null
            ? await assetLoaderOverride!(assetModelPath)
            : await rootBundle.load(assetModelPath);
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        if (bytes.length < 1024) {
          throw TranscriptionModelMissingException(
            'Bundled model is empty: $assetModelPath',
          );
        }
        await dest.writeAsBytes(bytes, flush: true);
      } on TranscriptionModelMissingException {
        rethrow;
      } catch (e) {
        throw TranscriptionModelMissingException(
          'Whisper model not found in assets ($assetModelPath): $e',
        );
      }
    }

    if (!await dest.exists() || await dest.length() < 1024) {
      throw TranscriptionModelMissingException(
        'Whisper model missing at $destPath',
      );
    }

    _resolvedModelPath = destPath;
    _modelReady = true;
    return destPath;
  }

  @override
  Future<String> transcribe({
    required String audioPath,
    required String locale,
    void Function(TranscriptionStatus status)? onStatus,
  }) async {
    final previous = this.onStatus;
    if (onStatus != null) this.onStatus = onStatus;

    final jobId = ++_jobId;
    _activeJobId = jobId;

    String? tempWavPath;
    try {
      _throwIfCancelled(jobId);

      final modelPath = await ensureModelInitialized();
      _throwIfCancelled(jobId);

      final original = File(audioPath);
      if (!await original.exists() || await original.length() <= 0) {
        throw TranscriptionFailedException('Audio file missing: $audioPath');
      }

      _emit(const TranscriptionStatus(phase: TranscriptionPhase.converting));

      // whisper_ggml converts non-WAV via FFmpeg to `$path.wav`.
      tempWavPath = '$audioPath.wav';

      _emit(const TranscriptionStatus(
        phase: TranscriptionPhase.transcribing,
        percent: 0,
      ));

      final lang = whisperLanguageCode(locale);
      final whisper = Whisper(model: WhisperModel.tiny);

      final response = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: lang,
          isTranslate: false,
          isNoTimestamps: true,
          noContext: true,
          suppressNonSpeechTokens: true,
          keepModelLoaded: false,
        ),
        modelPath: modelPath,
        onProgress: (percent) {
          if (jobId != _jobId) return;
          _emit(TranscriptionStatus(
            phase: TranscriptionPhase.transcribing,
            percent: percent.clamp(0, 100),
          ));
        },
      );

      _throwIfCancelled(jobId);

      final text = response.text.trim();
      if (text.isEmpty) {
        throw TranscriptionFailedException('Empty transcription result');
      }

      _emit(const TranscriptionStatus(
        phase: TranscriptionPhase.completing,
        percent: 100,
      ));
      _emit(const TranscriptionStatus(
        phase: TranscriptionPhase.completed,
        percent: 100,
      ));
      return text;
    } on TranscriptionCancelledException {
      _emit(const TranscriptionStatus(phase: TranscriptionPhase.cancelled));
      rethrow;
    } on TranscriptionModelMissingException {
      _emit(const TranscriptionStatus(
        phase: TranscriptionPhase.failed,
        message: 'model_missing',
      ));
      rethrow;
    } catch (e) {
      if (e is TranscriptionCancelledException) rethrow;
      debugPrint('LocalWhisper transcription failed (audio preserved): $e');
      _emit(TranscriptionStatus(
        phase: TranscriptionPhase.failed,
        message: e.toString(),
      ));
      if (e is TranscriptionFailedException) rethrow;
      throw TranscriptionFailedException(e.toString());
    } finally {
      if (_activeJobId == jobId) {
        _activeJobId = null;
      }
      await _deleteTempWav(tempWavPath, originalAudioPath: audioPath);
      if (onStatus != null) this.onStatus = previous;
    }
  }

  /// Map app locale tags to whisper.cpp language codes.
  static String whisperLanguageCode(String locale) {
    final tag = TranscriptionLocale.resolve(locale);
    switch (tag) {
      case TranscriptionLocale.en:
        return 'en';
      case TranscriptionLocale.zhTw:
      case TranscriptionLocale.zhCn:
        return 'zh';
      default:
        return tag.length >= 2 ? tag.substring(0, 2) : 'zh';
    }
  }

  void _throwIfCancelled(int jobId) {
    if (jobId != _jobId) {
      throw TranscriptionCancelledException();
    }
  }

  void _emit(TranscriptionStatus status) {
    onStatus?.call(status);
  }

  Future<void> _deleteTempWav(
    String? tempWavPath, {
    required String originalAudioPath,
  }) async {
    if (tempWavPath == null || tempWavPath.isEmpty) return;
    final normTemp = tempWavPath.replaceAll('\\', '/');
    final normOrig = originalAudioPath.replaceAll('\\', '/');
    if (normTemp == normOrig) return;
    if (!normTemp.endsWith('.wav')) return;
    try {
      final f = File(tempWavPath);
      if (await f.exists()) {
        await f.delete();
        debugPrint('Deleted temp wav: $tempWavPath');
      }
    } catch (e) {
      debugPrint('Temp wav cleanup failed (original kept): $e');
    }
  }
}
