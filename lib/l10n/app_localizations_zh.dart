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
  String get upgradeToProButton => '立即解鎖 PRO 終身版 (NT\$60)';

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

  @override
  String get audioFileMissing => '找不到錄音檔，無法播放';

  @override
  String get audioOnlySaveHint => '可清空文字，僅保存錄音記事';

  @override
  String get recordingSavedTitle => '錄音已完成';

  @override
  String get recordingSavedSubtitle => '已保存原始錄音。轉文字為選用，可稍後再執行。';

  @override
  String get saveRecordingOnly => '保存錄音';

  @override
  String get transcribeLater => '稍後轉文字';

  @override
  String get transcribeToText => '轉成文字';

  @override
  String get retranscribe => '重新轉寫';

  @override
  String get transcribing => '轉寫中…';

  @override
  String get transcriptionNotConfigured => '尚未設定轉文字服務';

  @override
  String get transcriptionFailed => '轉寫失敗，請稍後再試';

  @override
  String get clearTranscript => '清除文字';

  @override
  String get audioRecordingDefaultTitle => '語音錄音記事';

  @override
  String get noTranscriptYetHint => '尚未轉成文字';

  @override
  String get transcriptionPreparing => '準備中…';

  @override
  String get transcriptionConverting => '轉換音檔中…';

  @override
  String transcriptionProgress(int percent) {
    return '轉寫中 $percent%';
  }

  @override
  String get transcriptionCompleted => '轉寫完成';

  @override
  String get transcriptionCancelled => '已取消轉寫';

  @override
  String get cancelTranscription => '取消轉寫';

  @override
  String get runLocalSummary => '產生本機摘要';

  @override
  String get transcriptionModelMissing => '找不到本機 Whisper 模型，無法轉文字';

  @override
  String get dailyDigestTitle => '今日靈感晚報';

  @override
  String get exportModalTitle => '選擇匯出格式';

  @override
  String get exportSuccess => '已成功解鎖並複製到剪貼簿！';

  @override
  String get speechCleanedBadge => '已口語清洗';

  @override
  String get navToday => '今天';

  @override
  String get navCalendar => '月曆';

  @override
  String get navNotes => '記事';

  @override
  String get navTodos => '待辦';

  @override
  String get todayFocus => '今日焦點';

  @override
  String get todayTodosTitle => '今日待辦';

  @override
  String get overdueTodosTitle => '已逾期';

  @override
  String get todayNotesTitle => '今日筆記';

  @override
  String get addTodo => '新增待辦';

  @override
  String get editTodo => '編輯待辦';

  @override
  String get saveTodo => '儲存待辦';

  @override
  String get todoTitleLabel => '待辦標題';

  @override
  String get todoTitleRequired => '請輸入待辦標題';

  @override
  String get todoDescLabel => '詳細內容與備註';

  @override
  String get dueDateLabel => '預定日期與時間';

  @override
  String get priorityLabel => '優先級別';

  @override
  String get priorityLow => '低';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityHigh => '高';

  @override
  String get priorityUrgent => '緊急';

  @override
  String get enableReminder => '啟用本機提醒通知';

  @override
  String get persistentReminder => '持續提醒直到完成';

  @override
  String get repeatRuleLabel => '重複週期';

  @override
  String get repeatNone => '不重複';

  @override
  String get repeatDaily => '每天重複';

  @override
  String get repeatWeekly => '每週重複';

  @override
  String get repeatMonthly => '每月重複';

  @override
  String get filterPending => '未完成';

  @override
  String get filterCompleted => '已完成';

  @override
  String get filterOverdue => '已逾期';

  @override
  String get snooze30m => '稍後 30 分鐘';

  @override
  String get snooze1h => '稍後 1 小時';

  @override
  String get snooze3h => '稍後 3 小時';

  @override
  String get snoozeTomorrow => '稍後提醒：明天';

  @override
  String get deleteTodoTitle => '刪除待辦';

  @override
  String get deleteTodoConfirm => '確定要刪除此待辦事項嗎？';

  @override
  String get convertToTodo => '轉為待辦';

  @override
  String get convertAllToTodos => '全轉待辦';

  @override
  String get backToToday => '回到今天';

  @override
  String get viewMonth => '月';

  @override
  String get viewWeek => '週';

  @override
  String get viewDay => '日';

  @override
  String get settingsTitle => '設定與喜好';

  @override
  String get notificationCheck => '通知與鬧鐘權限檢查';
}
