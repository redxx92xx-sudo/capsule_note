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
  String get upgradeToProButton => 'Unlock PRO Lifetime (\$1.99)';

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
  String get audioFileMissing => 'Recording file not found. Unable to play.';

  @override
  String get audioOnlySaveHint => 'You can clear the text and save audio only';

  @override
  String get recordingSavedTitle => 'Recording saved';

  @override
  String get recordingSavedSubtitle =>
      'Original audio is saved. Transcription is optional and can be done later.';

  @override
  String get saveRecordingOnly => 'Save recording';

  @override
  String get transcribeLater => 'Transcribe later';

  @override
  String get transcribeToText => 'Transcribe';

  @override
  String get retranscribe => 'Re-transcribe';

  @override
  String get transcribing => 'Transcribing…';

  @override
  String get transcriptionNotConfigured =>
      'Transcription service is not configured';

  @override
  String get transcriptionFailed =>
      'Transcription failed. Please try again later.';

  @override
  String get clearTranscript => 'Clear text';

  @override
  String get audioRecordingDefaultTitle => 'Voice recording';

  @override
  String get noTranscriptYetHint => 'Not transcribed yet';

  @override
  String get transcriptionPreparing => 'Preparing…';

  @override
  String get transcriptionConverting => 'Converting audio…';

  @override
  String transcriptionProgress(int percent) {
    return 'Transcribing $percent%';
  }

  @override
  String get transcriptionCompleted => 'Transcription complete';

  @override
  String get transcriptionCancelled => 'Transcription cancelled';

  @override
  String get cancelTranscription => 'Cancel';

  @override
  String get runLocalSummary => 'Generate local summary';

  @override
  String get transcriptionModelMissing => 'On-device Whisper model not found';

  @override
  String get dailyDigestTitle => 'Daily Digest';

  @override
  String get exportModalTitle => 'Choose Export Format';

  @override
  String get exportSuccess => 'Exported and copied to clipboard!';

  @override
  String get speechCleanedBadge => 'Speech Cleaned';

  @override
  String get navToday => 'Today';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navNotes => 'Notes';

  @override
  String get navTodos => 'Todos';

  @override
  String get todayFocus => 'Today\'s Focus';

  @override
  String get todayTodosTitle => 'Today\'s Todos';

  @override
  String get overdueTodosTitle => 'Overdue';

  @override
  String get todayNotesTitle => 'Today\'s Notes';

  @override
  String get addTodo => 'Add Todo';

  @override
  String get editTodo => 'Edit Todo';

  @override
  String get saveTodo => 'Save Todo';

  @override
  String get todoTitleLabel => 'Todo Title';

  @override
  String get todoTitleRequired => 'Please enter todo title';

  @override
  String get todoDescLabel => 'Description & Notes';

  @override
  String get dueDateLabel => 'Due Date & Time';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get enableReminder => 'Enable Reminder';

  @override
  String get persistentReminder => 'Persistent Reminder Until Done';

  @override
  String get repeatRuleLabel => 'Repeat Rule';

  @override
  String get repeatNone => 'Never';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get filterPending => 'Pending';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get filterOverdue => 'Overdue';

  @override
  String get snooze30m => 'Snooze 30 min';

  @override
  String get snooze1h => 'Snooze 1 hour';

  @override
  String get snooze3h => 'Snooze 3 hours';

  @override
  String get snoozeTomorrow => 'Snooze Tomorrow';

  @override
  String get deleteTodoTitle => 'Delete Todo';

  @override
  String get deleteTodoConfirm =>
      'Are you sure you want to delete this todo item?';

  @override
  String get convertToTodo => 'Convert to Todo';

  @override
  String get convertAllToTodos => 'Convert All to Todos';

  @override
  String get backToToday => 'Back to Today';

  @override
  String get viewMonth => 'Month';

  @override
  String get viewWeek => 'Week';

  @override
  String get viewDay => 'Day';

  @override
  String get settingsTitle => 'Settings & Preferences';

  @override
  String get notificationCheck => 'Check Notification Permissions';
}
