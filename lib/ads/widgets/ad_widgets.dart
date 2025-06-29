import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:society_management/ads/service/ad_service.dart';
import 'package:society_management/constants/app_colors.dart';

/// Banner Ad Widget for bottom of screens
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.instance.createBannerAd();
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null || !AdService.instance.isBannerAdLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// Native Ad Widget for content feeds
class NativeAdWidget extends StatefulWidget {
  final String factoryId;
  
  const NativeAdWidget({
    super.key,
    this.factoryId = 'listTile',
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-3940256099942544/2247696110', // Test native ad
      factoryId: widget.factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 100,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

/// Rewarded Ad Button Widget
class RewardedAdButton extends StatefulWidget {
  final String buttonText;
  final IconData icon;
  final VoidCallback onRewardEarned;
  final VoidCallback? onAdClosed;
  final Color? backgroundColor;

  const RewardedAdButton({
    super.key,
    required this.buttonText,
    required this.icon,
    required this.onRewardEarned,
    this.onAdClosed,
    this.backgroundColor,
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preload rewarded ad
    AdService.instance.loadRewardedAd();
  }

  void _showRewardedAd() async {
    setState(() => _isLoading = true);

    if (!AdService.instance.isRewardedAdLoaded) {
      await AdService.instance.loadRewardedAd();
    }

    AdService.instance.showRewardedAd(
      onUserEarnedReward: () {
        widget.onRewardEarned();
        setState(() => _isLoading = false);
      },
      onAdClosed: () {
        widget.onAdClosed?.call();
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _showRewardedAd,
      icon: _isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
      label: Text(widget.buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor ?? AppColors.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Ad Banner Container with close option
class AdBannerContainer extends StatefulWidget {
  final Widget child;
  final bool showAd;

  const AdBannerContainer({
    super.key,
    required this.child,
    this.showAd = true,
  });

  @override
  State<AdBannerContainer> createState() => _AdBannerContainerState();
}

class _AdBannerContainerState extends State<AdBannerContainer> {
  bool _showAd = true;

  @override
  void initState() {
    super.initState();
    _showAd = widget.showAd;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        if (_showAd) ...[
          Container(
            color: Colors.grey[100],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'Ad',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showAd = false),
                      icon: const Icon(Icons.close, size: 16),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
                const BannerAdWidget(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Interstitial Ad Helper
class InterstitialAdHelper {
  static int _actionCount = 0;
  static const int _adFrequency = 3; // Show ad every 3 actions

  static void incrementActionCount() {
    _actionCount++;
  }

  static bool shouldShowAd() {
    return _actionCount >= _adFrequency;
  }

  static void showAdIfNeeded({VoidCallback? onAdClosed}) {
    if (shouldShowAd()) {
      _actionCount = 0; // Reset counter
      AdService.instance.showInterstitialAd(onAdClosed: onAdClosed);
    } else {
      onAdClosed?.call();
    }
  }

  static void resetCounter() {
    _actionCount = 0;
  }
}

/// Ad-supported feature unlock widget
class AdSupportedFeature extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;
  final VoidCallback onUnlock;
  final bool isUnlocked;

  const AdSupportedFeature({
    super.key,
    required this.featureName,
    required this.description,
    required this.icon,
    required this.onUnlock,
    this.isUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.1),
            AppColors.primaryPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      featureName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isUnlocked)
            RewardedAdButton(
              buttonText: 'Watch Ad to Unlock',
              icon: Icons.play_circle_outline,
              onRewardEarned: onUnlock,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Unlocked!',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
