import 'package:flutter/material.dart';

class FAQSection extends StatefulWidget {
  const FAQSection({super.key});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I get started with Society Management?',
      'answer': 'Getting started is easy! Download the app, create an account, and your society admin will assign you the appropriate role. Once your role is assigned, you can start using all the features available to your role.',
      'isExpanded': false,
    },
    {
      'question': 'What are the different roles in the app?',
      'answer': 'The app has three main roles: Admin, Line Head, and Member. Each role has different access levels and features tailored to their responsibilities in the society.',
      'isExpanded': false,
    },
    {
      'question': 'How does the expense tracking work?',
      'answer': 'All expenses are recorded with details like amount, category, date, and purpose. These expenses are visible to all members for complete transparency. You can view expenses by category, date range, or line.',
      'isExpanded': false,
    },
    {
      'question': 'Can I get digital receipts for my payments?',
      'answer': 'Yes! Whenever you make a payment, a digital receipt is generated automatically. You can view, download, or share these receipts directly from the app.',
      'isExpanded': false,
    },
    {
      'question': 'Is my data secure in the app?',
      'answer': 'Absolutely! We use industry-standard encryption and security practices to protect your data. Your personal and financial information is always kept secure and private.',
      'isExpanded': false,
    },
    {
      'question': 'Can I use the app offline?',
      'answer': 'The app requires an internet connection for most features to ensure real-time data synchronization. However, you can view previously loaded data even when offline.',
      'isExpanded': false,
    },
  ];

  void _toggleExpansion(int index) {
    setState(() {
      _faqs[index]['isExpanded'] = !_faqs[index]['isExpanded'];
    });
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
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A5298),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Find answers to common questions about Society Management',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          ...List.generate(
            _faqs.length,
            (index) => _buildFAQItem(index),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Still have questions?',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5298),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: _faqs[index]['isExpanded'] 
              ? const Color(0xFF2A5298) 
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          _faqs[index]['question'],
          style: TextStyle(
            fontSize: 18,
            fontWeight: _faqs[index]['isExpanded'] ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF333333),
          ),
        ),
        trailing: Icon(
          _faqs[index]['isExpanded'] ? Icons.remove : Icons.add,
          color: _faqs[index]['isExpanded'] 
              ? const Color(0xFF2A5298) 
              : const Color(0xFF666666),
        ),
        onExpansionChanged: (expanded) {
          _toggleExpansion(index);
        },
        initiallyExpanded: _faqs[index]['isExpanded'],
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _faqs[index]['answer'],
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
