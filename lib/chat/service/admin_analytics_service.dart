import 'package:flutter/foundation.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/chat/service/society_data_service.dart';
import 'package:society_management/injector/injector.dart';

/// Service for generating admin analytics and dashboard insights
class AdminAnalyticsService {
  final AuthService _authService = getIt<AuthService>();
  final SocietyDataService _dataService = SocietyDataService();

  /// Generate comprehensive society financial health report
  Future<String> generateFinancialHealthReport() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || (!currentUser.role!.toLowerCase().contains('admin'))) {
        return "This feature is only available for Administrators.";
      }

      // Get society-wide data
      final maintenanceInfo = await _dataService.getMaintenanceInfo();
      final societyData = maintenanceInfo['societyMaintenanceData'] as Map<String, dynamic>? ?? {};
      final stats = await _dataService.getSocietyStats();

      final totalCollected = (societyData['totalCollected'] as num?)?.toDouble() ?? 0;
      final totalPending = (societyData['totalPending'] as num?)?.toDouble() ?? 0;
      final fullyPaidCount = (societyData['fullyPaidCount'] as num?)?.toInt() ?? 0;
      final pendingCount = (societyData['pendingCount'] as num?)?.toInt() ?? 0;
      final totalMembers = (societyData['totalMembers'] as num?)?.toInt() ?? 0;

      final totalExpenses = (stats['totalExpenses'] as num?)?.toDouble() ?? 0;
      final activePeriods = (stats['activeMaintenancePeriods'] as num?)?.toInt() ?? 0;

      // Calculate financial health metrics
      final collectionRate = totalMembers > 0 ? (fullyPaidCount / totalMembers * 100) : 0;
      final netIncome = totalCollected - totalExpenses;
      final avgCollectionPerMember = totalMembers > 0 ? totalCollected / totalMembers : 0;
      final avgPendingPerMember = pendingCount > 0 ? totalPending / pendingCount : 0;

      // Determine financial health status
      String healthStatus = "";
      String healthEmoji = "";

      if (collectionRate >= 90 && netIncome > 0) {
        healthStatus = "EXCELLENT";
        healthEmoji = "🟢";
      } else if (collectionRate >= 75 && netIncome >= 0) {
        healthStatus = "GOOD";
        healthEmoji = "🟡";
      } else if (collectionRate >= 60) {
        healthStatus = "FAIR";
        healthEmoji = "🟠";
      } else {
        healthStatus = "NEEDS ATTENTION";
        healthEmoji = "🔴";
      }

      return """
📊 Society Financial Health Report

Hello ${currentUser.name},

**$healthEmoji OVERALL HEALTH: $healthStatus**

**💰 FINANCIAL OVERVIEW**:
• Total Collected: ₹${totalCollected.toStringAsFixed(2)}
• Total Pending: ₹${totalPending.toStringAsFixed(2)}
• Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}
• Net Income: ₹${netIncome.toStringAsFixed(2)} ${netIncome >= 0 ? '✅' : '⚠️'}

**👥 MEMBER STATISTICS**:
• Total Members: $totalMembers
• Fully Paid: $fullyPaidCount (${collectionRate.toStringAsFixed(1)}%)
• Pending Payments: $pendingCount
• Active Periods: $activePeriods

**📈 KEY METRICS**:
• Collection Rate: ${collectionRate.toStringAsFixed(1)}%
• Avg Collection/Member: ₹${avgCollectionPerMember.toStringAsFixed(2)}
• Avg Pending/Member: ₹${avgPendingPerMember.toStringAsFixed(2)}

**💡 INSIGHTS**:
${_generateFinancialInsights(collectionRate.toDouble(), netIncome.toDouble(), pendingCount, totalMembers)}

**🎯 RECOMMENDATIONS**:
${_generateFinancialRecommendations(collectionRate.toDouble(), netIncome.toDouble(), pendingCount)}

Generated on: ${DateTime.now().toString().split('.')[0]}
""";
    } catch (e) {
      debugPrint('Error generating financial health report: $e');
      return "Sorry, I couldn't generate the financial health report at this time. Please try again later.";
    }
  }

  /// Generate line-wise collection analysis
  Future<String> generateLineWiseAnalysis() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || (!currentUser.role!.toLowerCase().contains('admin'))) {
        return "This feature is only available for Administrators.";
      }

      // Get society-wide data with line breakdown
      final maintenanceInfo = await _dataService.getMaintenanceInfo();
      final societyData = maintenanceInfo['societyMaintenanceData'] as Map<String, dynamic>? ?? {};
      final lineWiseData = societyData['lineWiseData'] as Map<String, dynamic>? ?? {};

      if (lineWiseData.isEmpty) {
        return """
📊 Line-wise Analysis

No line-wise data available at this time.
This could mean:
• No maintenance payments have been recorded yet
• Data is still being processed
• All members are in the same line

Please check back later or contact technical support.
""";
      }

      // Sort lines by collection rate
      final sortedLines = lineWiseData.entries.toList()
        ..sort((a, b) {
          final aTotal = (a.value['fullyPaid'] as num?)?.toInt() ?? 0;
          final aPending = (a.value['pendingMembers'] as num?)?.toInt() ?? 0;
          final aRate = (aTotal + aPending) > 0 ? (aTotal / (aTotal + aPending)) : 0;

          final bTotal = (b.value['fullyPaid'] as num?)?.toInt() ?? 0;
          final bPending = (b.value['pendingMembers'] as num?)?.toInt() ?? 0;
          final bRate = (bTotal + bPending) > 0 ? (bTotal / (bTotal + bPending)) : 0;

          return bRate.compareTo(aRate);
        });

      String analysis = """
📊 Line-wise Collection Analysis

Hello ${currentUser.name},

**🏆 PERFORMANCE RANKING**:

""";

      int rank = 1;
      String bestPerformer = "";
      String needsAttention = "";

      for (final entry in sortedLines) {
        final lineName = entry.key;
        final data = entry.value as Map<String, dynamic>;

        final collected = (data['collected'] as num?)?.toDouble() ?? 0;
        final pending = (data['pending'] as num?)?.toDouble() ?? 0;
        final fullyPaid = (data['fullyPaid'] as num?)?.toInt() ?? 0;
        final pendingMembers = (data['pendingMembers'] as num?)?.toInt() ?? 0;
        final totalMembers = fullyPaid + pendingMembers;
        final collectionRate = totalMembers > 0 ? (fullyPaid / totalMembers * 100) : 0;

        String emoji = "";
        if (rank == 1) {
          emoji = "🥇";
          bestPerformer = lineName;
        } else if (rank == 2) {
          emoji = "🥈";
        } else if (rank == 3) {
          emoji = "🥉";
        } else {
          emoji = "📍";
        }

        if (collectionRate < 60) {
          needsAttention = lineName;
        }

        analysis += """
$emoji **$lineName** (${collectionRate.toStringAsFixed(1)}%)
   • Collected: ₹${collected.toStringAsFixed(2)}
   • Pending: ₹${pending.toStringAsFixed(2)}
   • Members: $fullyPaid paid, $pendingMembers pending

""";
        rank++;
      }

      analysis += """
**🎯 KEY INSIGHTS**:
• Best Performer: $bestPerformer 🏆
${needsAttention.isNotEmpty ? '• Needs Attention: $needsAttention ⚠️' : '• All lines performing well! ✅'}
• Total Lines: ${sortedLines.length}

**💡 RECOMMENDATIONS**:
${_generateLineWiseRecommendations(sortedLines)}

Generated on: ${DateTime.now().toString().split('.')[0]}
""";

      return analysis;
    } catch (e) {
      debugPrint('Error generating line-wise analysis: $e');
      return "Sorry, I couldn't generate the line-wise analysis at this time. Please try again later.";
    }
  }

  /// Generate monthly collection trends
  Future<String> generateCollectionTrends() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || (!currentUser.role!.toLowerCase().contains('admin'))) {
        return "This feature is only available for Administrators.";
      }

      // Get current month data
      final maintenanceInfo = await _dataService.getMaintenanceInfo();
      final societyData = maintenanceInfo['societyMaintenanceData'] as Map<String, dynamic>? ?? {};
      final activePeriods = maintenanceInfo['activePeriods'] as List? ?? [];

      final totalCollected = (societyData['totalCollected'] as num?)?.toDouble() ?? 0;
      final totalPending = (societyData['totalPending'] as num?)?.toDouble() ?? 0;
      final fullyPaidCount = (societyData['fullyPaidCount'] as num?)?.toInt() ?? 0;
      final totalMembers = (societyData['totalMembers'] as num?)?.toInt() ?? 0;

      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      return """
📈 Collection Trends Analysis

Hello ${currentUser.name},

**📅 CURRENT MONTH (${monthNames[currentMonth - 1]} $currentYear)**:

**💰 COLLECTION SUMMARY**:
• Total Collected: ₹${totalCollected.toStringAsFixed(2)}
• Total Pending: ₹${totalPending.toStringAsFixed(2)}
• Collection Rate: ${totalMembers > 0 ? (fullyPaidCount / totalMembers * 100).toStringAsFixed(1) : 0}%

**📊 ACTIVE PERIODS**: ${activePeriods.length}
${activePeriods.take(3).map((period) => "• ${period['name']} - Due: ${period['due_date']?.toString().split(' ')[0] ?? 'N/A'}").join('\n')}

**🎯 PERFORMANCE INDICATORS**:
${_generatePerformanceIndicators(totalCollected, totalPending, fullyPaidCount, totalMembers)}

**📈 TREND ANALYSIS**:
${_generateTrendAnalysis(totalCollected, totalPending, fullyPaidCount, totalMembers)}

**💡 ACTIONABLE INSIGHTS**:
${_generateActionableInsights(totalCollected, totalPending, fullyPaidCount, totalMembers)}

Generated on: ${DateTime.now().toString().split('.')[0]}
""";
    } catch (e) {
      debugPrint('Error generating collection trends: $e');
      return "Sorry, I couldn't generate collection trends at this time. Please try again later.";
    }
  }

  /// Generate defaulter analysis for admin
  Future<String> generateDefaulterAnalysis() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || (!currentUser.role!.toLowerCase().contains('admin'))) {
        return "This feature is only available for Administrators.";
      }

      // Get all members data
      final lineMembers = await _dataService.getLineMembers();
      final members = lineMembers['members'] as List? ?? [];

      // Filter members with pending payments
      final defaulters = members.where((member) {
        final pendingPayments = (member['pendingPayments'] as num?)?.toInt() ?? 0;
        return pendingPayments > 0;
      }).toList();

      if (defaulters.isEmpty) {
        return """
🎉 Excellent News!

Hello ${currentUser.name},

**NO DEFAULTERS FOUND!** 🏆

All society members are current with their maintenance payments.
This is an outstanding achievement for the society management!

**📊 CURRENT STATUS**:
• Total Members: ${members.length}
• All Paid: ${members.length} ✅
• Defaulters: 0 🎯

Keep up the excellent work! 👏
""";
      }

      // Sort defaulters by pending amount (highest first)
      defaulters.sort((a, b) {
        final aPending = (a['totalPending'] as num?)?.toDouble() ?? 0;
        final bPending = (b['totalPending'] as num?)?.toDouble() ?? 0;
        return bPending.compareTo(aPending);
      });

      // Calculate statistics
      final totalDefaulterAmount =
          defaulters.fold<double>(0, (sum, member) => sum + ((member['totalPending'] as num?)?.toDouble() ?? 0));
      final avgDefaulterAmount = defaulters.isNotEmpty ? totalDefaulterAmount / defaulters.length : 0;

      // Categorize defaulters
      final highRisk = defaulters.where((m) {
        final pending = (m['totalPending'] as num?)?.toDouble() ?? 0;
        return pending > 5000;
      }).toList();
      final mediumRisk = defaulters.where((m) {
        final pending = (m['totalPending'] as num?)?.toDouble() ?? 0;
        return pending >= 2000 && pending <= 5000;
      }).toList();
      final lowRisk = defaulters.where((m) {
        final pending = (m['totalPending'] as num?)?.toDouble() ?? 0;
        return pending < 2000;
      }).toList();

      return """
⚠️ Defaulter Analysis Report

Hello ${currentUser.name},

**📊 DEFAULTER OVERVIEW**:
• Total Defaulters: ${defaulters.length}
• Total Outstanding: ₹${totalDefaulterAmount.toStringAsFixed(2)}
• Average per Defaulter: ₹${avgDefaulterAmount.toStringAsFixed(2)}

**🚨 RISK CATEGORIES**:

**HIGH RISK (>₹5,000)**: ${highRisk.length} members
${highRisk.take(3).map((m) => "• ${m['name']} (${m['lineNumber']}) - ₹${(m['totalPending'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}").join('\n')}
${highRisk.length > 3 ? '• ... and ${highRisk.length - 3} more' : ''}

**MEDIUM RISK (₹2,000-₹5,000)**: ${mediumRisk.length} members
${mediumRisk.take(3).map((m) => "• ${m['name']} (${m['lineNumber']}) - ₹${(m['totalPending'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}").join('\n')}
${mediumRisk.length > 3 ? '• ... and ${mediumRisk.length - 3} more' : ''}

**LOW RISK (<₹2,000)**: ${lowRisk.length} members

**💡 RECOMMENDED ACTIONS**:
${_generateDefaulterRecommendations(highRisk.length, mediumRisk.length, lowRisk.length)}

**📞 IMMEDIATE FOLLOW-UP NEEDED**:
${highRisk.take(5).map((m) => "• Contact ${m['name']} (${m['lineNumber']}) - ₹${(m['totalPending'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'} pending").join('\n')}

Generated on: ${DateTime.now().toString().split('.')[0]}
""";
    } catch (e) {
      debugPrint('Error generating defaulter analysis: $e');
      return "Sorry, I couldn't generate defaulter analysis at this time. Please try again later.";
    }
  }

  // Helper methods for generating insights and recommendations
  String _generateFinancialInsights(double collectionRate, double netIncome, int pendingCount, int totalMembers) {
    List<String> insights = [];

    if (collectionRate >= 90) {
      insights.add("• Excellent collection rate! Society is financially stable.");
    } else if (collectionRate >= 75) {
      insights.add("• Good collection rate, but room for improvement.");
    } else {
      insights.add("• Collection rate needs attention. Focus on pending payments.");
    }

    if (netIncome > 0) {
      insights.add("• Positive cash flow indicates healthy financial management.");
    } else {
      insights.add("• Negative cash flow requires immediate attention.");
    }

    if (pendingCount > totalMembers * 0.3) {
      insights.add("• High number of pending payments may impact society operations.");
    }

    return insights.join('\n');
  }

  String _generateFinancialRecommendations(double collectionRate, double netIncome, int pendingCount) {
    List<String> recommendations = [];

    if (collectionRate < 80) {
      recommendations.add("• Implement automated payment reminders");
      recommendations.add("• Consider payment plans for high defaulters");
    }

    if (netIncome < 0) {
      recommendations.add("• Review and optimize society expenses");
      recommendations.add("• Consider adjusting maintenance amounts");
    }

    if (pendingCount > 10) {
      recommendations.add("• Organize collection drives");
      recommendations.add("• Engage line heads for better collection");
    }

    recommendations.add("• Regular financial health monitoring");

    return recommendations.join('\n');
  }

  String _generateLineWiseRecommendations(List<MapEntry<String, dynamic>> sortedLines) {
    if (sortedLines.isEmpty) return "• No specific recommendations available.";

    List<String> recommendations = [];

    // Check if there's a significant performance gap
    if (sortedLines.length > 1) {
      final bestLine = sortedLines.first;
      final worstLine = sortedLines.last;

      final bestData = bestLine.value as Map<String, dynamic>;
      final worstData = worstLine.value as Map<String, dynamic>;

      final bestRate = _calculateCollectionRate(bestData);
      final worstRate = _calculateCollectionRate(worstData);

      if (bestRate - worstRate > 20) {
        recommendations.add("• Share best practices from ${bestLine.key} with other lines");
        recommendations.add("• Provide additional support to ${worstLine.key}");
      }
    }

    recommendations.add("• Recognize top-performing line heads");
    recommendations.add("• Organize inter-line collection competitions");

    return recommendations.join('\n');
  }

  double _calculateCollectionRate(Map<String, dynamic> data) {
    final fullyPaid = (data['fullyPaid'] as num?)?.toInt() ?? 0;
    final pendingMembers = (data['pendingMembers'] as num?)?.toInt() ?? 0;
    final totalMembers = fullyPaid + pendingMembers;
    return totalMembers > 0 ? (fullyPaid / totalMembers * 100) : 0;
  }

  String _generatePerformanceIndicators(double collected, double pending, int paid, int total) {
    List<String> indicators = [];

    final collectionRate = total > 0 ? (paid / total * 100) : 0;

    if (collectionRate >= 90) {
      indicators.add("🟢 Collection Rate: Excellent");
    } else if (collectionRate >= 75) {
      indicators.add("🟡 Collection Rate: Good");
    } else {
      indicators.add("🔴 Collection Rate: Needs Improvement");
    }

    if (pending < collected * 0.1) {
      indicators.add("🟢 Pending Amount: Low");
    } else if (pending < collected * 0.3) {
      indicators.add("🟡 Pending Amount: Moderate");
    } else {
      indicators.add("🔴 Pending Amount: High");
    }

    return indicators.join('\n');
  }

  String _generateTrendAnalysis(double collected, double pending, int paid, int total) {
    // This is a simplified trend analysis. In a real implementation,
    // you would compare with historical data
    return """
• Current month showing ${total > 0 ? (paid / total * 100).toStringAsFixed(1) : 0}% collection rate
• Total outstanding amount: ₹${pending.toStringAsFixed(2)}
• Collection efficiency appears ${pending < collected * 0.2 ? 'strong' : 'moderate'}
""";
  }

  String _generateActionableInsights(double collected, double pending, int paid, int total) {
    List<String> insights = [];

    if (pending > collected * 0.3) {
      insights.add("• Focus on reducing pending amounts through targeted collection drives");
    }

    if (total > 0 && paid / total < 0.8) {
      insights.add("• Implement stricter payment follow-up procedures");
    }

    insights.add("• Consider digital payment options to improve collection efficiency");
    insights.add("• Regular communication with line heads for better coordination");

    return insights.join('\n');
  }

  String _generateDefaulterRecommendations(int highRisk, int mediumRisk, int lowRisk) {
    List<String> recommendations = [];

    if (highRisk > 0) {
      recommendations.add("• Immediate personal meetings with high-risk defaulters");
      recommendations.add("• Consider payment plans for high outstanding amounts");
    }

    if (mediumRisk > 0) {
      recommendations.add("• Send formal notices to medium-risk defaulters");
      recommendations.add("• Engage line heads for collection assistance");
    }

    if (lowRisk > 0) {
      recommendations.add("• Automated reminders for low-risk defaulters");
    }

    recommendations.add("• Implement late fee policy consistently");
    recommendations.add("• Regular defaulter review meetings");

    return recommendations.join('\n');
  }
}
