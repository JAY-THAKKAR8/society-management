import 'package:flutter/material.dart';
import 'package:society_management/web/widgets/animated_counter.dart';
import 'package:society_management/web/widgets/app_screenshot.dart';
import 'package:society_management/web/widgets/cta_button.dart';
import 'package:society_management/web/widgets/faq_section.dart';
import 'package:society_management/web/widgets/feature_card.dart';
import 'package:society_management/web/widgets/footer.dart';
import 'package:society_management/web/widgets/placeholder_image.dart';
import 'package:society_management/web/widgets/role_feature_section.dart';
import 'package:society_management/web/widgets/testimonial_card.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();

  // References to section keys for navigation
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final position = renderObject.localToGlobal(Offset.zero);
      final scrollPosition = position.dy;

      // Account for app bar height
      const appBarHeight = 80.0;
      final offset = scrollPosition - appBarHeight;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildNavBar(context),
            _buildHeroSection(context),
            _buildFeatureSection(context, key: _featuresKey),
            _buildRoleBasedSection(context),
            _buildStatisticsSection(context),
            _buildHowItWorksSection(context, key: _howItWorksKey),
            _buildScreenshotsSection(context),
            _buildTestimonialsSection(context, key: _testimonialsKey),
            _buildFAQSection(context, key: _faqKey),
            _buildCTASection(context),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              PlaceholderImage(width: 40, height: 40, icon: Icons.apartment),
              SizedBox(width: 12),
              Text(
                'Society Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A5298),
                ),
              ),
            ],
          ),
          if (MediaQuery.of(context).size.width > 768)
            Row(
              children: [
                _navItem('Features', onTap: () => _scrollToSection(_featuresKey)),
                _navItem('How It Works', onTap: () => _scrollToSection(_howItWorksKey)),
                _navItem('Testimonials', onTap: () => _scrollToSection(_testimonialsKey)),
                _navItem('FAQ', onTap: () => _scrollToSection(_faqKey)),
                const SizedBox(width: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A5298), Color(0xFF1E3C72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A5298).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Show a dialog or navigate to download page
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Download App'),
                          content: const Text('Thank you for your interest! The app will be available soon.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text(
                      'Download App',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Show mobile menu
              },
            ),
        ],
      ),
    );
  }

  Widget _navItem(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2A5298),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: isDesktop ? 100 : 60,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A3DE8), Color(0xFF5035E1)],
        ),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: _buildHeroContent(),
                ),
                const Expanded(
                  child: PlaceholderImage(
                    width: 400,
                    height: 400,
                    icon: Icons.phone_android,
                    color: Colors.white,
                    imageUrl: 'https://img.freepik.com/free-vector/mobile-app-concept-illustration_114360-690.jpg',
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildHeroContent(),
                const SizedBox(height: 40),
                const PlaceholderImage(
                  width: 300,
                  height: 300,
                  icon: Icons.phone_android,
                  color: Colors.white,
                  imageUrl: 'https://img.freepik.com/free-vector/mobile-app-concept-illustration_114360-690.jpg',
                ),
              ],
            ),
    );
  }

  Widget _buildHeroContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Empowering Smarter Communities',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'A complete solution for transparent society management with role-based access, expense tracking, and digital receipts.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            CTAButton(
              title: 'Download App',
              onPressed: () {
                // Show a dialog or navigate to download page
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Download App'),
                    content: const Text('Thank you for your interest! The app will be available soon.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              isPrimary: true,
            ),
            const SizedBox(width: 16),
            CTAButton(
              title: 'Try Demo',
              onPressed: () {
                // Scroll to features section
                _scrollToSection(_featuresKey);
              },
              isPrimary: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureSection(BuildContext context, {Key? key}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 80,
      ),
      child: Column(
        children: [
          const Text(
            'Features at a Glance',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A5298),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Everything you need to manage your society efficiently',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          GridView.count(
            crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 30,
            crossAxisSpacing: 30,
            children: const [
              FeatureCard(
                icon: Icons.people,
                title: 'Role-based Access',
                description: 'Different access levels for Admin, Line Head, and Members',
                color: Color(0xFF2A5298),
              ),
              FeatureCard(
                icon: Icons.bar_chart,
                title: 'Expense Tracking',
                description: 'Transparent tracking of all society expenses',
                color: Color(0xFF4CAF50),
              ),
              FeatureCard(
                icon: Icons.receipt_long,
                title: 'Digital Receipts',
                description: 'Generate and share digital receipts instantly',
                color: Color(0xFFF57C00),
              ),
              FeatureCard(
                icon: Icons.calendar_today,
                title: 'Monthly Reports',
                description: 'Detailed monthly financial reports',
                color: Color(0xFF9C27B0),
              ),
              FeatureCard(
                icon: Icons.account_balance_wallet,
                title: 'Emergency Fund',
                description: 'Track and manage emergency funds',
                color: Color(0xFFE91E63),
              ),
              FeatureCard(
                icon: Icons.pie_chart,
                title: 'Budgeting Tools',
                description: 'Plan and manage society budget efficiently',
                color: Color(0xFF00BCD4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBasedSection(BuildContext context) {
    return const RoleFeatureSection();
  }

  Widget _buildStatisticsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 60,
      ),
      color: const Color(0xFFF5F9FF),
      child: Column(
        children: [
          const Text(
            'Trusted by Communities',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A5298),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: isDesktop ? 80 : 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: const [
              AnimatedCounter(
                count: 50,
                label: 'Societies',
                icon: Icons.apartment,
              ),
              AnimatedCounter(
                count: 1500,
                label: 'Users',
                icon: Icons.people,
              ),
              AnimatedCounter(
                count: 10000,
                label: 'Transactions',
                icon: Icons.receipt,
              ),
              AnimatedCounter(
                count: 98,
                label: 'Satisfaction %',
                icon: Icons.thumb_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context, {Key? key}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 80,
      ),
      child: Column(
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A5298),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Simple steps to get started with Society Management',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          // Steps
          Row(
            children: [
              Expanded(
                child: _buildStepCard(
                  '01',
                  'Register Your Society',
                  'Create an account for your society and set up basic information like society name, address, and contact details.',
                  Icons.app_registration,
                  const Color(0xFF2A5298),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: _buildStepCard(
                  '02',
                  'Add Members',
                  'Add all society members with their details and assign appropriate roles (Admin, Line Head, Member).',
                  Icons.people_alt,
                  const Color(0xFF4CAF50),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 30),
                Expanded(
                  child: _buildStepCard(
                    '03',
                    'Start Managing',
                    'Begin tracking maintenance, expenses, and generating reports for complete transparency.',
                    Icons.trending_up,
                    const Color(0xFFF57C00),
                  ),
                ),
              ],
            ],
          ),
          if (!isDesktop) ...[
            const SizedBox(height: 30),
            _buildStepCard(
              '03',
              'Start Managing',
              'Begin tracking maintenance, expenses, and generating reports for complete transparency.',
              Icons.trending_up,
              const Color(0xFFF57C00),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenshotsSection(BuildContext context) {
    return const AppScreenshotSection();
  }

  Widget _buildTestimonialsSection(BuildContext context, {Key? key}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 80,
      ),
      color: const Color(0xFFF5F9FF),
      child: const Column(
        children: [
          Text(
            'What Our Users Say',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A5298),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Hear from society members and administrators',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 60),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              TestimonialCard(
                name: 'Rajesh Kumar',
                role: 'Society Admin',
                testimonial:
                    'This app has transformed how we manage our society. The transparency and ease of use have built trust among all members.',
                avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
              ),
              TestimonialCard(
                name: 'Priya Sharma',
                role: 'Line Head',
                testimonial:
                    'As a line head, I can easily track payments and expenses. The digital receipts feature saves so much time and paperwork!',
                avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
              ),
              TestimonialCard(
                name: 'Amit Patel',
                role: 'Society Member',
                testimonial:
                    'I love how I can see all expenses and maintenance details. The transparency builds trust in our society management.',
                avatarUrl: 'https://randomuser.me/api/portraits/men/67.jpg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, {Key? key}) {
    return FAQSection(key: key);
  }

  Widget _buildStepCard(String number, String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                number,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.3),
                ),
              ),
            ],
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
          const SizedBox(height: 12),
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
    );
  }

  Widget _buildCTASection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A5298), Color(0xFF1E3C72)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Transform Your Society Management?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Join thousands of satisfied users and make society management effortless',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CTAButton(
                title: 'Download App',
                onPressed: () {
                  // Show a dialog or navigate to download page
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Download App'),
                      content: const Text('Thank you for your interest! The app will be available soon.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(width: 16),
              CTAButton(
                title: 'Contact Us',
                onPressed: () {
                  // Show contact form dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Contact Us'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Message',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Submit form
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your message! We\'ll get back to you soon.'),
                                backgroundColor: Color(0xFF2A5298),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A5298),
                          ),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  );
                },
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
