import 'package:flutter/material.dart';

class RoleFeatureSection extends StatefulWidget {
  const RoleFeatureSection({super.key});

  @override
  State<RoleFeatureSection> createState() => _RoleFeatureSectionState();
}

class _RoleFeatureSectionState extends State<RoleFeatureSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _roles = ['Manager', 'Coordinator', 'Resident'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 80,
      ),
      color: const Color(0xFFF5F9FF),
      child: Column(
        children: [
          const Text(
            'Smart Access Control',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A3DE8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tailored experiences for everyone in your community',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A3DE8), Color(0xFF5035E1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: _roles.map((role) => Tab(text: role)).toList(),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdminFeatures(isDesktop),
                _buildLineHeadFeatures(isDesktop),
                _buildMemberFeatures(isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeatures(bool isDesktop) {
    return isDesktop
        ? Row(
            children: [
              Expanded(
                child: _buildFeatureList([
                  'Comprehensive dashboard with real-time analytics',
                  'Powerful user management with custom permissions',
                  'Smart payment tracking and automated reminders',
                  'Advanced financial reporting and data visualization',
                  'Intelligent budget planning and expense tracking',
                  'Customizable settings and notification preferences',
                ]),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://img.freepik.com/free-vector/dashboard-user-panel-template_23-2148627943.jpg',
                    height: 350,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF6A3DE8),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 350,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.dashboard_customize,
                            size: 80,
                            color: Color(0xFF6A3DE8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          )
        : Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://img.freepik.com/free-vector/dashboard-user-panel-template_23-2148627943.jpg',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF6A3DE8),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.dashboard_customize,
                          size: 60,
                          color: Color(0xFF6A3DE8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildFeatureList([
                'Comprehensive dashboard with real-time analytics',
                'Powerful user management with custom permissions',
                'Smart payment tracking and automated reminders',
                'Advanced financial reporting and data visualization',
                'Intelligent budget planning and expense tracking',
                'Customizable settings and notification preferences',
              ]),
            ],
          );
  }

  Widget _buildLineHeadFeatures(bool isDesktop) {
    return isDesktop
        ? Row(
            children: [
              Expanded(
                child: _buildFeatureList([
                  'View and manage line members',
                  'Collect maintenance payments',
                  'Generate digital receipts',
                  'Track line-specific expenses',
                  'View line-specific reports',
                  'Communicate with line members',
                ]),
              ),
              Expanded(
                child: Image.asset(
                  'assets/images/line_head_dashboard.png',
                  height: 350,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Image.asset(
                'assets/images/line_head_dashboard.png',
                height: 200,
              ),
              const SizedBox(height: 24),
              _buildFeatureList([
                'View and manage line members',
                'Collect maintenance payments',
                'Generate digital receipts',
                'Track line-specific expenses',
                'View line-specific reports',
                'Communicate with line members',
              ]),
            ],
          );
  }

  Widget _buildMemberFeatures(bool isDesktop) {
    return isDesktop
        ? Row(
            children: [
              Expanded(
                child: _buildFeatureList([
                  'View personal payment history',
                  'Track society expenses transparently',
                  'Submit complaints and suggestions',
                  'Receive digital receipts',
                  'View society announcements',
                  'Access emergency contact information',
                ]),
              ),
              Expanded(
                child: Image.asset(
                  'assets/images/member_dashboard.png',
                  height: 350,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Image.asset(
                'assets/images/member_dashboard.png',
                height: 200,
              ),
              const SizedBox(height: 24),
              _buildFeatureList([
                'View personal payment history',
                'Track society expenses transparently',
                'Submit complaints and suggestions',
                'Receive digital receipts',
                'View society announcements',
                'Access emergency contact information',
              ]),
            ],
          );
  }

  Widget _buildFeatureList(List<String> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => _buildFeatureItem(feature)).toList(),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A5298),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
