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
  String get dailyDigest => 'デイリーダイジェスト';

  @override
  String get dailyDigestTitle => '今日のエスピレーション夕刊';

  @override
  String get digestEmptyTitle => '本日記録されたカプセルはありません';

  @override
  String get digestEmptySubtitle => '音声を記録すると、デイリーダイジェストが自動生成されます';

  @override
  String get keySummariesHeader => '主な要約';

  @override
  String get pendingActionItemsHeader => 'アクションアイテム一覧';

  @override
  String get tagDistributionHeader => 'タグ分布';

  @override
  String get copyDigestMarkdown => 'ダイジェストをMarkdownでコピー';

  @override
  String get export => 'エクスポート';

  @override
  String get exportCapsule => 'カプセルをエクスポート';

  @override
  String get exportDigest => 'ダイジェストをエクスポート';

  @override
  String get exportFormat => 'エクスポート形式';

  @override
  String get formatMarkdown => 'Markdown (.md)';

  @override
  String get formatPlainText => 'プレーンテキスト (.txt)';

  @override
  String get formatNotion => 'Notion 互換形式';

  @override
  String get watchAdToUnlockExport => '広告を視聴してエクスポートを解除';

  @override
  String get exportSuccess => 'クリップボードにエクスポートしました！';

  @override
  String get speechCleanerActive => '音声クリーナー適用済み';

  @override
  String todayStats(int count) {
    return '本日：$count件';
  }
}
