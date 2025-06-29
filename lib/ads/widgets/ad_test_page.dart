import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/ads/service/ad_service.dart';
import 'package:society_management/ads/widgets/ad_widgets.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';

/// Test page to verify AdMob integration
class AdTestPage extends StatefulWidget {
  const AdTestPage({super.key});

  @override
  State<AdTestPage> createState() => _AdTestPageState();
}

class _AdTestPageState extends State<AdTestPage> {
  @override
  void initState() {
    super.initState();
    // Preload ads for testing
    AdService.instance.preloadAds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '🎯 Ad Integration Test',
        showDivider: true,
      ),
      body: AdBannerContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Gap(24),
              _buildBannerAdTest(),
              const Gap(24),
              _buildInterstitialAdTest(),
              const Gap(24),
              _buildRewardedAdTest(),
              const Gap(24),
              _buildNativeAdTest(),
              const Gap(24),
              _buildAdSupportedFeatureTest(),
              const Gap(100), // Space for banner ad
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.8),
            AppColors.primaryPurple.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 AdMob Integration Test',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Gap(8),
          Text(
            'Test all ad types to ensure proper integration',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerAdTest() {
    return _buildTestCard(
      title: '📱 Banner Ad Test',
      description: 'Banner ads appear at the bottom of the screen',
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: const Center(
          child: Text(
            'Banner Ad Space\n(Automatically shown at bottom)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildInterstitialAdTest() {
    return _buildTestCard(
      title: '📺 Interstitial Ad Test',
      description: 'Full-screen ads shown between content',
      child: ElevatedButton.icon(
        onPressed: () {
          AdService.instance.showInterstitialAd(
            onAdClosed: () {
              Utility.toast(message: '✅ Interstitial ad test completed!');
            },
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Show Interstitial Ad'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRewardedAdTest() {
    return _buildTestCard(
      title: '🎁 Rewarded Ad Test',
      description: 'Users watch ads to unlock features',
      child: RewardedAdButton(
        buttonText: 'Watch Ad for Reward',
        icon: Icons.card_giftcard,
        onRewardEarned: () {
          Utility.toast(message: '🎉 Reward earned! Ad test successful!');
        },
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildNativeAdTest() {
    return _buildTestCard(
      title: '📰 Native Ad Test',
      description: 'Ads that blend with your content',
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'Native Ad Space\n(Requires platform-specific setup)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildAdSupportedFeatureTest() {
    return AdSupportedFeature(
      featureName: '✨ Premium Feature Test',
      description: 'Test the ad-supported feature unlock system',
      icon: Icons.star,
      onUnlock: () {
        Utility.toast(message: '🔓 Premium feature unlocked via ad!');
      },
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Gap(16),
          child,
        ],
      ),
    );
  }
}
