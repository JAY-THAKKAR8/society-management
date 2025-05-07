import 'package:flutter/material.dart';

class AppScreenshotSection extends StatefulWidget {
  const AppScreenshotSection({super.key});

  @override
  State<AppScreenshotSection> createState() => _AppScreenshotSectionState();
}

class _AppScreenshotSectionState extends State<AppScreenshotSection> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  final List<Map<String, String>> _screenshots = [
    {
      'image': 'https://img.freepik.com/free-vector/dashboard-user-panel-template_23-2148627943.jpg',
      'title': 'Admin Dashboard',
      'description': 'Complete overview of society finances, maintenance, and user management.',
    },
    {
      'image': 'https://img.freepik.com/free-vector/gradient-ui-ux-background_23-2149052117.jpg',
      'title': 'Expense Tracking',
      'description': 'Detailed expense tracking with categories, charts, and filters.',
    },
    {
      'image': 'https://img.freepik.com/free-vector/gradient-ui-ux-background_23-2149065782.jpg',
      'title': 'Digital Receipts',
      'description': 'Generate and share professional digital receipts instantly.',
    },
    {
      'image': 'https://img.freepik.com/free-vector/gradient-infographic-template_23-2149164255.jpg',
      'title': 'Line Head View',
      'description': 'Manage line members, collect payments, and track line-specific expenses.',
    },
    {
      'image': 'https://img.freepik.com/free-vector/gradient-ui-ux-background_23-2149065779.jpg',
      'title': 'Member Dashboard',
      'description': 'View payment history, society expenses, and announcements.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      child: Column(
        children: [
          const Text(
            'App Screenshots',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A5298),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'See the app in action with these screenshots',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 600,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _screenshots.length,
              itemBuilder: (context, index) {
                final double distance = (index - _currentPage).abs().toDouble();
                final isActive = index == _currentPage;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  margin: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isActive ? 0 : 50,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isActive ? const Color(0xFF2A5298).withOpacity(0.3) : Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Opacity(
                      opacity: 1.0 - (distance * 0.3).clamp(0.0, 0.6),
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              _screenshots[index]['image']!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF2A5298),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFEEEEEE),
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Color(0xFF2A5298),
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _screenshots[index]['title']!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _screenshots[index]['description']!,
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
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _screenshots.length,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? const Color(0xFF2A5298) : const Color(0xFFCCCCCC),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
