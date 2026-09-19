import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import '../services/monetization_provider.dart';

/// Places an anchored adaptive Banner between the status bar and [appBar].
///
/// Layout:
///   SafeArea(top) → Banner (4–8dp gap) → AppBar → body → bottomNavigationBar
///
/// Hide when [showBanner] is false (settings, recording, transcription, etc.).
class TopBannerScaffold extends StatefulWidget {
  const TopBannerScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showBanner = true,
    this.backgroundColor,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showBanner;
  final Color? backgroundColor;

  @override
  State<TopBannerScaffold> createState() => _TopBannerScaffoldState();
}

class _TopBannerScaffoldState extends State<TopBannerScaffold> {
  BannerAd? _banner;
  bool _loaded = false;
  double _bannerHeight = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadBanner();
  }

  @override
  void didUpdateWidget(covariant TopBannerScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBanner && !widget.showBanner) {
      _disposeBanner();
    } else if (!oldWidget.showBanner && widget.showBanner) {
      _maybeLoadBanner();
    }
  }

  Future<void> _maybeLoadBanner() async {
    if (!widget.showBanner || kIsWeb) return;
    if (!AdService.instance.isSupported) return;

    final mon = Provider.of<MonetizationProvider>(context, listen: false);
    if (mon.isPro) {
      _disposeBanner();
      return;
    }
    if (_banner != null) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final ad = await AdService.instance.createAnchoredAdaptiveBanner(
      width: width,
      onAdLoaded: (BannerAd ad) {
        if (!mounted) {
          ad.dispose();
          return;
        }
        setState(() {
          _banner = ad;
          _loaded = true;
          _bannerHeight = ad.size.height.toDouble();
        });
      },
      onAdFailedToLoad: (_) {
        if (!mounted) return;
        setState(() {
          _loaded = false;
          _bannerHeight = 0;
          _banner = null;
        });
      },
    );
    if (ad == null && mounted) {
      setState(() {
        _loaded = false;
        _bannerHeight = 0;
      });
    }
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    if (mounted) {
      setState(() {
        _loaded = false;
        _bannerHeight = 0;
      });
    } else {
      _loaded = false;
      _bannerHeight = 0;
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mon = context.watch<MonetizationProvider>();
    final show = widget.showBanner &&
        !mon.isPro &&
        _loaded &&
        _banner != null &&
        !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS);

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: show
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SizedBox(
                      width: _banner!.size.width.toDouble(),
                      height: _bannerHeight,
                      child: AdWidget(ad: _banner!),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (widget.appBar != null)
            SizedBox(
              height: widget.appBar!.preferredSize.height,
              child: widget.appBar,
            ),
          Expanded(child: widget.body),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
