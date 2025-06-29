import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking ad performance and user engagement
class AdAnalyticsService {
  static AdAnalyticsService? _instance;
  static AdAnalyticsService get instance => _instance ??= AdAnalyticsService._();
  AdAnalyticsService._();

  static const String _keyAdImpressions = 'ad_impressions';
  static const String _keyAdClicks = 'ad_clicks';
  static const String _keyRewardedAdsWatched = 'rewarded_ads_watched';
  static const String _keyInterstitialAdsShown = 'interstitial_ads_shown';
  static const String _keyBannerAdsShown = 'banner_ads_shown';
  static const String _keyTotalRevenue = 'total_revenue_estimate';
  static const String _keyLastResetDate = 'last_reset_date';

  // Track ad events
  Future<void> trackBannerAdShown() async {
    await _incrementCounter(_keyBannerAdsShown);
    await _estimateRevenue('banner');
    debugPrint('📊 Banner ad shown - Analytics updated');
  }

  Future<void> trackInterstitialAdShown() async {
    await _incrementCounter(_keyInterstitialAdsShown);
    await _estimateRevenue('interstitial');
    debugPrint('📊 Interstitial ad shown - Analytics updated');
  }

  Future<void> trackRewardedAdWatched() async {
    await _incrementCounter(_keyRewardedAdsWatched);
    await _estimateRevenue('rewarded');
    debugPrint('📊 Rewarded ad watched - Analytics updated');
  }

  Future<void> trackAdClick() async {
    await _incrementCounter(_keyAdClicks);
    debugPrint('📊 Ad clicked - Analytics updated');
  }

  Future<void> trackAdImpression() async {
    await _incrementCounter(_keyAdImpressions);
    debugPrint('📊 Ad impression - Analytics updated');
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'bannerAdsShown': prefs.getInt(_keyBannerAdsShown) ?? 0,
      'interstitialAdsShown': prefs.getInt(_keyInterstitialAdsShown) ?? 0,
      'rewardedAdsWatched': prefs.getInt(_keyRewardedAdsWatched) ?? 0,
      'totalImpressions': prefs.getInt(_keyAdImpressions) ?? 0,
      'totalClicks': prefs.getInt(_keyAdClicks) ?? 0,
      'estimatedRevenue': prefs.getDouble(_keyTotalRevenue) ?? 0.0,
      'lastResetDate': prefs.getString(_keyLastResetDate) ?? 'Never',
    };
  }

  // Revenue estimation (rough estimates)
  Future<void> _estimateRevenue(String adType) async {
    final prefs = await SharedPreferences.getInstance();
    double currentRevenue = prefs.getDouble(_keyTotalRevenue) ?? 0.0;
    
    double adRevenue = 0.0;
    switch (adType) {
      case 'banner':
        adRevenue = 0.01; // $0.01 per banner impression
        break;
      case 'interstitial':
        adRevenue = 0.05; // $0.05 per interstitial
        break;
      case 'rewarded':
        adRevenue = 0.10; // $0.10 per rewarded ad
        break;
    }
    
    await prefs.setDouble(_keyTotalRevenue, currentRevenue + adRevenue);
  }

  Future<void> _incrementCounter(String key) async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentCount + 1);
  }

  // Reset analytics (monthly reset)
  Future<void> resetMonthlyAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBannerAdsShown, 0);
    await prefs.setInt(_keyInterstitialAdsShown, 0);
    await prefs.setInt(_keyRewardedAdsWatched, 0);
    await prefs.setInt(_keyAdImpressions, 0);
    await prefs.setInt(_keyAdClicks, 0);
    await prefs.setDouble(_keyTotalRevenue, 0.0);
    await prefs.setString(_keyLastResetDate, DateTime.now().toIso8601String());
    debugPrint('📊 Analytics reset for new month');
  }

  // Get performance metrics
  Future<Map<String, double>> getPerformanceMetrics() async {
    final analytics = await getAnalytics();
    
    int totalImpressions = analytics['totalImpressions'];
    int totalClicks = analytics['totalClicks'];
    double estimatedRevenue = analytics['estimatedRevenue'];
    
    double ctr = totalImpressions > 0 ? (totalClicks / totalImpressions) * 100 : 0.0;
    double rpm = totalImpressions > 0 ? (estimatedRevenue / totalImpressions) * 1000 : 0.0;
    
    return {
      'clickThroughRate': ctr,
      'revenuePerMille': rpm,
      'estimatedDailyRevenue': estimatedRevenue / 30, // Rough daily estimate
    };
  }

  // Export analytics data
  Future<String> exportAnalyticsData() async {
    final analytics = await getAnalytics();
    final metrics = await getPerformanceMetrics();
    
    return '''
📊 Ad Performance Report
========================

📱 Ad Impressions:
• Banner Ads: ${analytics['bannerAdsShown']}
• Interstitial Ads: ${analytics['interstitialAdsShown']}
• Rewarded Ads: ${analytics['rewardedAdsWatched']}
• Total Impressions: ${analytics['totalImpressions']}
• Total Clicks: ${analytics['totalClicks']}

💰 Revenue Metrics:
• Estimated Revenue: \$${analytics['estimatedRevenue'].toStringAsFixed(2)}
• Click-Through Rate: ${metrics['clickThroughRate']!.toStringAsFixed(2)}%
• Revenue Per Mille: \$${metrics['revenuePerMille']!.toStringAsFixed(2)}
• Est. Daily Revenue: \$${metrics['estimatedDailyRevenue']!.toStringAsFixed(2)}

📅 Report Generated: ${DateTime.now().toString()}
📅 Last Reset: ${analytics['lastResetDate']}
''';
  }
}
