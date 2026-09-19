class CleanResult {
  final String cleanedText;
  final int removedFillersCount;
  final int removedDuplicatesCount;

  const CleanResult({
    required this.cleanedText,
    required this.removedFillersCount,
    required this.removedDuplicatesCount,
  });
}

class SpeechCleanerService {
  static final SpeechCleanerService instance = SpeechCleanerService._internal();
  SpeechCleanerService._internal();

  static final List<String> _chineseFillers = [
    '呃',
    '嗯',
    '那個',
    '就是說',
    '然後',
    '其實',
    '基本上',
    '事實上',
    '對了',
    '總之',
    '老實說',
    '坦白說',
    '阿',
    '啦',
    '吧',
    '呢',
    '呀',
    '唄',
    '那麼'
  ];

  static final List<RegExp> _englishFillerRegexes = [
    RegExp(
        r'\b(uh|um|er|ah|like|you know|basically|actually|literally|so yeah|I mean)\b',
        caseSensitive: false),
  ];

  static final List<String> _japaneseFillers = [
    'えーと',
    'あの',
    'その',
    'なんか',
    'ええ',
    'まあ',
    'っていうか'
  ];

  static final List<String> _koreanFillers = [
    '어',
    '음',
    '그',
    '저',
    '있잖아',
    '그냥',
    '말하자면'
  ];

  String clean(String rawTranscript) {
    return cleanWithStats(rawTranscript).cleanedText;
  }

  CleanResult cleanWithStats(String rawTranscript) {
    if (rawTranscript.trim().isEmpty) {
      return const CleanResult(
        cleanedText: '',
        removedFillersCount: 0,
        removedDuplicatesCount: 0,
      );
    }

    String text = rawTranscript;
    int fillerCount = 0;
    int duplicateCount = 0;

    for (final filler in _chineseFillers) {
      final reg = RegExp(RegExp.escape(filler));
      while (reg.hasMatch(text)) {
        fillerCount++;
        text = text.replaceFirst(reg, '');
      }
    }

    for (final reg in _englishFillerRegexes) {
      final matches = reg.allMatches(text);
      fillerCount += matches.length;
      text = text.replaceAll(reg, '');
    }

    for (final filler in _japaneseFillers) {
      final reg = RegExp(RegExp.escape(filler));
      while (reg.hasMatch(text)) {
        fillerCount++;
        text = text.replaceFirst(reg, '');
      }
    }

    for (final filler in _koreanFillers) {
      final reg = RegExp(RegExp.escape(filler));
      while (reg.hasMatch(text)) {
        fillerCount++;
        text = text.replaceFirst(reg, '');
      }
    }

    final cjkRepeatRegex =
        RegExp(r'([\u4e00-\u9fa5\u3040-\u30ff\uac00-\ud7af]{1,6})\1+');
    while (cjkRepeatRegex.hasMatch(text)) {
      text = text.replaceAllMapped(cjkRepeatRegex, (match) {
        duplicateCount++;
        return match.group(1)!;
      });
    }

    final wordRepeatRegex = RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false);
    while (wordRepeatRegex.hasMatch(text)) {
      text = text.replaceAllMapped(wordRepeatRegex, (match) {
        duplicateCount++;
        return match.group(1)!;
      });
    }

    // Single character long repetitions (e.g. "aaaaa" -> "a")
    final charRepeatRegex = RegExp(r'(.)\1+');
    while (charRepeatRegex.hasMatch(text)) {
      text = text.replaceAllMapped(charRepeatRegex, (match) {
        duplicateCount++;
        return match.group(1)!;
      });
    }

    text = text.replaceAll(RegExp(r'[，,]{2,}'), '，');
    text = text.replaceAll(RegExp(r'[。]{2,}'), '。');
    text = text.replaceAll(RegExp(r'[、]{2,}'), '、');
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ');
    text = text.replaceAll(RegExp(r'^[，,、。\s]+'), '');
    text = text.replaceAll(RegExp(r'[，,、\s]+$'), '');
    text = text.trim();

    return CleanResult(
      cleanedText: text.isEmpty ? rawTranscript.trim() : text,
      removedFillersCount: fillerCount,
      removedDuplicatesCount: duplicateCount,
    );
  }
}
