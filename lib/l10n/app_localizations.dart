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
    Locale('zh'),
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
  /// **'Unlock PRO Lifetime (.99)'**
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

  /// No description provided for @dailyDigest.
  ///
  /// In en, this message translates to:
  /// **'Daily Digest'**
  String get dailyDigest;

  /// No description provided for @dailyDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Inspiration Digest'**
  String get dailyDigestTitle;

  /// No description provided for @digestEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Capsules Recorded Today'**
  String get digestEmptyTitle;

  /// No description provided for @digestEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hold the mic button to capture thoughts and generate your daily digest'**
  String get digestEmptySubtitle;

  /// No description provided for @keySummariesHeader.
  ///
  /// In en, this message translates to:
  /// **'Key Summaries'**
  String get keySummariesHeader;

  /// No description provided for @pendingActionItemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Action Items To-Do'**
  String get pendingActionItemsHeader;

  /// No description provided for @tagDistributionHeader.
  ///
  /// In en, this message translates to:
  /// **'Tag Distribution'**
  String get tagDistributionHeader;

  /// No description provided for @copyDigestMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Copy Digest (Markdown)'**
  String get copyDigestMarkdown;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportCapsule.
  ///
  /// In en, this message translates to:
  /// **'Export Capsule'**
  String get exportCapsule;

  /// No description provided for @exportDigest.
  ///
  /// In en, this message translates to:
  /// **'Export Digest'**
  String get exportDigest;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @formatMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown (.md)'**
  String get formatMarkdown;

  /// No description provided for @formatPlainText.
  ///
  /// In en, this message translates to:
  /// **'Plain Text (.txt)'**
  String get formatPlainText;

  /// No description provided for @formatNotion.
  ///
  /// In en, this message translates to:
  /// **'Notion Compatible'**
  String get formatNotion;

  /// No description provided for @watchAdToUnlockExport.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad to Unlock Full Export'**
  String get watchAdToUnlockExport;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully to clipboard!'**
  String get exportSuccess;

  /// No description provided for @speechCleanerActive.
  ///
  /// In en, this message translates to:
  /// **'Speech Cleaner Active'**
  String get speechCleanerActive;

  /// No description provided for @todayStats.
  ///
  /// In en, this message translates to:
  /// **'Today: {count} Notes'**
  String todayStats(int count);
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
    'that was used.',
  );
}
