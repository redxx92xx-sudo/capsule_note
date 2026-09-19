import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  bool _isRewardedLoaded = false;

  bool get isBannerLoaded => _isBannerLoaded;
  BannerAd? get bannerAd => _bannerAd;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }

  Future<void> initialize() async {
    if (!isSupported) return;
    try {
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 2));
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      debugPrint('AdMob initialize timeout or failed: ');
    }
  }

  BannerAd? createBannerAd({
    required Function() onAdLoaded,
    Function(LoadAdError error)? onAdFailedToLoad,
  }) {
    if (!isSupported) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          debugPrint('BannerAd load failed: ');
          onAdFailedToLoad?.call(error);
        },
      ),
    )..load();
  }

  /// Anchored adaptive banner for top-of-content placement (test unit IDs).
  Future<BannerAd?> createAnchoredAdaptiveBanner({
    required int width,
    required void Function(BannerAd ad) onAdLoaded,
    void Function(LoadAdError error)? onAdFailedToLoad,
  }) async {
    if (!isSupported) return null;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null) return null;

    late final BannerAd banner;
    banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          debugPrint('Adaptive BannerAd load failed: $error');
          onAdFailedToLoad?.call(error);
        },
      ),
    )..load();
    return banner;
  }

  void _loadInterstitialAd() {
    if (!isSupported) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoaded = false;
          debugPrint('InterstitialAd failed: ');
        },
      ),
    );
  }

  void _loadRewardedAd() {
    if (!isSupported) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
        },
        onAdFailedToLoad: (err) {
          _isRewardedLoaded = false;
          debugPrint('RewardedAd failed: ');
        },
      ),
    );
  }

  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    Function()? onAdFailedToLoad,
  }) {
    if (!isSupported) {
      onUserEarnedReward(RewardItem(1, 'mock_reward'));
      return;
    }

    if (_isRewardedLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedLoaded = false;
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _isRewardedLoaded = false;
          _loadRewardedAd();
          onAdFailedToLoad?.call();
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (adWithoutView, reward) {
        onUserEarnedReward(reward);
      });
    } else {
      debugPrint('RewardedAd not loaded yet, triggering fallback reward');
      onUserEarnedReward(RewardItem(1, 'mock_reward'));
      _loadRewardedAd();
    }
  }

  void showInterstitialAd({Function()? onAdDismissed}) {
    if (!isSupported) {
      onAdDismissed?.call();
      return;
    }

    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialLoaded = false;
          _loadInterstitialAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _isInterstitialLoaded = false;
          _loadInterstitialAd();
          onAdDismissed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      onAdDismissed?.call();
      _loadInterstitialAd();
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
