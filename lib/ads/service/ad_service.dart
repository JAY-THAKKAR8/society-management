import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for managing Google AdMob advertisements
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();

  // Test Ad Unit IDs (Replace with your real Ad Unit IDs in production)
  static String get _bannerAdUnitId => kDebugMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Test banner Android
          : 'ca-app-pub-3940256099942544/2934735716') // Test banner iOS
      : (Platform.isAndroid
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_ANDROID' // Your real banner Android
          : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_IOS'); // Your real banner iOS

  static String get _interstitialAdUnitId => kDebugMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Test interstitial Android
          : 'ca-app-pub-3940256099942544/4411468910') // Test interstitial iOS
      : (Platform.isAndroid
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_ANDROID' // Your real interstitial Android
          : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_IOS'); // Your real interstitial iOS

  static String get _rewardedAdUnitId => kDebugMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Test rewarded Android
          : 'ca-app-pub-3940256099942544/1712485313') // Test rewarded iOS
      : (Platform.isAndroid
          ? 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_REWARDED_ANDROID' // Your real rewarded Android
          : 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_REWARDED_IOS'); // Your real rewarded iOS

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Ad loading states
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  // Initialize AdMob
  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      debugPrint('🎯 AdMob initialized successfully');
    } catch (e) {
      debugPrint('🎯 AdMob initialization failed: $e');
      // Continue app execution even if AdMob fails to initialize
    }
  }

  // Banner Ad Methods
  BannerAd createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          debugPrint('🎯 Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          debugPrint('🎯 Banner ad failed to load: $error');
        },
        onAdOpened: (ad) => debugPrint('🎯 Banner ad opened'),
        onAdClosed: (ad) => debugPrint('🎯 Banner ad closed'),
      ),
    );
    return _bannerAd!;
  }

  bool get isBannerAdLoaded => _isBannerAdLoaded;

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // Interstitial Ad Methods
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          debugPrint('🎯 Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          debugPrint('🎯 Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          onAdClosed?.call();
          // Preload next interstitial ad
          loadInterstitialAd();
          debugPrint('🎯 Interstitial ad dismissed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          debugPrint('🎯 Interstitial ad failed to show: $error');
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint('🎯 Interstitial ad not ready');
      onAdClosed?.call(); // Still call callback even if ad not shown
    }
  }

  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  // Rewarded Ad Methods
  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          debugPrint('🎯 Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          debugPrint('🎯 Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          onAdClosed?.call();
          // Preload next rewarded ad
          loadRewardedAd();
          debugPrint('🎯 Rewarded ad dismissed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          debugPrint('🎯 Rewarded ad failed to show: $error');
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward();
          debugPrint('🎯 User earned reward: ${reward.amount} ${reward.type}');
        },
      );
    } else {
      debugPrint('🎯 Rewarded ad not ready');
      onAdClosed?.call(); // Still call callback even if ad not shown
    }
  }

  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  // Preload ads for better user experience
  Future<void> preloadAds() async {
    await Future.wait([
      loadInterstitialAd(),
      loadRewardedAd(),
    ]);
  }

  // Dispose all ads
  void disposeAllAds() {
    disposeBannerAd();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialAdLoaded = false;
    _isRewardedAdLoaded = false;
  }
}
