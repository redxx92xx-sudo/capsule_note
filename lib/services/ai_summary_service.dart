import 'speech_cleaner_service.dart';

class AiSummaryResult {
  final String title;
  final String summary;
  final List<String> actionItems;
  final List<String> tags;

  const AiSummaryResult({
    required this.title,
    required this.summary,
    required this.actionItems,
    required this.tags,
  });
}

class AiSummaryService {
  static final AiSummaryService instance = AiSummaryService._internal();
  AiSummaryService._internal();

  Future<AiSummaryResult> structureTranscript(String rawText) async {
    final cleanedText = SpeechCleanerService.instance.clean(rawText);
    if (cleanedText.isEmpty) {
      return const AiSummaryResult(
        title: '未命名靈感膠囊',
        summary: '（空白語音便籤）',
        actionItems: ['點擊編輯添加待辦'],
        tags: ['便籤'],
      );
    }

    // 1. 產生核心摘要
    final summary = _generateSummary(cleanedText);

    // 2. 提取行動項目 (Action Items)
    final actionItems = _extractActionItems(cleanedText);

    // 3. 提煉精簡標題
    final title = _generateTitle(cleanedText, actionItems);

    // 4. 自動產生語義標籤
    final tags = _generateTags(cleanedText);

    return AiSummaryResult(
      title: title,
      summary: summary,
      actionItems: actionItems,
      tags: tags,
    );
  }

  String _generateSummary(String text) {
    if (text.length <= 60) return text;
    final sentences = text
        .split(RegExp(r'[。！？\n\.\!\?]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sentences.isEmpty) return text;
    if (sentences.length == 1) return sentences.first.trim();
    return '。';
  }

  List<String> _extractActionItems(String text) {
    final actionKeywords = [
      '要',
      '記得',
      '去',
      '買',
      '確認',
      '聯絡',
      '討論',
      '完成',
      '準備',
      '測試',
      '提交',
      '寄信',
      '安排',
      '處理',
      '檢查',
      '更新',
      'todo',
      'need to',
      'check',
      'buy',
      'send',
      'call',
      'review'
    ];

    final items = <String>[];
    final clauses = text
        .split(RegExp(r'[，,。！？\n\.\!\?；;]'))
        .where((s) => s.trim().isNotEmpty);

    for (final clause in clauses) {
      final trimmed = clause.trim();
      final hasAction =
          actionKeywords.any((kw) => trimmed.toLowerCase().contains(kw));
      if (hasAction && trimmed.length >= 3 && trimmed.length <= 40) {
        if (!items.contains(trimmed)) {
          items.add(trimmed);
        }
      }
    }

    if (items.isEmpty) {
      if (text.length > 20) {
        items.add('回顧便籤重點內容');
        items.add('確認後續執行細節');
      } else {
        items.add('執行事項：');
      }
    }

    return items.take(4).toList();
  }

  String _generateTitle(String text, List<String> actionItems) {
    if (actionItems.isNotEmpty && actionItems.first.length <= 15) {
      return actionItems.first;
    }
    final firstSentence = text.split(RegExp(r'[，,。！？\n\.\!\?；;]')).first.trim();
    if (firstSentence.length <= 14) {
      return firstSentence.isEmpty ? '靈感便籤' : firstSentence;
    }
    return '...';
  }

  List<String> _generateTags(String text) {
    final lower = text.toLowerCase();
    final tagRules = {
      '工作': [
        '會議',
        '專案',
        '討論',
        '進度',
        '客戶',
        '提交',
        '開發',
        'work',
        'project',
        'meeting'
      ],
      '待辦': ['記得', '要', '買', '寄', 'todo', 'task', 'check'],
      '靈感': ['想法', '思考', '設計', '創新', '點子', 'idea', 'inspiration'],
      '生活': ['回家', '吃飯', '運動', '健康', '買菜', 'life', 'home'],
      '技術': ['api', 'flutter', '代碼', '架構', 'bug', '測試', 'code', 'ui'],
    };

    final matched = <String>[];
    tagRules.forEach((tag, keywords) {
      if (keywords.any((kw) => lower.contains(kw))) {
        matched.add(tag);
      }
    });

    if (matched.isEmpty) {
      matched.add('語音記錄');
    }

    return matched.take(3).toList();
  }
}
