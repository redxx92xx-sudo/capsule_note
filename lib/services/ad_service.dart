import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static bool get isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // 官方 AdMob 測試廣告單元 ID
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  Future<void> initialize() async {
    if (!isMobilePlatform) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob SDK Initialized successfully');
    } catch (e) {
      debugPrint('AdMob SDK Initialization failed: ');
    }
  }

  BannerAd? createBannerAd({
    required Function() onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
    AdSize size = AdSize.banner,
  }) {
    if (!isMobilePlatform) return null;

    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('BannerAd loaded: ');
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: ');
          ad.dispose();
          onAdFailedToLoad(error);
        },
      ),
    );

    banner.load();
    return banner;
  }

  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    Function()? onAdFailedToLoad,
  }) {
    if (!isMobilePlatform) {
      onUserEarnedReward(RewardItem(3, 'AI_QUOTA'));
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          ad.show(onUserEarnedReward: (adWithoutView, reward) {
            onUserEarnedReward(reward);
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: ');
          if (onAdFailedToLoad != null) onAdFailedToLoad();
        },
      ),
    );
  }

  void showInterstitialAd({Function()? onAdDismissed}) {
    if (!isMobilePlatform) {
      if (onAdDismissed != null) onAdDismissed();
      return;
    }

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (onAdDismissed != null) onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (onAdDismissed != null) onAdDismissed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: ');
          if (onAdDismissed != null) onAdDismissed();
        },
      ),
    );
  }
}
