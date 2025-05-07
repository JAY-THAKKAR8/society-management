import 'package:flutter/material.dart';

class WebsiteSections2 {
  static Widget buildPricingSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          const Text(
            'Flexible Pricing',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8A42F5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Transparent and affordable plans for communities of all sizes',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildPricingCard(
                'Basic',
                '₹999',
                'per month',
                [
                  'Up to 50 residents',
                  'Basic financial tracking',
                  'Digital receipts',
                  'Email support',
                ],
                false,
              ),
              buildPricingCard(
                'Pro',
                '₹1,999',
                'per month',
                [
                  'Up to 200 residents',
                  'Advanced financial tracking',
                  'Digital receipts',
                  'Priority support',
                  'Custom branding',
                ],
                true,
              ),
              buildPricingCard(
                'Enterprise',
                'Custom',
                'contact for pricing',
                [
                  'Unlimited residents',
                  'Full feature access',
                  'API integration',
                  'Dedicated support',
                  'Custom development',
                ],
                false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget buildPricingCard(String title, String price, String period, List<String> features, bool isPopular) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isPopular ? Border.all(color: const Color(0xFF8A42F5), width: 2) : null,
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8A42F5), Color(0xFF5D3FE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Text(
                'Most Popular',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A42F5),
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? const Color(0xFF8A42F5) : Colors.white,
                      foregroundColor: isPopular ? Colors.white : const Color(0xFF8A42F5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: isPopular ? BorderSide.none : const BorderSide(color: Color(0xFF8A42F5)),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  static Widget buildContactSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Row(
        children: [
          // Left side - Contact form
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get in Touch',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A42F5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Have questions? We\'re here to help!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A42F5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 40),

          // Right side - Contact info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get in Touch',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 30),
                buildContactInfo(
                  Icons.email,
                  'Email Us',
                  'contact@societymanager.com',
                ),
                const SizedBox(height: 30),
                buildContactInfo(
                  Icons.phone,
                  'Call Us',
                  '+91 9876543210',
                ),
                const SizedBox(height: 30),
                buildContactInfo(
                  Icons.location_on,
                  'Visit Us',
                  '123 Tech Park, Bangalore, India',
                ),
                const SizedBox(height: 40),
                const Text(
                  'Follow Us',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    buildSocialIcon(Icons.facebook),
                    buildSocialIcon(Icons.chat),
                    buildSocialIcon(Icons.business),
                    buildSocialIcon(Icons.photo_camera),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildContactInfo(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF8A42F5).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF8A42F5),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildSocialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8A42F5).withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: const Color(0xFF8A42F5),
        size: 24,
      ),
    );
  }
}
