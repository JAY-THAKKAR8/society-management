import 'package:flutter/material.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 60,
      ),
      color: const Color(0xFF1E3C72),
      child: Column(
        children: [
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildCompanyInfo()),
                    Expanded(child: _buildLinks()),
                    Expanded(child: _buildContactInfo()),
                  ],
                )
              : Column(
                  children: [
                    _buildCompanyInfo(),
                    const SizedBox(height: 40),
                    _buildLinks(),
                    const SizedBox(height: 40),
                    _buildContactInfo(),
                  ],
                ),
          const SizedBox(height: 60),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '© 2023 Society Management. All rights reserved.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (isDesktop || isTablet)
                Row(
                  children: [
                    _buildSocialIcon(Icons.facebook),
                    _buildSocialIcon(Icons.chat),
                    _buildSocialIcon(Icons.business),
                    _buildSocialIcon(Icons.photo_camera),
                  ],
                ),
            ],
          ),
          if (!isDesktop && !isTablet) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(Icons.facebook),
                _buildSocialIcon(Icons.chat),
                _buildSocialIcon(Icons.business),
                _buildSocialIcon(Icons.photo_camera),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset('assets/images/logo_white.png', height: 40, width: 40),
            const SizedBox(width: 12),
            const Text(
              'Society Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Empowering communities with transparent and efficient society management solutions.',
          style: TextStyle(
            color: Colors.white70,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildAppStoreButton('assets/images/app_store.png'),
            const SizedBox(width: 12),
            _buildAppStoreButton('assets/images/play_store.png'),
          ],
        ),
      ],
    );
  }

  Widget _buildLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        _buildFooterLink('Features'),
        _buildFooterLink('How It Works'),
        _buildFooterLink('Testimonials'),
        _buildFooterLink('FAQ'),
        _buildFooterLink('Privacy Policy'),
        _buildFooterLink('Terms of Service'),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        _buildContactItem(
          Icons.email,
          'contact@societymanagement.com',
        ),
        _buildContactItem(
          Icons.phone,
          '+91 9876543210',
        ),
        _buildContactItem(
          Icons.location_on,
          '123 Tech Park, Bangalore, India',
        ),
        const SizedBox(height: 20),
        const Text(
          'Subscribe to Newsletter',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Your email',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2A5298),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Subscribe'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildAppStoreButton(String imagePath) {
    return InkWell(
      onTap: () {},
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(
          imagePath,
          height: 24,
        ),
      ),
    );
  }
}
