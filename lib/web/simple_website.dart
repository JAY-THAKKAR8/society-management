import 'dart:async';

import 'package:flutter/material.dart';

import 'simple_website_footer.dart';
import 'simple_website_sections.dart';
import 'simple_website_sections2.dart';

class SimpleWebsite extends StatefulWidget {
  const SimpleWebsite({super.key});

  @override
  State<SimpleWebsite> createState() => _SimpleWebsiteState();
}

class _SimpleWebsiteState extends State<SimpleWebsite> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // For animated counters
  final Map<String, int> _counters = {
    'users': 0,
    'communities': 0,
    'transactions': 0,
  };

  final Map<String, int> _targetCounters = {
    'users': 5000,
    'communities': 120,
    'transactions': 25000,
  };

  Timer? _counterTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Start counter animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _startCounterAnimation();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _counterTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  void _startCounterAnimation() {
    _counterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      bool allDone = true;

      setState(() {
        for (final entry in _targetCounters.entries) {
          final key = entry.key;
          final target = entry.value;

          if (_counters[key]! < target) {
            _counters[key] = _counters[key]! + (target ~/ 100);
            if (_counters[key]! > target) {
              _counters[key] = target;
            }
            allDone = false;
          }
        }
      });

      if (allDone) {
        timer.cancel();
      }
    });
  }

  void _scrollToSection(String section) {
    double offset = 0;

    switch (section) {
      case 'features':
        offset = 600;
        break;
      case 'screenshots':
        offset = 1200;
        break;
      case 'pricing':
        offset = 1800;
        break;
      case 'contact':
        offset = 2400;
        break;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(),
                WebsiteSections.buildFeaturesSection(),
                WebsiteSections.buildStatisticsSection(_counters),
                WebsiteSections.buildScreenshotsSection(),
                WebsiteSections2.buildPricingSection(),
                WebsiteSections2.buildContactSection(),
                WebsiteFooter.buildFooter(),
              ],
            ),
          ),

          // Fixed navigation bar
          _buildNavBar(),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 70,
      color: _isScrolled ? Colors.white : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A42F5), Color(0xFF5D3FE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A42F5).withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Society Manager',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isScrolled ? const Color(0xFF333333) : Colors.white,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Navigation links
          Row(
            children: [
              _buildNavLink('Features', () => _scrollToSection('features')),
              _buildNavLink('Screenshots', () => _scrollToSection('screenshots')),
              _buildNavLink('Pricing', () => _scrollToSection('pricing')),
              _buildNavLink('Contact', () => _scrollToSection('contact')),
              const SizedBox(width: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A42F5), Color(0xFF5D3FE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A42F5).withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show demo dialog with animation
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                        child: Container(
                          width: 450,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8A42F5).withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_circle_filled,
                                      color: Color(0xFF8A42F5),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Try Interactive Demo',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Experience our platform with a fully interactive demo. No sign-up required!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'https://cdn.dribbble.com/users/1615584/screenshots/16978571/media/e3f44a3cd86e5bf56c9c3e1b5c8c31d7.jpg',
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 220,
                                      width: double.infinity,
                                      color: Colors.grey.withAlpha(30),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF8A42F5),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 220,
                                      width: double.infinity,
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
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF666666),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    child: const Text('Maybe Later'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8A42F5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_arrow, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Launch Demo',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_filled, size: 18),
                  label: const Text(
                    'Try Demo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: _isScrolled ? const Color(0xFF333333) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 600,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A42F5), Color(0xFF5D3FE8)],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Row(
              children: [
                // Left side - Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Transform Your\nCommunity Experience',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Elevate your residential management with our all-in-one digital platform featuring smart controls, crystal-clear financial tracking, and instant digital documentation.',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  // Show a dialog with a form
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 5,
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        width: 400,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF8A42F5).withAlpha(30),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.rocket_launch_rounded,
                                                    color: Color(0xFF8A42F5),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                const Text(
                                                  'Get Started Today',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF333333),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            const Text(
                                              'Enter your details to begin your journey',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            const TextField(
                                              decoration: InputDecoration(
                                                labelText: 'Name',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                                ),
                                                prefixIcon: Icon(Icons.person, color: Color(0xFF8A42F5)),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                                  borderSide: BorderSide(color: Color(0xFF8A42F5), width: 2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const TextField(
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                                ),
                                                prefixIcon: Icon(Icons.email, color: Color(0xFF8A42F5)),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                                  borderSide: BorderSide(color: Color(0xFF8A42F5), width: 2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: const Color(0xFF666666),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  ),
                                                  child: const Text('Cancel'),
                                                ),
                                                const SizedBox(width: 16),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF8A42F5),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Submit',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF8A42F5),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: OutlinedButton(
                                onPressed: () {
                                  // Scroll to features section
                                  _scrollToSection('features');
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore Features',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.explore, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right side - Image with animation
                Expanded(
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8A42F5).withAlpha(76),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  'https://cdn.dribbble.com/users/1615584/screenshots/15571949/media/7e95f0fddb7957096217d5bf5ed9ebfa.jpg',
                                  height: 400,
                                  width: 350,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 400,
                                      width: 350,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(25),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
