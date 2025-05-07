import 'package:flutter/material.dart';

class WebsiteSections {
  static Widget buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Column(
        children: [
          const Text(
            'Powerful Features',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8A42F5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Innovative tools designed to revolutionize community management',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),

          // Features grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30,
            children: [
              buildFeatureCard(
                'Smart Access Control',
                'Tailored access for managers, coordinators, and residents',
                Icons.security,
                const Color(0xFF8A42F5),
              ),
              buildFeatureCard(
                'Financial Tracking',
                'Transparent expense management and payment tracking',
                Icons.account_balance_wallet,
                const Color(0xFF4CAF50),
              ),
              buildFeatureCard(
                'Digital Receipts',
                'Generate and share professional digital receipts instantly',
                Icons.receipt_long,
                const Color(0xFFF57C00),
              ),
              buildFeatureCard(
                'Analytics Dashboard',
                'Comprehensive insights with visual data representation',
                Icons.bar_chart,
                const Color(0xFF9C27B0),
              ),
              buildFeatureCard(
                'Communication Tools',
                'Built-in messaging and announcement system',
                Icons.message,
                const Color(0xFFE91E63),
              ),
              buildFeatureCard(
                'Mobile Access',
                'Access all features on the go with our mobile app',
                Icons.phone_android,
                const Color(0xFF00BCD4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildFeatureCard(String title, String description, IconData icon, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildStatisticsSection(Map<String, int> counters) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          const Text(
            'Growing Community',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8A42F5),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildStatCard(
                '${formatNumber(counters['users']!)}+',
                'Active Users',
                Icons.people,
              ),
              buildStatCard(
                '${formatNumber(counters['communities']!)}+',
                'Communities',
                Icons.apartment,
              ),
              buildStatCard(
                '${formatNumber(counters['transactions']!)}+',
                'Transactions',
                Icons.receipt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String formatNumber(int number) {
    if (number >= 1000) {
      double result = number / 1000;
      return '${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}k';
    }
    return number.toString();
  }

  static Widget buildStatCard(String value, String label, IconData icon) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF8A42F5),
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildScreenshotsSection() {
    final List<Map<String, dynamic>> screenshots = [
      {
        'image':
            'https://cdn.dribbble.com/users/1615584/screenshots/16342029/media/8b1f34c9c61cd3240d3ba1879f722f85.jpg',
        'title': 'Dashboard',
        'description': 'Comprehensive overview with real-time data',
        'icon': Icons.dashboard,
        'color': const Color(0xFF8A42F5),
      },
      {
        'image':
            'https://cdn.dribbble.com/users/1615584/screenshots/16978572/media/b6bd5e09e2ca5820de55369d13a1ef8a.jpg',
        'title': 'Financial Reports',
        'description': 'Detailed financial tracking and reporting',
        'icon': Icons.bar_chart,
        'color': const Color(0xFF4CAF50),
      },
      {
        'image':
            'https://cdn.dribbble.com/users/1615584/screenshots/16978571/media/e3f44a3cd86e5bf56c9c3e1b5c8c31d7.jpg',
        'title': 'User Management',
        'description': 'Easy user management with role-based access',
        'icon': Icons.people,
        'color': const Color(0xFFE91E63),
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF8A42F5),
                size: 28,
              ),
              SizedBox(width: 16),
              Text(
                'Stunning Interface',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8A42F5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Experience our beautiful and intuitive user interface',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: screenshots.map((screenshot) {
              return Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            screenshot['image']!,
                            height: 200,
                            width: 300,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                width: 300,
                                color: Colors.grey.withAlpha(30),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: screenshot['color'],
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: 300,
                                color: Colors.grey.withAlpha(30),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              screenshot['icon'],
                              color: screenshot['color'],
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                screenshot['icon'],
                                color: screenshot['color'],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                screenshot['title']!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            screenshot['description']!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
