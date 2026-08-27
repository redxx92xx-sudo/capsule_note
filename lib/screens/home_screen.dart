import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/audio_record_service.dart';
import '../services/speech_cleaner_service.dart';
import '../services/capsule_provider.dart';
import '../services/locale_provider.dart';
import '../services/monetization_provider.dart';
import '../theme/app_theme.dart';
import 'daily_digest_screen.dart';
import 'widgets/capsule_card.dart';
import 'widgets/pro_modal.dart';
import 'widgets/record_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _rippleController;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  String? _recordedAudioPath;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _loadBannerAd(); });
  }

  void _loadBannerAd() {
    final monetization = Provider.of<MonetizationProvider>(context, listen: false);
    if (monetization.isPro) return;

    _bannerAd = AdService.instance.createBannerAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isBannerLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (error) {
        if (mounted) {
          setState(() {
            _isBannerLoaded = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _onRecordStart() async {
    setState(() {
      _isRecording = true;
    });
    _rippleController.repeat();
    _recordedAudioPath = await AudioRecordService.instance.startRecording();
  }

  Future<void> _onRecordEnd() async {
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
    });
    _rippleController.stop();
    _rippleController.reset();

    final path = await AudioRecordService.instance.stopRecording();
    _recordedAudioPath = path ?? _recordedAudioPath;

    _showRecordingCompletedDialog(_recordedAudioPath);
  }

  void _showRecordingCompletedDialog(String? audioPath) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<CapsuleProvider>(context, listen: false);
    final monetization = Provider.of<MonetizationProvider>(context, listen: false);
    final isDark = provider.isDarkMode;

    final hasQuota = monetization.consumeQuota();
    if (!hasQuota) {
      ProModal.show(context);
      return;
    }

    // 口語自動清洗示範預設文字
    const rawDemo = '呃，今天下午要跟產品團隊開會，然後，討論那個語音模型的架構與效能優化。';
    final cleanedDemo = SpeechCleanerService.instance.clean(rawDemo);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final titleController = TextEditingController(text: '語音錄音靈感');
        final transcriptController = TextEditingController(text: cleanedDemo);
        final tagController = TextEditingController(text: '靈感, 工作');

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mic, size: 20, color: AppTheme.inkBlue),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.voiceConversionDone,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.inkBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: AppTheme.inkBlue),
                        const SizedBox(width: 4),
                        Text(
                          l10n.speechCleanedBadge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(
                  labelText: l10n.capsuleTitleLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: transcriptController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: l10n.rawTranscriptLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: l10n.tagsLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkBlack,
                    foregroundColor: AppTheme.paperWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final tags = tagController.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    provider.addCapsule(
                      title: titleController.text.trim(),
                      rawTranscript: transcriptController.text.trim(),
                      tags: tags.isEmpty ? ['靈感'] : tags,
                      audioPath: audioPath,
                    );

                    monetization.onCapsuleCreated();
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    l10n.saveAsNote,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    l10n.switchLanguage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...LocaleProvider.supportedLocales.map((loc) {
                  final isSelected = localeProvider.locale?.languageCode == loc.languageCode;
                  return ListTile(
                    title: Text(localeProvider.getLanguageName(loc.languageCode)),
                    trailing: isSelected ? const Icon(Icons.check, color: AppTheme.inkBlue) : null,
                    onTap: () {
                      localeProvider.setLocale(loc);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final monetization = Provider.of<MonetizationProvider>(context);
    final theme = Theme.of(context);
    final isDark = capsuleProvider.isDarkMode;
    final now = DateTime.now();

    String dateStr;
    try {
      dateStr = DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(now);
    } catch (_) {
      try {
        dateStr = DateFormat('yyyy/MM/dd').format(now);
      } catch (_) {
        dateStr = '//';
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            l10n.appTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              l10n.capsulesPending(capsuleProvider.unprocessedCount),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.nightText : AppTheme.inkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // 今日靈感晚報按鈕
                      IconButton(
                        key: const Key('daily_digest_header_btn'),
                        tooltip: l10n.dailyDigestTitle,
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                        ),
                        icon: const Icon(Icons.auto_stories_outlined, size: 20, color: AppTheme.inkBlue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyDigestScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.proUpgradeTitle,
                        style: IconButton.styleFrom(
                          backgroundColor: monetization.isPro
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                              : (isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight),
                        ),
                        icon: Icon(
                          Icons.workspace_premium,
                          size: 20,
                          color: monetization.isPro ? const Color(0xFFD4AF37) : (isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary),
                        ),
                        onPressed: () => ProModal.show(context),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: '今日靈感晚報',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                        ),
                        icon: const Icon(Icons.auto_stories, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyDigestScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: l10n.switchLanguage,
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                        ),
                        icon: const Icon(Icons.language, size: 20),
                        onPressed: () => _showLanguageSelector(context),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: isDark ? l10n.lightModeToggle : l10n.darkModeToggle,
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                        ),
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 20,
                        ),
                        onPressed: () => capsuleProvider.toggleTheme(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                        ),
                      ),
                      child: TextField(
                        onChanged: (val) => capsuleProvider.setSearchQuery(val),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.tapToRecordHint,
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 16,
                          color: monetization.isPro ? const Color(0xFFD4AF37) : AppTheme.inkBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          monetization.isPro ? l10n.proBadge : '${monetization.remainingDailyQuota}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: monetization.isPro ? const Color(0xFFD4AF37) : AppTheme.inkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (capsuleProvider.allTags.isNotEmpty)
              Container(
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(l10n.filterAll),
                        selected: capsuleProvider.selectedTag == null,
                        onSelected: (_) => capsuleProvider.setSelectedTag(null),
                        backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                        selectedColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                        checkmarkColor: AppTheme.inkBlue,
                        side: BorderSide(
                          color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                        ),
                      ),
                    ),
                    ...capsuleProvider.allTags.map((tag) {
                      final isSelected = capsuleProvider.selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('#$tag'),
                          selected: isSelected,
                          onSelected: (_) {
                            capsuleProvider.setSelectedTag(isSelected ? null : tag);
                          },
                          backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                          selectedColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                          checkmarkColor: AppTheme.inkBlue,
                          side: BorderSide(
                            color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            Expanded(
              child: capsuleProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : capsuleProvider.filteredCapsules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 56,
                                color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.emptyCapsulesTitle,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.emptyCapsulesSubtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: capsuleProvider.filteredCapsules.length,
                          itemBuilder: (context, index) {
                            final capsule = capsuleProvider.filteredCapsules[index];
                            return CapsuleCard(capsule: capsule);
                          },
                        ),
            ),
            if (_isBannerLoaded && _bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RecordButton(
        isRecording: _isRecording,
        rippleController: _rippleController,
        onRecordStart: _onRecordStart,
        onRecordEnd: _onRecordEnd,
      ),
    );
  }
}