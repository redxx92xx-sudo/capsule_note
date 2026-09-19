import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Capsule Note'**
  String get appTitle;

  /// No description provided for @capsulesPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All Caught Up} =1{1 Pending} other{{count} Pending}}'**
  String capsulesPending(int count);

  /// No description provided for @pressToRecord.
  ///
  /// In en, this message translates to:
  /// **'Hold button to record note'**
  String get pressToRecord;

  /// No description provided for @recordingListening.
  ///
  /// In en, this message translates to:
  /// **'Listening... Release to complete'**
  String get recordingListening;

  /// No description provided for @tapToRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the button to record voice'**
  String get tapToRecordHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @emptyCapsulesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Capsule Notes Yet'**
  String get emptyCapsulesTitle;

  /// No description provided for @emptyCapsulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold the bottom button to capture thoughts anytime'**
  String get emptyCapsulesSubtitle;

  /// No description provided for @saveAsNote.
  ///
  /// In en, this message translates to:
  /// **'Save Capsule Note'**
  String get saveAsNote;

  /// No description provided for @voiceConversionDone.
  ///
  /// In en, this message translates to:
  /// **'Voice Processed'**
  String get voiceConversionDone;

  /// No description provided for @capsuleTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Capsule Title'**
  String get capsuleTitleLabel;

  /// No description provided for @rawTranscriptLabel.
  ///
  /// In en, this message translates to:
  /// **'Raw Transcript'**
  String get rawTranscriptLabel;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get tagsLabel;

  /// No description provided for @proUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Capsule PRO'**
  String get proUpgradeTitle;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// No description provided for @proSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited AI summaries and ad-free experience'**
  String get proSubtitle;

  /// No description provided for @proFeature1.
  ///
  /// In en, this message translates to:
  /// **'100% Ad-Free Clean Ink Interface'**
  String get proFeature1;

  /// No description provided for @proFeature2.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Voice Summaries & Action Items'**
  String get proFeature2;

  /// No description provided for @proFeature3.
  ///
  /// In en, this message translates to:
  /// **'Advanced Markdown & Audio Export'**
  String get proFeature3;

  /// No description provided for @unlockRewardAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad for +3 AI Quotas'**
  String get unlockRewardAd;

  /// No description provided for @upgradeToProButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock PRO Lifetime (\$1.99)'**
  String get upgradeToProButton;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @quotaRemaining.
  ///
  /// In en, this message translates to:
  /// **'Daily AI Quotas: {count}'**
  String quotaRemaining(int count);

  /// No description provided for @rewardSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward earned: +3 AI Quotas added!'**
  String get rewardSuccess;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get switchLanguage;

  /// No description provided for @darkModeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle Dark Mode'**
  String get darkModeToggle;

  /// No description provided for @lightModeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle Light Mode'**
  String get lightModeToggle;

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as organized'**
  String get markAsDone;

  /// No description provided for @markAsPending.
  ///
  /// In en, this message translates to:
  /// **'Mark as pending'**
  String get markAsPending;

  /// No description provided for @copyMarkdownSuccess.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard as Markdown format!'**
  String get copyMarkdownSuccess;

  /// No description provided for @capsuleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Capsule Details'**
  String get capsuleDetailTitle;

  /// No description provided for @deleteCapsuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Capsule'**
  String get deleteCapsuleTitle;

  /// No description provided for @deleteCapsuleMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this capsule note?'**
  String get deleteCapsuleMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDelete;

  /// No description provided for @addNewAction.
  ///
  /// In en, this message translates to:
  /// **'Add Action Item'**
  String get addNewAction;

  /// No description provided for @addActionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter action or task item...'**
  String get addActionHint;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @noActionItemsHint.
  ///
  /// In en, this message translates to:
  /// **'No action items yet. Click + to add one.'**
  String get noActionItemsHint;

  /// No description provided for @audioRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Recording'**
  String get audioRecordTitle;

  /// No description provided for @audioFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Recording file not found. Unable to play.'**
  String get audioFileMissing;

  /// No description provided for @audioOnlySaveHint.
  ///
  /// In en, this message translates to:
  /// **'You can clear the text and save audio only'**
  String get audioOnlySaveHint;

  /// No description provided for @recordingSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get recordingSavedTitle;

  /// No description provided for @recordingSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Original audio is saved. Transcription is optional and can be done later.'**
  String get recordingSavedSubtitle;

  /// No description provided for @saveRecordingOnly.
  ///
  /// In en, this message translates to:
  /// **'Save recording'**
  String get saveRecordingOnly;

  /// No description provided for @transcribeLater.
  ///
  /// In en, this message translates to:
  /// **'Transcribe later'**
  String get transcribeLater;

  /// No description provided for @transcribeToText.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get transcribeToText;

  /// No description provided for @retranscribe.
  ///
  /// In en, this message translates to:
  /// **'Re-transcribe'**
  String get retranscribe;

  /// No description provided for @transcribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get transcribing;

  /// No description provided for @transcriptionNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Transcription service is not configured'**
  String get transcriptionNotConfigured;

  /// No description provided for @transcriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed. Please try again later.'**
  String get transcriptionFailed;

  /// No description provided for @clearTranscript.
  ///
  /// In en, this message translates to:
  /// **'Clear text'**
  String get clearTranscript;

  /// No description provided for @audioRecordingDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice recording'**
  String get audioRecordingDefaultTitle;

  /// No description provided for @noTranscriptYetHint.
  ///
  /// In en, this message translates to:
  /// **'Not transcribed yet'**
  String get noTranscriptYetHint;

  /// No description provided for @transcriptionPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get transcriptionPreparing;

  /// No description provided for @transcriptionConverting.
  ///
  /// In en, this message translates to:
  /// **'Converting audio…'**
  String get transcriptionConverting;

  /// No description provided for @transcriptionProgress.
  ///
  /// In en, this message translates to:
  /// **'Transcribing {percent}%'**
  String transcriptionProgress(int percent);

  /// No description provided for @transcriptionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Transcription complete'**
  String get transcriptionCompleted;

  /// No description provided for @transcriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Transcription cancelled'**
  String get transcriptionCancelled;

  /// No description provided for @cancelTranscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTranscription;

  /// No description provided for @runLocalSummary.
  ///
  /// In en, this message translates to:
  /// **'Generate local summary'**
  String get runLocalSummary;

  /// No description provided for @transcriptionModelMissing.
  ///
  /// In en, this message translates to:
  /// **'On-device Whisper model not found'**
  String get transcriptionModelMissing;

  /// No description provided for @dailyDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Digest'**
  String get dailyDigestTitle;

  /// No description provided for @exportModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Export Format'**
  String get exportModalTitle;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported and copied to clipboard!'**
  String get exportSuccess;

  /// No description provided for @speechCleanedBadge.
  ///
  /// In en, this message translates to:
  /// **'Speech Cleaned'**
  String get speechCleanedBadge;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navTodos.
  ///
  /// In en, this message translates to:
  /// **'Todos'**
  String get navTodos;

  /// No description provided for @todayFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Focus'**
  String get todayFocus;

  /// No description provided for @todayTodosTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Todos'**
  String get todayTodosTitle;

  /// No description provided for @overdueTodosTitle.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTodosTitle;

  /// No description provided for @todayNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Notes'**
  String get todayNotesTitle;

  /// No description provided for @addTodo.
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get addTodo;

  /// No description provided for @editTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit Todo'**
  String get editTodo;

  /// No description provided for @saveTodo.
  ///
  /// In en, this message translates to:
  /// **'Save Todo'**
  String get saveTodo;

  /// No description provided for @todoTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Todo Title'**
  String get todoTitleLabel;

  /// No description provided for @todoTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter todo title'**
  String get todoTitleRequired;

  /// No description provided for @todoDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description & Notes'**
  String get todoDescLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date & Time'**
  String get dueDateLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @enableReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminder'**
  String get enableReminder;

  /// No description provided for @persistentReminder.
  ///
  /// In en, this message translates to:
  /// **'Persistent Reminder Until Done'**
  String get persistentReminder;

  /// No description provided for @repeatRuleLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat Rule'**
  String get repeatRuleLabel;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// No description provided for @snooze30m.
  ///
  /// In en, this message translates to:
  /// **'Snooze 30 min'**
  String get snooze30m;

  /// No description provided for @snooze1h.
  ///
  /// In en, this message translates to:
  /// **'Snooze 1 hour'**
  String get snooze1h;

  /// No description provided for @snooze3h.
  ///
  /// In en, this message translates to:
  /// **'Snooze 3 hours'**
  String get snooze3h;

  /// No description provided for @snoozeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Snooze Tomorrow'**
  String get snoozeTomorrow;

  /// No description provided for @deleteTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Todo'**
  String get deleteTodoTitle;

  /// No description provided for @deleteTodoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this todo item?'**
  String get deleteTodoConfirm;

  /// No description provided for @convertToTodo.
  ///
  /// In en, this message translates to:
  /// **'Convert to Todo'**
  String get convertToTodo;

  /// No description provided for @convertAllToTodos.
  ///
  /// In en, this message translates to:
  /// **'Convert All to Todos'**
  String get convertAllToTodos;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get backToToday;

  /// No description provided for @viewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get viewMonth;

  /// No description provided for @viewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get viewWeek;

  /// No description provided for @viewDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get viewDay;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Preferences'**
  String get settingsTitle;

  /// No description provided for @notificationCheck.
  ///
  /// In en, this message translates to:
  /// **'Check Notification Permissions'**
  String get notificationCheck;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
