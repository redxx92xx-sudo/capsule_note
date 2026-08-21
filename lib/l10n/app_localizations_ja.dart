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
}
