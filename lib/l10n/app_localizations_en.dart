// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Capsule Note';

  @override
  String capsulesPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pending',
      one: '1 Pending',
      zero: 'All Caught Up',
    );
    return '$_temp0';
  }

  @override
  String get pressToRecord => 'Hold button to record note';

  @override
  String get recordingListening => 'Listening... Release to complete';

  @override
  String get tapToRecordHint => 'Press and hold the button to record voice';

  @override
  String get filterAll => 'All';

  @override
  String get emptyCapsulesTitle => 'No Capsule Notes Yet';

  @override
  String get emptyCapsulesSubtitle =>
      'Hold the bottom button to capture thoughts anytime';

  @override
  String get saveAsNote => 'Save Capsule Note';

  @override
  String get voiceConversionDone => 'Voice Processed';

  @override
  String get capsuleTitleLabel => 'Capsule Title';

  @override
  String get rawTranscriptLabel => 'Raw Transcript';

  @override
  String get tagsLabel => 'Tags (comma separated)';

  @override
  String get proUpgradeTitle => 'Upgrade to Capsule PRO';

  @override
  String get proBadge => 'PRO';

  @override
  String get proSubtitle =>
      'Unlock unlimited AI summaries and ad-free experience';

  @override
  String get proFeature1 => '100% Ad-Free Clean Ink Interface';

  @override
  String get proFeature2 => 'Unlimited AI Voice Summaries & Action Items';

  @override
  String get proFeature3 => 'Advanced Markdown & Audio Export';

  @override
  String get unlockRewardAd => 'Watch Ad for +3 AI Quotas';

  @override
  String get upgradeToProButton => 'Unlock PRO Lifetime (.99)';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String quotaRemaining(int count) {
    return 'Daily AI Quotas: $count';
  }

  @override
  String get rewardSuccess => 'Reward earned: +3 AI Quotas added!';

  @override
  String get switchLanguage => 'Language';

  @override
  String get darkModeToggle => 'Toggle Dark Mode';

  @override
  String get lightModeToggle => 'Toggle Light Mode';

  @override
  String get markAsDone => 'Mark as organized';

  @override
  String get markAsPending => 'Mark as pending';

  @override
  String get copyMarkdownSuccess => 'Copied to clipboard as Markdown format!';

  @override
  String get capsuleDetailTitle => 'Capsule Details';

  @override
  String get deleteCapsuleTitle => 'Delete Capsule';

  @override
  String get deleteCapsuleMessage =>
      'Are you sure you want to permanently delete this capsule note?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDelete => 'Delete';

  @override
  String get addNewAction => 'Add Action Item';

  @override
  String get addActionHint => 'Enter action or task item...';

  @override
  String get addAction => 'Add';

  @override
  String get noActionItemsHint => 'No action items yet. Click + to add one.';

  @override
  String get audioRecordTitle => 'Voice Recording';

  @override
  String get dailyDigest => 'Daily Digest';

  @override
  String get dailyDigestTitle => 'Daily Inspiration Digest';

  @override
  String get digestEmptyTitle => 'No Capsules Recorded Today';

  @override
  String get digestEmptySubtitle =>
      'Hold the mic button to capture thoughts and generate your daily digest';

  @override
  String get keySummariesHeader => 'Key Summaries';

  @override
  String get pendingActionItemsHeader => 'Action Items To-Do';

  @override
  String get tagDistributionHeader => 'Tag Distribution';

  @override
  String get copyDigestMarkdown => 'Copy Digest (Markdown)';

  @override
  String get export => 'Export';

  @override
  String get exportCapsule => 'Export Capsule';

  @override
  String get exportDigest => 'Export Digest';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get formatMarkdown => 'Markdown (.md)';

  @override
  String get formatPlainText => 'Plain Text (.txt)';

  @override
  String get formatNotion => 'Notion Compatible';

  @override
  String get watchAdToUnlockExport => 'Watch Ad to Unlock Full Export';

  @override
  String get exportSuccess => 'Exported successfully to clipboard!';

  @override
  String get speechCleanerActive => 'Speech Cleaner Active';

  @override
  String todayStats(int count) {
    return 'Today: $count Notes';
  }
}
