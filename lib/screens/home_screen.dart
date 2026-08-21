import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/capsule_provider.dart';
import '../services/locale_provider.dart';
import '../services/monetization_provider.dart';
import '../theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _loadBannerAd();
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

  void _onRecordStart() {
    setState(() {
      _isRecording = true;
    });
    _rippleController.repeat();
  }

  void _onRecordEnd() {
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
    });
    _rippleController.stop();
    _rippleController.reset();

    _showRecordingCompletedDialog();
  }

  void _showRecordingCompletedDialog() {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<CapsuleProvider>(context, listen: false);
    final monetization = Provider.of<MonetizationProvider>(context, listen: false);
    final isDark = provider.isDarkMode;

    final hasQuota = monetization.consumeQuota();
    if (!hasQuota) {
      ProModal.show(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final titleController = TextEditingController(text: '快速語音靈感膠囊');
        final transcriptController = TextEditingController(text: '確認墨水屏調色盤、多國語言切換與 AdMob 商業化變現架構。');
        final tagController = TextEditingController(text: '靈感, PRO');

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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: l10n.capsuleTitleLabel,
                  labelStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: transcriptController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.rawTranscriptLabel,
                  labelStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                decoration: InputDecoration(
                  labelText: l10n.tagsLabel,
                  labelStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF4A6572) : AppTheme.inkBlue,
                    foregroundColor: Colors.white,
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
                      title: titleController.text.trim().isEmpty ? '語音記錄' : titleController.text.trim(),
                      rawTranscript: transcriptController.text.trim(),
                      summary: transcriptController.text.trim(),
                      actionItems: ['確認錄音便籤項目', '檢視行動摘要'],
                      tags: tags.isEmpty ? ['語音'] : tags,
                    );
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

    final dateStr = DateFormat.yMMMEd(Localizations.localeOf(context).toString()).format(now);

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

            if (capsuleProvider.allTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildTagFilterChip(
                        context,
                        label: ' ()',
                        isSelected: capsuleProvider.selectedTag == null,
                        onTap: () => capsuleProvider.setSelectedTag(null),
                      ),
                      ...capsuleProvider.allTags.map(
                        (tag) => _buildTagFilterChip(
                          context,
                          label: tag,
                          isSelected: capsuleProvider.selectedTag == tag,
                          onTap: () => capsuleProvider.setSelectedTag(
                            capsuleProvider.selectedTag == tag ? null : tag,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 10),

            Expanded(
              child: capsuleProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : capsuleProvider.filteredCapsules.isEmpty
                      ? _buildEmptyState(context, l10n)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: capsuleProvider.filteredCapsules.length,
                          itemBuilder: (context, index) {
                            final capsule = capsuleProvider.filteredCapsules[index];
                            return CapsuleCard(capsule: capsule)
                                .animate()
                                .fadeIn(duration: 300.ms, delay: (index * 40).ms)
                                .slideY(begin: 0.05, end: 0, duration: 300.ms);
                          },
                        ),
            ),

            if (!monetization.isPro)
              _buildBannerAdContainer(context),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: monetization.isPro ? 0 : 54),
        child: RecordButton(
          isRecording: _isRecording,
          rippleController: _rippleController,
          onRecordStart: _onRecordStart,
          onRecordEnd: _onRecordEnd,
        ),
      ),
    );
  }

  Widget _buildBannerAdContainer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isBannerLoaded && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return Container(
      width: double.infinity,
      height: 50,
      color: isDark ? AppTheme.nightCard : AppTheme.inkHighlightLight.withValues(alpha: 0.5),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ad_units, size: 14, color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary),
            const SizedBox(width: 6),
            Text(
              'AdMob Banner (PRO removes ads)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF4A6572) : AppTheme.inkBlue)
                : (isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.nightText : AppTheme.inkBlack),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.draw_outlined,
              size: 56,
              color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyCapsulesTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.emptyCapsulesSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
