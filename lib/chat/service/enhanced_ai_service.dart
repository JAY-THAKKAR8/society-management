import 'package:flutter/foundation.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/chat/service/admin_analytics_service.dart';
import 'package:society_management/chat/service/gemini_service.dart';
import 'package:society_management/chat/service/smart_reminder_service.dart';
import 'package:society_management/chat/service/society_data_service.dart';
import 'package:society_management/injector/injector.dart';

/// Enhanced AI service that combines Gemini AI with smart features
class EnhancedAIService {
  final GeminiService _geminiService = GeminiService();
  final SmartReminderService _reminderService = SmartReminderService();
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  final SocietyDataService _dataService = SocietyDataService();
  final AuthService _authService = getIt<AuthService>();

  /// Main method to process user queries with enhanced features
  Future<String> processQuery(String query) async {
    try {
      debugPrint('Processing enhanced AI query: $query');

      final lowerQuery = query.toLowerCase();

      // Check for specific smart features first
      if (_isPaymentReminderRequest(lowerQuery)) {
        return await _handlePaymentReminder(lowerQuery);
      }

      if (_isDueDateAlertRequest(lowerQuery)) {
        return await _handleDueDateAlert();
      }

      if (_isLineReminderRequest(lowerQuery)) {
        return await _handleLineReminder();
      }

      if (_isAdminAnalyticsRequest(lowerQuery)) {
        return await _handleAdminAnalytics(lowerQuery);
      }

      // New feature handlers
      if (_isMaintenanceHistoryRequest(lowerQuery)) {
        return await _handleMaintenanceHistory();
      }

      if (_isLateFeeRequest(lowerQuery)) {
        return await _handleLateFeeCalculation();
      }

      if (_isPaymentMethodsRequest(lowerQuery)) {
        return await _handlePaymentMethods();
      }

      if (_isLineHeadContactRequest(lowerQuery)) {
        return await _handleLineHeadContact();
      }

      if (_isSocietyRulesRequest(lowerQuery)) {
        return await _handleSocietyRules();
      }

      if (_isComplaintStatusRequest(lowerQuery)) {
        return await _handleComplaintStatus();
      }

      if (_isEventUpdatesRequest(lowerQuery)) {
        return await _handleEventUpdates();
      }

      if (_isExpenseBreakdownRequest(lowerQuery)) {
        return await _handleExpenseBreakdown();
      }

      // For general queries, use the standard Gemini service
      return await _geminiService.generateResponse(query);
    } catch (e) {
      debugPrint('Error in enhanced AI service: $e');
      return "Sorry, I encountered an error while processing your request. Please try again.";
    }
  }

