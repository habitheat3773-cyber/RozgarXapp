import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/app_logger.dart';

class AdMobService {
  static bool _initialized = false;
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  static AppOpenAd? _appOpenAd;
  static NativeAd? _nativeAd;

  // ─── Ad Unit IDs ──────────────────────────────────────────────────────────
  // 🔴 REPLACE WITH REAL IDS BEFORE RELEASE
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS)     return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    return '';
  }
  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS)     return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    return '';
  }
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS)     return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    return '';
  }
  static String get _appOpenAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS)     return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    return '';
  }
  static String get _nativeAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    if (Platform.isIOS)     return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
    return '';
  }

  // ─── Test IDs (for development) ──────────────────────────────────────────
  static String get _testBannerAdUnitId =>
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
  static String get _testInterstitialAdUnitId =>
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
  static String get _testRewardedAdUnitId =>
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';

  static bool _isDebug = true; // Set false for production

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _initialized = true;
    AppLogger.info('[AdMob] Initialized');
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadAppOpenAd();
  }

  // ─── Banner Ad ────────────────────────────────────────────────────────────
  static Future<BannerAd?> loadBannerAd({
    AdSize size = AdSize.banner,
  }) async {
    if (!_initialized) return null;
    final ad = BannerAd(
      adUnitId: _isDebug ? _testBannerAdUnitId : _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => AppLogger.info('[AdMob] Banner loaded'),
        onAdFailedToLoad: (_, err) => AppLogger.error('[AdMob] Banner failed: $err'),
      ),
    );
    await ad.load();
    return ad;
  }

  // ─── Interstitial Ad ──────────────────────────────────────────────────────
  static void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _isDebug ? _testInterstitialAdUnitId : _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          AppLogger.info('[AdMob] Interstitial loaded');
        },
        onAdFailedToLoad: (err) {
          AppLogger.error('[AdMob] Interstitial failed: $err');
          Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
        },
      ),
    );
  }

  static Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) return false;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (_, err) {
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );
    await _interstitialAd!.show();
    return true;
  }

  // ─── Rewarded Ad ──────────────────────────────────────────────────────────
  static void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _isDebug ? _testRewardedAdUnitId : _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          AppLogger.info('[AdMob] Rewarded loaded');
        },
        onAdFailedToLoad: (err) {
          AppLogger.error('[AdMob] Rewarded failed: $err');
          Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
        },
      ),
    );
  }

  static Future<bool> showRewardedAd({
    required VoidCallback onReward,
  }) async {
    if (_rewardedAd == null) return false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );
    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) => onReward(),
    );
    return true;
  }

  // ─── App Open Ad ──────────────────────────────────────────────────────────
  static void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          AppLogger.info('[AdMob] AppOpen loaded');
        },
        onAdFailedToLoad: (err) {
          AppLogger.error('[AdMob] AppOpen failed: $err');
        },
      ),
    );
  }

  static Future<void> showAppOpenAd() async {
    if (_appOpenAd == null) return;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        _appOpenAd = null;
      },
    );
    await _appOpenAd!.show();
  }

  // ─── Native Ad ────────────────────────────────────────────────────────────
  static Future<NativeAd?> loadNativeAd({
    required NativeAdListener listener,
  }) async {
    if (!_initialized) return null;
    final ad = NativeAd(
      adUnitId: _isDebug ? 'ca-app-pub-3940256099942544/2247696110' : _nativeAdUnitId,
      request: const AdRequest(),
      listener: listener,
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.transparent,
      ),
    );
    await ad.load();
    return ad;
  }

  static void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    _nativeAd?.dispose();
  }
}

/// Reusable Banner Ad Widget
class BannerAdWidget extends StatefulWidget {
  final AdSize size;
  const BannerAdWidget({super.key, this.size = AdSize.banner});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final ad = await AdMobService.loadBannerAd(size: widget.size);
    if (mounted) setState(() { _ad = ad; _loaded = ad != null; });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
