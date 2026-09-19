// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'カプセルノート';

  @override
  String capsulesPending(int count) {
    return '未整理 $count 件';
  }

  @override
  String get pressToRecord => '長押しで音声メモを記録';

  @override
  String get recordingListening => '録音中... 離すと完了';

  @override
  String get tapToRecordHint => 'ボタンを長押しして録音してください';

  @override
  String get filterAll => 'すべて';

  @override
  String get emptyCapsulesTitle => 'カプセルノートがありません';

  @override
  String get emptyCapsulesSubtitle => '下のボタンを長押ししてアイデアを記録しましょう';

  @override
  String get saveAsNote => 'カプセルを保存';

  @override
  String get voiceConversionDone => '音声変換完了';

  @override
  String get capsuleTitleLabel => 'タイトル';

  @override
  String get rawTranscriptLabel => '音声テキスト';

  @override
  String get tagsLabel => 'タグ (カンマ区切り)';

  @override
  String get proUpgradeTitle => 'Capsule PRO にアップグレード';

  @override
  String get proBadge => 'PRO';

  @override
  String get proSubtitle => '無制限のAI要約と完全広告非表示を解放';

  @override
  String get proFeature1 => '完全広告非表示のミニマルなE-ink体験';

  @override
  String get proFeature2 => '無制限のAI音声要約とアクションプラン抽出';

  @override
  String get proFeature3 => '高度なMarkdownおよび音声データエクスポート';

  @override
  String get unlockRewardAd => '広告を見てAI枠を+3回追加';

  @override
  String get upgradeToProButton => 'PRO 永久版を購入 (¥600)';

  @override
  String get restorePurchases => '購入を復元';

  @override
  String quotaRemaining(int count) {
    return '本日のAI利用枠: $count 回';
  }

  @override
  String get rewardSuccess => 'ボーナス獲得: AI利用枠が+3回追加されました！';

  @override
  String get switchLanguage => '言語切り替え';

  @override
  String get darkModeToggle => 'ダークモードに切り替え';

  @override
  String get lightModeToggle => 'ライトモードに切り替え';

  @override
  String get markAsDone => '整理済みにする';

  @override
  String get markAsPending => '未整理にする';

  @override
  String get copyMarkdownSuccess => 'Markdown形式でクリップボードにコピーしました！';

  @override
  String get capsuleDetailTitle => 'カプセル詳細';

  @override
  String get deleteCapsuleTitle => 'カプセルを削除';

  @override
  String get deleteCapsuleMessage => 'このカプセルノートを完全に削除してもよろしいですか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirmDelete => '削除する';

  @override
  String get addNewAction => 'アクション項目を追加';

  @override
  String get addActionHint => 'タスクまたはアクションを入力...';

  @override
  String get addAction => '追加';

  @override
  String get noActionItemsHint => 'アクション項目がありません。+ をクリックして追加してください。';

  @override
  String get audioRecordTitle => '音声録音データ';

  @override
  String get audioFileMissing => '録音ファイルが見つからないため再生できません';

  @override
  String get audioOnlySaveHint => '文字を空にして録音のみ保存できます';

  @override
  String get recordingSavedTitle => '録音が完了しました';

  @override
  String get recordingSavedSubtitle => '元の録音を保存しました。文字起こしは後から実行できます。';

  @override
  String get saveRecordingOnly => '録音を保存';

  @override
  String get transcribeLater => '後で文字起こし';

  @override
  String get transcribeToText => '文字に変換';

  @override
  String get retranscribe => '再文字起こし';

  @override
  String get transcribing => '文字起こし中…';

  @override
  String get transcriptionNotConfigured => '文字起こしサービスが未設定です';

  @override
  String get transcriptionFailed => '文字起こしに失敗しました。後でもう一度お試しください。';

  @override
  String get clearTranscript => '文字をクリア';

  @override
  String get audioRecordingDefaultTitle => '音声録音メモ';

  @override
  String get noTranscriptYetHint => 'まだ文字起こしされていません';

  @override
  String get transcriptionPreparing => '準備中…';

  @override
  String get transcriptionConverting => '音声を変換中…';

  @override
  String transcriptionProgress(int percent) {
    return '文字起こし中 $percent%';
  }

  @override
  String get transcriptionCompleted => '文字起こし完了';

  @override
  String get transcriptionCancelled => '文字起こしをキャンセルしました';

  @override
  String get cancelTranscription => 'キャンセル';

  @override
  String get runLocalSummary => 'ローカル要約を生成';

  @override
  String get transcriptionModelMissing => '端末内 Whisper モデルが見つかりません';

  @override
  String get dailyDigestTitle => '今日の日報';

  @override
  String get exportModalTitle => 'エクスポート形式を選択';

  @override
  String get exportSuccess => 'クリップボードにコピーしました！';

  @override
  String get speechCleanedBadge => 'クリーン済み';

  @override
  String get navToday => '今日';

  @override
  String get navCalendar => 'カレンダー';

  @override
  String get navNotes => 'メモ';

  @override
  String get navTodos => 'タスク';

  @override
  String get todayFocus => '今日のフォーカス';

  @override
  String get todayTodosTitle => '今日のタスク';

  @override
  String get overdueTodosTitle => '期限切れ';

  @override
  String get todayNotesTitle => '今日のメモ';

  @override
  String get addTodo => 'タスクを追加';

  @override
  String get editTodo => 'タスクを編集';

  @override
  String get saveTodo => '保存';

  @override
  String get todoTitleLabel => 'タスク名';

  @override
  String get todoTitleRequired => 'タスク名を入力してください';

  @override
  String get todoDescLabel => '詳細とメモ';

  @override
  String get dueDateLabel => '予定日時';

  @override
  String get priorityLabel => '優先度';

  @override
  String get priorityLow => '低';

  @override
  String get priorityMedium => '中';

  @override
  String get priorityHigh => '高';

  @override
  String get priorityUrgent => '緊急';

  @override
  String get enableReminder => '通知を有効にする';

  @override
  String get persistentReminder => '完了するまで通知を継続';

  @override
  String get repeatRuleLabel => '繰り返し';

  @override
  String get repeatNone => '繰り返さない';

  @override
  String get repeatDaily => '毎日';

  @override
  String get repeatWeekly => '毎週';

  @override
  String get repeatMonthly => '毎月';

  @override
  String get filterPending => '未完了';

  @override
  String get filterCompleted => '完了済み';

  @override
  String get filterOverdue => '期限切れ';

  @override
  String get snooze30m => '30分後に通知';

  @override
  String get snooze1h => '1時間後に通知';

  @override
  String get snooze3h => '3時間後に通知';

  @override
  String get snoozeTomorrow => '明日通知';

  @override
  String get deleteTodoTitle => 'タスクを削除';

  @override
  String get deleteTodoConfirm => 'このタスクを削除してもよろしいですか？';

  @override
  String get convertToTodo => 'タスクに変換';

  @override
  String get convertAllToTodos => 'すべてタスクに変換';

  @override
  String get backToToday => '今日へ戻る';

  @override
  String get viewMonth => '月';

  @override
  String get viewWeek => '週';

  @override
  String get viewDay => '日';

  @override
  String get settingsTitle => '設定と環境設定';

  @override
  String get notificationCheck => '通知とアラームの権限を確認';
}