  /// Check if the query is asking for payment reminders
  bool _isPaymentReminderRequest(String query) {
    final reminderKeywords = [
      'payment reminder',
      'remind me about payment',
      'pending payment',
      'my dues',
      'what do i owe',
      'payment status',
      'maintenance reminder',
      'check my payments',
      'check my dues'
    ];

    return reminderKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for maintenance history
  bool _isMaintenanceHistoryRequest(String query) {
    final historyKeywords = [
      'maintenance history',
      'payment history',
      'past payments',
      'previous payments',
      'payment records',
      'my history'
    ];

    return historyKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for late fee calculation
  bool _isLateFeeRequest(String query) {
    final lateFeeKeywords = [
      'late fee',
      'late fees',
      'calculate late fee',
      'penalty',
      'overdue charges',
      'late charges'
    ];

    return lateFeeKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for payment methods
  bool _isPaymentMethodsRequest(String query) {
    final paymentMethodKeywords = [
      'payment methods',
      'how to pay',
      'payment options',
      'pay online',
      'payment ways',
      'how can i pay'
    ];

    return paymentMethodKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for line head contact
  bool _isLineHeadContactRequest(String query) {
    final contactKeywords = [
      'line head contact',
      'contact line head',
      'line head number',
      'line head phone',
      'my line head',
      'line head details'
    ];

    return contactKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for society rules
  bool _isSocietyRulesRequest(String query) {
    final rulesKeywords = [
      'society rules',
      'society guidelines',
      'rules and regulations',
      'society policies',
      'community rules',
      'society bylaws'
    ];

    return rulesKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for complaint status
  bool _isComplaintStatusRequest(String query) {
    final complaintKeywords = [
      'complaint status',
      'my complaints',
      'complaint update',
      'check complaint',
      'complaint progress',
      'submitted complaints'
    ];

    return complaintKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for event updates
  bool _isEventUpdatesRequest(String query) {
    final eventKeywords = [
      'event updates',
      'upcoming events',
      'society events',
      'events',
      'activities',
      'community events'
    ];

    return eventKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for expense breakdown
  bool _isExpenseBreakdownRequest(String query) {
    final expenseKeywords = [
      'expense breakdown',
      'how money spent',
      'maintenance usage',
      'expense details',
      'where money goes',
      'society expenses'
    ];

    return expenseKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for due date alerts
  bool _isDueDateAlertRequest(String query) {
    final dueDateKeywords = [
      'due date',
      'when is due',
      'payment due',
      'deadline',
      'overdue',
      'late payment',
      'upcoming due'
    ];

    return dueDateKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for line reminders (line heads)
  bool _isLineReminderRequest(String query) {
    final lineKeywords = [
      'line reminder',
      'my line status',
      'line collection',
      'line members payment',
      'line head summary',
      'collection status'
    ];

    return lineKeywords.any((keyword) => query.contains(keyword));
  }

  /// Check if the query is asking for admin analytics
  bool _isAdminAnalyticsRequest(String query) {
    final analyticsKeywords = [
      'financial health',
      'society report',
      'admin analytics',
      'collection trends',
      'line wise analysis',
      'defaulter analysis',
      'society analytics',
      'financial report',
      'admin dashboard',
      'society performance'
    ];

    return analyticsKeywords.any((keyword) => query.contains(keyword));
  }

  /// Handle payment reminder requests
  Future<String> _handlePaymentReminder(String query) async {
    try {
      return await _reminderService.generatePaymentReminder();
    } catch (e) {
      debugPrint('Error generating payment reminder: $e');
      return "Sorry, I couldn't generate your payment reminder at this time. Please try again later.";
    }
  }

  /// Handle due date alert requests
  Future<String> _handleDueDateAlert() async {
    try {
      return await _reminderService.generateDueDateAlert();
    } catch (e) {
      debugPrint('Error generating due date alert: $e');
      return "Sorry, I couldn't check due dates at this time. Please try again later.";
    }
  }

  /// Handle line reminder requests (for line heads)
  Future<String> _handleLineReminder() async {
    try {
      return await _reminderService.generateLineReminderForLineHead();
    } catch (e) {
      debugPrint('Error generating line reminder: $e');
      return "Sorry, I couldn't generate line reminder at this time. Please try again later.";
    }
  }

  /// Handle admin analytics requests
  Future<String> _handleAdminAnalytics(String query) async {
    try {
      // Determine which type of analytics is requested
      if (query.contains('financial health') || query.contains('financial report')) {
        return await _analyticsService.generateFinancialHealthReport();
      }

      if (query.contains('line wise') || query.contains('line analysis')) {
        return await _analyticsService.generateLineWiseAnalysis();
      }

      if (query.contains('collection trends') || query.contains('trends')) {
        return await _analyticsService.generateCollectionTrends();
      }

      if (query.contains('defaulter') || query.contains('pending members')) {
        return await _analyticsService.generateDefaulterAnalysis();
      }

      // Default to financial health report for general admin analytics requests
      return await _analyticsService.generateFinancialHealthReport();
    } catch (e) {
      debugPrint('Error generating admin analytics: $e');
      return "Sorry, I couldn't generate analytics at this time. Please try again later.";
    }
  }

  /// Handle maintenance history requests
  Future<String> _handleMaintenanceHistory() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to view your maintenance history.";
      }

      // Get user's payment history
      final paymentHistory = await _dataService.getUserPaymentHistory();

      if (paymentHistory.isEmpty) {
        return """
📋 Maintenance Payment History

Hello ${currentUser.name},

No payment history found for your account.

This could mean:
• You're a new member
• No payments have been recorded yet
• There might be a data sync issue

Contact your Line Head or Admin for assistance.
""";
      }

      // Format payment history
      String historyText = """
📋 Maintenance Payment History

Hello ${currentUser.name},

Here's your complete payment history:

""";

      int totalPaid = 0;
      double totalAmount = 0;

      for (final payment in paymentHistory.take(10)) {
        // Show last 10 payments
        final periodName = payment['period_name'] ?? 'Unknown Period';
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
        final amountPaid = (payment['amount_paid'] as num?)?.toDouble() ?? 0;
        final status = payment['status'] ?? 'unknown';
        final paymentDate = payment['payment_date'] ?? 'Not recorded';

        if (status == 'paid') {
          totalPaid++;
          totalAmount += amountPaid;
        }

        final statusEmoji = status == 'paid' ? '✅' : '⏳';

        historyText += """
$statusEmoji **$periodName**
   Amount: ₹${amount.toStringAsFixed(2)}
   Paid: ₹${amountPaid.toStringAsFixed(2)}
   Status: ${status.toUpperCase()}
   Date: $paymentDate

""";
      }

      historyText += """
📊 **SUMMARY**:
• Total Periods Paid: $totalPaid
• Total Amount Paid: ₹${totalAmount.toStringAsFixed(2)}
• Payment Record: ${totalPaid > 0 ? 'Good' : 'Needs Attention'}

💡 Keep up your payment consistency for a healthy society! 🏠
""";

      return historyText;
    } catch (e) {
      debugPrint('Error generating maintenance history: $e');
      return "Sorry, I couldn't retrieve your payment history at this time. Please try again later.";
    }
  }

  /// Handle late fee calculation requests
  Future<String> _handleLateFeeCalculation() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to calculate late fees.";
      }

      // Get pending payments to calculate late fees
      final pendingPayments = await _dataService.getUserPendingPaymentsList();

      if (pendingPayments.isEmpty) {
        return """
💰 Late Fee Calculator

Hello ${currentUser.name},

Great news! You have no pending payments, so no late fees apply.

✅ All maintenance payments are up to date
✅ No overdue amounts
✅ No late fee charges

Keep up the excellent payment record! 👏
""";
      }

      double totalLateFees = 0;
      int overdueCount = 0;
      String feeBreakdown = "";

      final now = DateTime.now();

      for (final payment in pendingPayments) {
        final dueDateStr = payment['due_date'] as String?;
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
        final amountPaid = (payment['amount_paid'] as num?)?.toDouble() ?? 0;
        final pendingAmount = amount - amountPaid;

        if (dueDateStr != null && pendingAmount > 0) {
          try {
            final dueDate = DateTime.parse(dueDateStr);
            final daysOverdue = now.difference(dueDate).inDays;

            if (daysOverdue > 0) {
              // Calculate late fee: ₹10 per day after due date
              final lateFee = daysOverdue * 10.0;
              totalLateFees += lateFee;
              overdueCount++;

              feeBreakdown += """
📅 **${payment['period_name'] ?? 'Unknown Period'}**
   Pending Amount: ₹${pendingAmount.toStringAsFixed(2)}
   Days Overdue: $daysOverdue
   Late Fee: ₹${lateFee.toStringAsFixed(2)}

""";
            }
          } catch (e) {
            debugPrint('Error parsing due date: $e');
          }
        }
      }

      if (totalLateFees == 0) {
        return """
💰 Late Fee Calculator

Hello ${currentUser.name},

You have pending payments but no late fees yet!

✅ All pending payments are still within due date
💡 Pay before due dates to avoid late fees

Current pending payments are not overdue. 📅
""";
      }

      return """
💰 Late Fee Calculator

Hello ${currentUser.name},

Here's your current late fee calculation:

$feeBreakdown

📊 **TOTAL LATE FEES**: ₹${totalLateFees.toStringAsFixed(2)}
📋 **Overdue Periods**: $overdueCount

⚠️ **Important**: Late fees accumulate daily at ₹10 per day per overdue period.

💡 **Action Required**:
• Pay pending amounts immediately to stop late fee accumulation
• Contact your Line Head for payment assistance
• Use the Maintenance section in app for payment details

Pay now to avoid additional charges! 💳
""";
    } catch (e) {
      debugPrint('Error calculating late fees: $e');
      return "Sorry, I couldn't calculate late fees at this time. Please try again later.";
    }
  }

  /// Handle payment methods requests
  Future<String> _handlePaymentMethods() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to view payment methods.";
      }

      return """
💳 Payment Methods & Options

Hello ${currentUser.name},

Here are the available ways to pay your maintenance:

**🏦 DIRECT PAYMENT OPTIONS**:
• **Line Head Collection**: Contact your Line Head directly
• **Society Office**: Visit during office hours
• **Bank Transfer**: Direct transfer to society account

**📱 DIGITAL PAYMENT OPTIONS**:
• **UPI Payment**: Pay via Google Pay, PhonePe, Paytm
• **Net Banking**: Online bank transfer
• **Mobile Banking**: Use your bank's mobile app

**💰 PAYMENT DETAILS**:
• **Line Head**: Contact for collection schedule
• **Society Account**: Get details from admin
• **Receipt**: Always collect payment receipt

**📞 CONTACT FOR PAYMENT**:
• **Line Head**: Primary contact for collections
• **Admin Office**: For account details and queries
• **Emergency**: Contact society management

**💡 PAYMENT TIPS**:
• Pay before due date to avoid late fees
• Keep payment receipts safe
• Update payment in app after paying
• Contact Line Head for any payment issues

**⚠️ IMPORTANT**:
• Always get proper receipt for payments
• Verify payment with Line Head
• Update your payment status in the app

Need help with payment? Contact your Line Head! 📞
""";
    } catch (e) {
      debugPrint('Error generating payment methods: $e');
      return "Sorry, I couldn't retrieve payment methods at this time. Please try again later.";
    }
  }

  /// Handle line head contact requests
  Future<String> _handleLineHeadContact() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to get Line Head contact information.";
      }

