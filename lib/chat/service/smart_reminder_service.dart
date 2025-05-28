import 'package:flutter/foundation.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/chat/service/society_data_service.dart';
import 'package:society_management/injector/injector.dart';

/// Service for generating smart payment reminders and alerts
class SmartReminderService {
  final AuthService _authService = getIt<AuthService>();
  final SocietyDataService _dataService = SocietyDataService();

  /// Generate personalized payment reminder message
  Future<String> generatePaymentReminder() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to check your payment status.";
      }

      // Get user's pending payments
      final pendingPayments = await _dataService.getUserPendingPaymentsList();
      final userInfo = await _dataService.getCurrentUserInfo();

      if (pendingPayments.isEmpty) {
        return """
🎉 Great news, ${currentUser.name}!

You're all caught up with your maintenance payments!
✅ No pending payments
✅ All maintenance periods are paid

Keep up the excellent payment record! 👏
""";
      }

      // Calculate total pending amount
      double totalPending = 0;
      int pendingCount = 0;
      List<String> pendingPeriods = [];

      for (final payment in pendingPayments) {
        if (payment['status'] != 'paid') {
          final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
          final amountPaid = (payment['amount_paid'] as num?)?.toDouble() ?? 0;
          final pendingAmount = amount - amountPaid;

          if (pendingAmount > 0) {
            totalPending += pendingAmount;
            pendingCount++;
            pendingPeriods.add(payment['period_name'] ?? 'Unknown Period');
          }
        }
      }

      if (pendingCount == 0) {
        return """
🎉 Excellent, ${currentUser.name}!

All your maintenance payments are up to date!
✅ No pending amounts
✅ Payment status: Current

Thank you for being a responsible society member! 🏠
""";
      }

      // Generate reminder based on pending amount
      String urgencyLevel = "";
      String emoji = "";

      if (totalPending > 5000) {
        urgencyLevel = "URGENT";
        emoji = "🚨";
      } else if (totalPending > 2000) {
        urgencyLevel = "Important";
        emoji = "⚠️";
      } else {
        urgencyLevel = "Reminder";
        emoji = "💡";
      }

      return """
$emoji $urgencyLevel Payment Reminder

Hello ${currentUser.name},

You have pending maintenance payments:

💰 **Total Pending**: ₹${totalPending.toStringAsFixed(2)}
📋 **Pending Periods**: $pendingCount
📅 **Periods**: ${pendingPeriods.take(3).join(', ')}${pendingPeriods.length > 3 ? '...' : ''}

${_getPaymentAdvice(totalPending, pendingCount)}

💳 **Payment Options**:
• Contact your Line Head
• Visit the Maintenance section in app
• Make payment through society office

${_getLateFeeWarning(pendingCount)}

Thank you for your cooperation! 🏠
""";
    } catch (e) {
      debugPrint('Error generating payment reminder: $e');
      return "Sorry, I couldn't generate your payment reminder at this time. Please try again later.";
    }
  }

  /// Generate due date alerts
  Future<String> generateDueDateAlert() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return "Please log in to check due dates.";
      }

      // Get active maintenance periods
      final maintenanceInfo = await _dataService.getMaintenanceInfo();
      final activePeriods = maintenanceInfo['activePeriods'] as List? ?? [];

      if (activePeriods.isEmpty) {
        return """
📅 No Active Maintenance Periods

Hello ${currentUser.name},

Currently, there are no active maintenance periods with upcoming due dates.

Stay tuned for announcements about new maintenance periods! 📢
""";
      }

      List<String> upcomingDueDates = [];
      List<String> overduePeriods = [];

      final now = DateTime.now();

      for (final period in activePeriods) {
        final dueDateStr = period['due_date'] as String?;
        if (dueDateStr != null) {
          try {
            final dueDate = DateTime.parse(dueDateStr);
            final daysUntilDue = dueDate.difference(now).inDays;

            if (daysUntilDue < 0) {
              overduePeriods.add("${period['name']} (${(-daysUntilDue)} days overdue)");
            } else if (daysUntilDue <= 7) {
              upcomingDueDates.add("${period['name']} ($daysUntilDue days left)");
            }
          } catch (e) {
            debugPrint('Error parsing due date: $e');
          }
        }
      }

      if (upcomingDueDates.isEmpty && overduePeriods.isEmpty) {
        return """
✅ All Good with Due Dates!

Hello ${currentUser.name},

No immediate due dates approaching. All your maintenance periods are either:
• Already paid ✅
• Due dates are more than a week away 📅

Keep up the good work! 👏
""";
      }

      String alertMessage = "📅 Due Date Alert\n\nHello ${currentUser.name},\n\n";

      if (overduePeriods.isNotEmpty) {
        alertMessage += "🚨 **OVERDUE PAYMENTS**:\n";
        for (final overdue in overduePeriods) {
          alertMessage += "• $overdue\n";
        }
        alertMessage += "\n";
      }

      if (upcomingDueDates.isNotEmpty) {
        alertMessage += "⏰ **UPCOMING DUE DATES**:\n";
        for (final upcoming in upcomingDueDates) {
          alertMessage += "• $upcoming\n";
        }
        alertMessage += "\n";
      }

      alertMessage += """
💡 **Action Required**:
• Make payments before due dates
• Contact your Line Head for assistance
• Check the Maintenance section for details

Avoid late fees by paying on time! 💰
""";

      return alertMessage;
    } catch (e) {
      debugPrint('Error generating due date alert: $e');
      return "Sorry, I couldn't check due dates at this time. Please try again later.";
    }
  }

  /// Generate line-specific reminders for line heads
  Future<String> generateLineReminderForLineHead() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || !currentUser.role!.toLowerCase().contains('line')) {
        return "This feature is only available for Line Heads.";
      }

      final lineNumber = currentUser.lineNumber;
      if (lineNumber == null) {
        return "Line number not found for your account.";
      }

      // Get line maintenance data
      final maintenanceInfo = await _dataService.getMaintenanceInfo();
      final lineData = maintenanceInfo['lineMaintenanceData'] as Map<String, dynamic>? ?? {};

      final totalCollected = (lineData['totalCollected'] as num?)?.toDouble() ?? 0;
      final totalPending = (lineData['totalPending'] as num?)?.toDouble() ?? 0;
      final fullyPaidCount = (lineData['fullyPaidCount'] as num?)?.toInt() ?? 0;
      final pendingCount = (lineData['pendingCount'] as num?)?.toInt() ?? 0;
      final totalMembers = (lineData['totalMembers'] as num?)?.toInt() ?? 0;
      final collectionPercentage = (lineData['collectionPercentage'] as num?)?.toDouble() ?? 0;

      // Get line members with pending payments
      final lineMembers = await _dataService.getLineMembers();
      final members = lineMembers['members'] as List? ?? [];
      final pendingMembers = members.where((member) {
        final pendingPayments = (member['pendingPayments'] as num?)?.toInt() ?? 0;
        return pendingPayments > 0;
      }).toList();

      return """
📊 Line Head Collection Summary

Hello ${currentUser.name},

Here's your Line $lineNumber collection status:

**📈 COLLECTION STATS**:
• Total Collected: ₹${totalCollected.toStringAsFixed(2)}
• Total Pending: ₹${totalPending.toStringAsFixed(2)}
• Collection Rate: ${collectionPercentage.toStringAsFixed(1)}%

**👥 MEMBER STATUS**:
• Total Members: $totalMembers
• Fully Paid: $fullyPaidCount ✅
• Pending Payments: $pendingCount ⏳

${pendingCount > 0 ? """
**🔔 MEMBERS NEEDING FOLLOW-UP**:
${pendingMembers.take(5).map((member) => "• ${member['name']} - ₹${(member['totalPending'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'} pending").join('\n')}
${pendingMembers.length > 5 ? '\n• ... and ${pendingMembers.length - 5} more members' : ''}

**💡 SUGGESTED ACTIONS**:
• Send payment reminders to pending members
• Schedule collection visits
• Contact members with high pending amounts
• Update payment records after collection
""" : """
🎉 **EXCELLENT WORK!**
All members in your line have completed their payments!
"""}

Keep up the great work as Line Head! 👏
""";
    } catch (e) {
      debugPrint('Error generating line reminder: $e');
      return "Sorry, I couldn't generate line reminder at this time. Please try again later.";
    }
  }

  /// Get payment advice based on amount and count
  String _getPaymentAdvice(double amount, int count) {
    if (amount > 5000) {
      return "⚠️ **High pending amount detected!** Please prioritize these payments to avoid additional late fees.";
    } else if (count > 3) {
      return "📋 **Multiple pending periods.** Consider making partial payments to reduce the burden.";
    } else {
      return "💡 **Quick action needed.** A small payment now can keep you current with society dues.";
    }
  }

  /// Get late fee warning
  String _getLateFeeWarning(int pendingCount) {
    if (pendingCount > 2) {
      return "⚠️ **Late Fee Alert**: Multiple overdue payments may incur additional charges.";
    } else {
      return "💡 **Tip**: Pay before due date to avoid late fees.";
    }
  }
}
