import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordService {
  static final AudioRecordService instance = AudioRecordService._internal();
  AudioRecordService._internal();

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
        final dir = await getTemporaryDirectory();
        final audioDir = Directory('${dir.path}/capsule_audio');
        if (!audioDir.existsSync()) {
          audioDir.createSync(recursive: true);
        }
        filePath = '${audioDir.path}/capsule_$timestamp.m4a';
      }

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await recorder.start(config, path: filePath);
      _isRecording = true;
      _currentRecordingPath = filePath;
      debugPrint('Recording started at: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error starting record: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      final path = await recorder.stop();
      _isRecording = false;
      debugPrint('Recording stopped: ${path ?? "null"}');
      return path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('Error stopping record: $e');
      _isRecording = false;
      return null;
    }
  }

  Future<void> playAudio(String path) async {
    try {
      await player.stop();
      if (kIsWeb || path.startsWith('http')) {
        await player.play(UrlSource(path));
      } else {
        await player.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
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
}