      final lineNumber = currentUser.lineNumber;
      if (lineNumber == null) {
        return "Line number not found for your account. Please contact admin.";
      }

      // Get line head information
      final lineHeadInfo = await _dataService.getLineHeadInfo(int.tryParse(lineNumber) ?? 1);

      if (lineHeadInfo == null) {
        return """
📞 Line Head Contact

Hello ${currentUser.name},

Line Head information not available for Line $lineNumber.

**Alternative Contacts**:
• **Society Admin**: Contact main office
• **Management**: Reach out to society management
• **Emergency**: Use society emergency contact

Please contact the admin to update Line Head information.
""";
      }

      return """
📞 Line Head Contact Information

Hello ${currentUser.name},

Here's your Line $lineNumber Head contact details:

**👤 LINE HEAD DETAILS**:
• **Name**: ${lineHeadInfo['name'] ?? 'Not available'}
• **Phone**: ${lineHeadInfo['phone'] ?? 'Not available'}
• **Email**: ${lineHeadInfo['email'] ?? 'Not available'}
• **Line**: Line $lineNumber

**📱 CONTACT OPTIONS**:
• **Call**: Tap to call directly
• **WhatsApp**: Send message via WhatsApp
• **SMS**: Send text message
• **Email**: Send email for detailed queries

**💰 FOR PAYMENTS**:
• Contact for collection schedule
• Arrange payment timing
• Get payment receipts
• Clarify payment amounts

**🏠 FOR SOCIETY MATTERS**:
• Report maintenance issues
• Society announcements
• Community concerns
• Line-specific queries

**⏰ BEST TIME TO CONTACT**:
• Morning: 9 AM - 11 AM
• Evening: 6 PM - 8 PM
• Avoid late night calls
• Respect personal time

**💡 CONTACT TIPS**:
• Be polite and respectful
• State your purpose clearly
• Have your details ready
• Follow up if needed

Your Line Head is here to help! 🤝
""";
    } catch (e) {
      debugPrint('Error getting line head contact: $e');
      return "Sorry, I couldn't retrieve Line Head contact information at this time. Please try again later.";
    }
  }

  /// Handle society rules requests
  Future<String> _handleSocietyRules() async {
    try {
      return """
📋 Society Rules & Guidelines

**🏠 GENERAL SOCIETY RULES**:

**💰 MAINTENANCE PAYMENTS**:
• Pay maintenance by due date each month
• Late fees apply after due date (₹10/day)
• Contact Line Head for payment issues
• Keep payment receipts safe

**🚗 PARKING & VEHICLES**:
• Park only in designated areas
• No blocking of common passages
• Visitor parking in designated spots
• Two-wheeler parking in assigned areas

**🔊 NOISE & DISTURBANCE**:
• Maintain silence after 10 PM
• No loud music or parties without permission
• Construction work only during allowed hours
• Respect neighbors' privacy

**🏗️ CONSTRUCTION & MODIFICATIONS**:
• Get approval before any modifications
• No structural changes without permission
• Balcony modifications need approval
• Maintain building aesthetics

**🚮 CLEANLINESS & HYGIENE**:
• Keep common areas clean
• Dispose garbage properly
• No littering in common areas
• Maintain personal area cleanliness

**👥 COMMUNITY BEHAVIOR**:
• Respect all residents
• No discrimination of any kind
• Help maintain peaceful environment
• Participate in community activities

**🚨 SECURITY MEASURES**:
• Inform security about visitors
• Don't share gate codes/keys
• Report suspicious activities
• Follow visitor registration process

**💧 WATER & UTILITIES**:
• Use water responsibly
• Report leakages immediately
• No wastage of common utilities
• Pay utility bills on time

**🌱 COMMON AREAS**:
• No personal items in common areas
• Maintain garden and landscaping
• Children's play area supervision
• Gym/club house rules compliance

**⚠️ VIOLATIONS & PENALTIES**:
• First warning for minor violations
• Fines for repeated violations
• Serious violations reported to authorities
• Community service for some violations

**📞 COMPLAINT PROCESS**:
• Report to Line Head first
• Use society complaint system
• Escalate to admin if needed
• Follow proper complaint procedure

**🏛️ SOCIETY MEETINGS**:
• Attend monthly society meetings
• Participate in decision making
• Voice concerns appropriately
• Respect majority decisions

**💡 REMEMBER**:
• These rules ensure peaceful living
• Everyone's cooperation is essential
• Rules may be updated periodically
• Ignorance of rules is not an excuse

For detailed rules, contact society management! 📞
""";
    } catch (e) {
      debugPrint('Error generating society rules: $e');
      return "Sorry, I couldn't retrieve society rules at this time. Please try again later.";
    }
  }

  /// Handle complaint status requests
  Future<String> _handleComplaintStatus() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to check your complaint status.";
      }

      // Get user's complaints
      final userComplaints = await _dataService.getUserComplaints();

      if (userComplaints.isEmpty) {
        return """
📝 Complaint Status

Hello ${currentUser.name},

You have no complaints submitted yet.

**📋 TO SUBMIT A COMPLAINT**:
• Use the Complaints section in the app
• Contact your Line Head
• Visit the society office
• Call the management office

**🔍 COMPLAINT CATEGORIES**:
• Maintenance issues
• Noise complaints
• Security concerns
• Facility problems
• Neighbor disputes

**💡 TIPS FOR EFFECTIVE COMPLAINTS**:
• Be specific about the issue
• Provide clear details
• Include photos if relevant
• Follow up appropriately

Need to report an issue? Use the Complaints feature! 📞
""";
      }

      String complaintsText = """
📝 Complaint Status

Hello ${currentUser.name},

Here are your submitted complaints:

""";

      int totalComplaints = userComplaints.length;
      int resolvedComplaints = 0;
      int pendingComplaints = 0;

      for (final complaint in userComplaints.take(10)) {
        // Show last 10 complaints
        final title = complaint['title'] ?? 'No title';
        final status = complaint['status'] ?? 'pending';
        final submittedDate = complaint['submitted_date'] ?? 'Unknown date';
        final category = complaint['category'] ?? 'General';

        if (status.toLowerCase() == 'resolved') {
          resolvedComplaints++;
        } else {
          pendingComplaints++;
        }

        final statusEmoji = status.toLowerCase() == 'resolved' ? '✅' : '⏳';
        final urgencyColor = status.toLowerCase() == 'pending' ? '🔴' : '🟢';

        complaintsText += """
$statusEmoji **$title**
   Category: $category
   Status: ${status.toUpperCase()} $urgencyColor
   Submitted: $submittedDate

""";
      }

      complaintsText += """
📊 **COMPLAINT SUMMARY**:
• Total Complaints: $totalComplaints
• Resolved: $resolvedComplaints ✅
• Pending: $pendingComplaints ⏳
• Resolution Rate: ${totalComplaints > 0 ? ((resolvedComplaints / totalComplaints) * 100).toStringAsFixed(1) : '0'}%

**📞 FOLLOW UP OPTIONS**:
• Contact Line Head for updates
• Visit society office for status
• Call management for urgent issues
• Submit additional details if needed

**💡 COMPLAINT TIPS**:
• Be patient for resolution
• Provide additional info if requested
• Follow up politely
• Rate the resolution when completed

Your concerns matter to us! 🏠
""";

      return complaintsText;
    } catch (e) {
      debugPrint('Error getting complaint status: $e');
      return "Sorry, I couldn't retrieve your complaint status at this time. Please try again later.";
    }
  }

  /// Handle event updates requests
  Future<String> _handleEventUpdates() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to view event updates.";
      }

      // Get upcoming events
      final upcomingEvents = await _dataService.getUpcomingEvents();

      if (upcomingEvents.isEmpty) {
        return """
🎉 Society Events & Updates

Hello ${currentUser.name},

No upcoming events scheduled at the moment.

**📅 STAY UPDATED**:
• Check the Events section regularly
• Follow society announcements
• Join community WhatsApp groups
• Attend monthly society meetings

**🎊 TYPICAL SOCIETY EVENTS**:
• Festival celebrations
• Community gatherings
• Sports tournaments
• Cultural programs
• Maintenance meetings
• Safety workshops

**💡 EVENT PARTICIPATION**:
• Volunteer for event organization
• Suggest new event ideas
• Participate actively
• Help with event coordination

**📞 EVENT INFORMATION**:
• Contact Line Head for details
• Check society notice board
• Follow official announcements
• Ask neighbors about events

Stay connected with your community! 🤝
""";
      }

      String eventsText = """
🎉 Upcoming Society Events

Hello ${currentUser.name},

Here are the upcoming events in our society:

""";

      for (final event in upcomingEvents.take(5)) {
        // Show next 5 events
        final title = event['title'] ?? 'Event';
        final description = event['description'] ?? 'No description';
        final eventDate = event['event_date'] ?? 'Date TBD';
        final location = event['location'] ?? 'Society premises';
        final organizer = event['organizer'] ?? 'Society management';

        eventsText += """
🎊 **$title**
   📅 Date: $eventDate
   📍 Location: $location
   👤 Organizer: $organizer
   📝 Details: $description

""";
      }

      eventsText += """
**📋 EVENT PARTICIPATION**:
• Mark your calendar for events
• RSVP if required
• Volunteer to help organize
• Bring family and friends

**💡 EVENT BENEFITS**:
• Build community connections
• Meet your neighbors
• Enjoy recreational activities
• Strengthen society bonds

**📞 EVENT QUERIES**:
• Contact event organizers
• Ask Line Head for details
• Check society notice board
• Join planning committees

**🎯 UPCOMING HIGHLIGHTS**:
• Community festivals
• Sports competitions
• Cultural programs
• Educational workshops

Join us and make our society vibrant! 🌟
""";

      return eventsText;
    } catch (e) {
      debugPrint('Error getting event updates: $e');
      return "Sorry, I couldn't retrieve event updates at this time. Please try again later.";
    }
  }

  /// Handle expense breakdown requests
  Future<String> _handleExpenseBreakdown() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to view expense breakdown.";
      }

      // Get society expenses
      final expenseData = await _dataService.getSocietyExpenses();

      if (expenseData.isEmpty) {
        return """
💰 Society Expense Breakdown

Hello ${currentUser.name},

No expense data available at the moment.

**📊 TYPICAL SOCIETY EXPENSES**:
• Security services
• Cleaning and maintenance
• Electricity bills
• Water supply charges
• Garden maintenance
• Lift maintenance
• Common area repairs

**💡 EXPENSE TRANSPARENCY**:
• Monthly expense reports
• Detailed breakdowns
• Receipt verification
• Budget planning
• Cost optimization

**📞 FOR EXPENSE QUERIES**:
• Contact society treasurer
• Attend monthly meetings
• Review expense reports
• Ask for detailed breakdowns

Contact admin for detailed expense information! 📞
""";
      }

      String expenseText = """
💰 Society Expense Breakdown

Hello ${currentUser.name},

Here's how your maintenance money is being used:

""";

      double totalExpenses = 0;
      Map<String, double> categoryTotals = {};

      for (final expense in expenseData) {
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
        final category = expense['category'] ?? 'Other';

        totalExpenses += amount;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }

      // Show category-wise breakdown
      expenseText += "**📊 CATEGORY-WISE EXPENSES**:\n\n";

      categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(8).forEach((entry) {
          final percentage = totalExpenses > 0 ? (entry.value / totalExpenses * 100) : 0;
          expenseText +=
              "💸 **${entry.key}**: ₹${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)\n";
        });

      expenseText += """

**💰 TOTAL EXPENSES**: ₹${totalExpenses.toStringAsFixed(2)}

**🔍 RECENT MAJOR EXPENSES**:
""";

      // Show recent major expenses
      final recentExpenses = expenseData.take(5);
      for (final expense in recentExpenses) {
        final description = expense['description'] ?? 'No description';
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
        final date = expense['date'] ?? 'Unknown date';

        expenseText += "• $description - ₹${amount.toStringAsFixed(2)} ($date)\n";
      }

      expenseText += """

**📈 EXPENSE INSIGHTS**:
• Maintenance funds are used transparently
• Regular audits ensure proper utilization
• Cost optimization is continuously pursued
• Emergency funds are maintained

**📋 EXPENSE CATEGORIES**:
• **Security**: Guards, CCTV, access control
• **Utilities**: Electricity, water, internet
• **Maintenance**: Repairs, cleaning, upkeep
• **Administration**: Management, legal, audit
• **Amenities**: Gym, garden, common facilities

**💡 COST OPTIMIZATION**:
• Energy-efficient solutions
• Bulk purchasing benefits
• Preventive maintenance
• Vendor negotiations

**📞 EXPENSE QUERIES**:
• Monthly expense meetings
• Detailed reports available
• Treasurer contact for clarifications
• Audit reports on request

Your maintenance contribution is used wisely! 💪
""";

      return expenseText;
    } catch (e) {
      debugPrint('Error getting expense breakdown: $e');
      return "Sorry, I couldn't retrieve expense breakdown at this time. Please try again later.";
    }
  }

  /// Get AI suggestions based on user role
  Future<List<String>> getAISuggestions() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return [
          "Please log in to get personalized suggestions",
          "How can I help you today?",
          "Ask me about society management"
        ];
      }

      final role = currentUser.role?.toLowerCase() ?? '';

      if (role.contains('admin')) {
        return [
          "Show me financial health report",
          "Generate line wise analysis",
          "Check defaulter analysis",
          "Show collection trends",
          "Society performance report"
        ];
      } else if (role.contains('line')) {
        return [
          "My line collection status",
          "Line reminder for members",
          "Payment reminder",
          "Due date alerts",
          "My line members status"
        ];
      } else {
        return [
          "Payment reminder",
          "Check my dues",
          "Due date alerts",
          "Maintenance history",
          "Late fee calculator",
          "Payment methods",
          "Contact line head",
          "Society rules",
          "Complaint status",
          "Event updates",
          "Expense breakdown"
        ];
      }
    } catch (e) {
      debugPrint('Error getting AI suggestions: $e');
      return ["Payment reminder", "Check my status", "Society information", "Help with payments"];
    }
  }

  /// Get quick action commands based on user role
  Future<List<Map<String, String>>> getQuickActions() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return [];
      }

      final role = currentUser.role?.toLowerCase() ?? '';

      if (role.contains('admin')) {
        return [
          {
            'title': '📊 Financial Health',
            'command': 'Show me financial health report',
            'description': 'Complete society financial overview'
          },
          {
            'title': '📈 Line Analysis',
            'command': 'Generate line wise analysis',
            'description': 'Performance comparison by lines'
          },
          {
            'title': '⚠️ Defaulters',
            'command': 'Check defaulter analysis',
            'description': 'Members with pending payments'
          },
          {
            'title': '📅 Collection Trends',
            'command': 'Show collection trends',
            'description': 'Monthly collection patterns'
          }
        ];
      } else if (role.contains('line')) {
        return [
          {
            'title': '📋 Line Status',
            'command': 'My line collection status',
            'description': 'Your line collection summary'
          },
          {
            'title': '🔔 Line Reminder',
            'command': 'Line reminder for members',
            'description': 'Generate member follow-up list'
          },
          {'title': '💰 Payment Check', 'command': 'Payment reminder', 'description': 'Check your payment status'},
          {'title': '📅 Due Dates', 'command': 'Due date alerts', 'description': 'Upcoming payment deadlines'}
        ];
      } else {
        return [
          {'title': '💰 Payment Reminder', 'command': 'Payment reminder', 'description': 'Check your pending payments'},
          {'title': '📅 Due Dates', 'command': 'Due date alerts', 'description': 'Upcoming payment deadlines'},
          {'title': '📋 Payment History', 'command': 'Maintenance history', 'description': 'View your payment records'},
          {'title': '💳 Payment Methods', 'command': 'Payment methods', 'description': 'How to pay maintenance'},
          {
            'title': '💰 Late Fee Calculator',
            'command': 'Late fee calculator',
            'description': 'Calculate overdue charges'
          },
          {
            'title': '📞 Contact Line Head',
            'command': 'Contact line head',
            'description': 'Get line head contact info'
          },
          {'title': '📋 Society Rules', 'command': 'Society rules', 'description': 'View society guidelines'},
          {'title': '📝 My Complaints', 'command': 'Complaint status', 'description': 'Check complaint status'},
          {'title': '🎉 Events', 'command': 'Event updates', 'description': 'Upcoming society events'},
          {'title': '💸 Expense Breakdown', 'command': 'Expense breakdown', 'description': 'How maintenance is used'}
        ];
      }
    } catch (e) {
      debugPrint('Error getting quick actions: $e');
      return [];
    }
  }
}
