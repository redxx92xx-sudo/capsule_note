import 'package:flutter/foundation.dart';

import 'local_whisper_transcription_service.dart';

/// Pluggable speech-to-text. Swap in on-device Whisper or cloud STT later.
abstract class TranscriptionService {
  Future<String> transcribe({
    required String audioPath,
    required String locale,
    void Function(TranscriptionStatus status)? onStatus,
  });
}

/// Phases surfaced to the Detail UI while a job runs.
enum TranscriptionPhase {
  preparing,
  converting,
  transcribing,
  completing,
  completed,
  failed,
  cancelled,
}

class TranscriptionStatus {
  const TranscriptionStatus({
    required this.phase,
    this.percent,
    this.message,
  });

  final TranscriptionPhase phase;
  final int? percent;
  final String? message;
}

/// Thrown when no real STT provider has been registered.
class TranscriptionNotConfiguredException implements Exception {
  @override
  String toString() => 'TranscriptionNotConfiguredException';
}

/// Thrown when transcription fails for a configured provider.
class TranscriptionFailedException implements Exception {
  TranscriptionFailedException([this.message]);
  final String? message;

  @override
  String toString() =>
      'TranscriptionFailedException${message == null ? '' : ': $message'}';
}

/// Thrown when the user cancels an in-flight transcription.
class TranscriptionCancelledException implements Exception {
  @override
  String toString() => 'TranscriptionCancelledException';
}

/// Thrown when the bundled / local Whisper model file is missing.
class TranscriptionModelMissingException implements Exception {
  TranscriptionModelMissingException([this.message]);
  final String? message;

  @override
  String toString() =>
      'TranscriptionModelMissingException${message == null ? '' : ': $message'}';
}

/// Default: explicitly unconfigured — never fakes a transcript.
class UnconfiguredTranscriptionService implements TranscriptionService {
  const UnconfiguredTranscriptionService();

  @override
  Future<String> transcribe({
    required String audioPath,
    required String locale,
    void Function(TranscriptionStatus status)? onStatus,
  }) async {
    throw TranscriptionNotConfiguredException();
  }
}

/// App-wide transcription entry point (replaceable for tests / future STT).
class TranscriptionServiceLocator {
  TranscriptionServiceLocator._();

  static TranscriptionService instance = LocalWhisperTranscriptionService();

  @visibleForTesting
  static void reset() {
    instance = LocalWhisperTranscriptionService();
  }

  @visibleForTesting
  static void useUnconfigured() {
    instance = const UnconfiguredTranscriptionService();
  }
}

/// Maps [Locale] / Flutter locale tags to STT language codes.
///
/// Supported STT tags for this phase: `zh_TW`, `zh_CN`, `en`.
class TranscriptionLocale {
  TranscriptionLocale._();

  static const String zhTw = 'zh_TW';
  static const String zhCn = 'zh_CN';
  static const String en = 'en';

  /// Resolve a BCP-47 / Flutter [locale] string into an STT locale tag.
  static String resolve(String? localeTag) {
    if (localeTag == null || localeTag.isEmpty) return zhTw;

    final normalized = localeTag.replaceAll('-', '_');
    final lower = normalized.toLowerCase();

    if (lower == 'en' || lower.startsWith('en_')) return en;

    if (lower == 'zh_cn' ||
        lower.startsWith('zh_hans') ||
        lower == 'zh_sg' ||
        lower.contains('_hans')) {
      return zhCn;
    }

    if (lower == 'zh_tw' ||
        lower == 'zh_hk' ||
        lower == 'zh_mo' ||
        lower.startsWith('zh_hant') ||
        lower.contains('_hant') ||
        lower == 'zh') {
      return zhTw;
    }

    if (lower.startsWith('zh')) {
      final parts = normalized.split('_');
      if (parts.length >= 2) {
        final region = parts[1].toUpperCase();
        if (region == 'CN' || region == 'SG') return zhCn;
        if (region == 'TW' || region == 'HK' || region == 'MO') return zhTw;
      }
      return zhTw;
    }

    final lang = normalized.split('_').first;
    return lang.isEmpty ? zhTw : lang;
  }

  static String fromLanguageAndCountry({
    required String languageCode,
    String? countryCode,
    String? scriptCode,
  }) {
    if (languageCode == 'en') return en;
    if (languageCode == 'zh') {
      if (scriptCode == 'Hans' ||
          countryCode == 'CN' ||
          countryCode == 'SG') {
        return zhCn;
      }
      return zhTw;
    }
    return languageCode;
  }
}
