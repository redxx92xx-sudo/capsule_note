// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '膠囊筆記';

  @override
  String capsulesPending(int count) {
    return '$count 則待整理';
  }

  @override
  String get pressToRecord => '長按按鈕記錄靈感便籤';

  @override
  String get recordingListening => '正在聆聽錄音中... 鬆開即完成';

  @override
  String get tapToRecordHint => '請長按按鈕進行語音錄製';

  @override
  String get filterAll => '全部';

  @override
  String get emptyCapsulesTitle => '尚無靈感膠囊';

  @override
  String get emptyCapsulesSubtitle => '長按下方按鈕隨時記錄語音與想法';

  @override
  String get saveAsNote => '儲存為膠囊便籤';

  @override
  String get voiceConversionDone => '語音轉化完成';

  @override
  String get capsuleTitleLabel => '膠囊標題';

  @override
  String get rawTranscriptLabel => '語音轉譯內容';

  @override
  String get tagsLabel => '標籤 (逗號分隔)';

  @override
  String get proUpgradeTitle => '升級至 Capsule PRO';

  @override
  String get proBadge => 'PRO';

  @override
  String get proSubtitle => '解鎖無限 AI 智能摘要與純淨無廣告墨水屏體驗';

  @override
  String get proFeature1 => '100% 極簡純淨無廣告介面';

  @override
  String get proFeature2 => '無限次 AI 語音摘要與行動項目提取';

  @override
  String get proFeature3 => '進階 Markdown 與音訊格式匯出';

  @override
  String get unlockRewardAd => '觀看廣告免費領取 +3 次 AI 額度';

  @override
  String get upgradeToProButton => '立即解鎖 PRO 終身版 (NT)';

  @override
  String get restorePurchases => '恢復購買記錄';

  @override
  String quotaRemaining(int count) {
    return '今日 AI 剩餘額度：$count 次';
  }

  @override
  String get rewardSuccess => '已成功獲得獎勵：+3 次 AI 額度！';

  @override
  String get switchLanguage => '切換語言';

  @override
  String get darkModeToggle => '切換墨黑夜間';

  @override
  String get lightModeToggle => '切換紙質白模式';

  @override
  String get markAsDone => '標記為已整理';

  @override
  String get markAsPending => '標記為未整理';

  @override
  String get copyMarkdownSuccess => '已複製為 Markdown 格式到剪貼簿！';

  @override
  String get capsuleDetailTitle => '便籤詳情';

  @override
  String get deleteCapsuleTitle => '刪除膠囊';

  @override
  String get deleteCapsuleMessage => '確定要永久刪除此靈感便籤嗎？';

  @override
  String get cancel => '取消';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String get addNewAction => '新增行動項目';

  @override
  String get addActionHint => '輸入待辦或執行事項...';

  @override
  String get addAction => '添加';

  @override
  String get noActionItemsHint => '暫無行動項目，點擊右上角「+」新增';

  @override
  String get audioRecordTitle => '語音錄音記錄';
}
