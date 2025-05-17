import 'package:flutter/material.dart';
import 'package:society_management/chat/service/society_ai_service.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/theme_utils.dart';

/// A page that displays AI-generated insights about the society
class SocietyInsightsPage extends StatefulWidget {
  const SocietyInsightsPage({super.key});

  @override
  State<SocietyInsightsPage> createState() => _SocietyInsightsPageState();
}

class _SocietyInsightsPageState extends State<SocietyInsightsPage> {
  final SocietyAIService _aiService = SocietyAIService();

  bool _isLoading = true;
  String _insightsText = '';
  String _userInfoText = '';
  String _paymentsInfoText = '';
  String _statsInfoText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _aiService.getSocietyInsights(),
        _aiService.getCurrentUserInfo(),
        _aiService.getPendingPaymentsInfo(),
        _aiService.getSocietyStatsInfo(),
      ]);

      setState(() {
        _insightsText = results[0];
        _userInfoText = results[1];
        _paymentsInfoText = results[2];
        _statsInfoText = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _insightsText = "Sorry, I couldn't analyze the society data at this time. Please try again later.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Insights'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing society data...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main insights card
                  _buildInsightsCard(
                    context,
                    title: 'AI Summary',
                    content: _insightsText,
                    icon: Icons.insights,
                    color: AppColors.primary,
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 16),

                  // User info card
                  _buildInsightsCard(
                    context,
                    title: 'Your Information',
                    content: _userInfoText,
                    icon: Icons.person,
                    color: Colors.teal,
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 16),

                  // Payments info card
                  _buildInsightsCard(
                    context,
                    title: 'Maintenance Payments',
                    content: _paymentsInfoText,
                    icon: Icons.payment,
                    color: Colors.orange,
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 16),

                  // Society stats card
                  _buildInsightsCard(
                    context,
                    title: 'Society Statistics',
                    content: _statsInfoText,
                    icon: Icons.bar_chart,
                    color: Colors.purple,
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 24),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This information is generated by AI and may not be 100% accurate. '
                            'Please refer to the official records for the most up-to-date information.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInsightsCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? color.withAlpha(50) : color.withAlpha(25),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
