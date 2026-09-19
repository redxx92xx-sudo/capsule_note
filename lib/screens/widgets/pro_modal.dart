import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../services/ad_service.dart';
import '../../services/monetization_provider.dart';
import '../../theme/app_theme_capsule.dart';

class ProModal extends StatelessWidget {
  const ProModal({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const ProModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<MonetizationProvider>(
      builder: (context, mon, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.proUpgradeTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.proSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.quotaRemaining(mon.remainingDailyQuota),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.nightText : AppTheme.inkBlue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(context, Icons.block, l10n.proFeature1),
              _buildFeatureItem(context, Icons.auto_awesome, l10n.proFeature2),
              _buildFeatureItem(context, Icons.file_download_outlined, l10n.proFeature3),
              const SizedBox(height: 20),
              // 看廣告領取額度按鈕
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.video_library_outlined, size: 18),
                  label: Text(l10n.unlockRewardAd),
                  onPressed: () {
                    AdService.instance.showRewardedAd(
                      onUserEarnedReward: (reward) {
                        mon.addRewardQuota(3);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.rewardSuccess)),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // PRO 購買/切換按鈕
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    mon.setProStatus(!mon.isPro);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(mon.isPro ? 'PRO 模式已啟用！' : '已切換為免費模式')),
                    );
                  },
                  child: Text(
                    mon.isPro ? '已是 PRO 用戶 (點擊切換測試)' : l10n.upgradeToProButton,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  mon.setProStatus(true);
                  Navigator.pop(context);
                },
                child: Text(l10n.restorePurchases, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
