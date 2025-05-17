import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:society_management/chat/service/ai_service.dart';
import 'package:society_management/chat/service/society_data_service.dart';
import 'package:society_management/injector/injector.dart';

/// Service that uses AI to analyze society data and provide insights
class SocietyAIService {
  final AIService _aiService = getIt<AIService>();
  final SocietyDataService _dataService = SocietyDataService();

  /// Get AI-generated insights about the society
  Future<String> getSocietyInsights() async {
    try {
      // Fetch all society data
      final societyData = await _dataService.getAllSocietyData();

      // Convert data to JSON string
      final dataJson = jsonEncode(societyData);

      // Create prompt for the AI
      final prompt = '''
You are an AI assistant for a Society Management app. I will provide you with data about the society, and I need you to analyze it and provide insights.

Here is the data:
$dataJson

Based on this data, please provide the following information in a clear, organized format:
1. A greeting addressing the current user by name
2. Summary of the society's financial status (total members, maintenance collected, pending amounts)
3. Information about the user's pending payments, if any
4. Any active maintenance periods and their due dates
5. Recommendations or next steps for the user based on their role and pending payments

Format your response in a friendly, helpful manner. Use bullet points and clear sections.
''';

      // Get AI response
      final response = await _aiService.generateResponse(prompt);
      return response;
    } catch (e) {
      debugPrint('Error getting society insights: $e');
      return "Sorry, I couldn't analyze the society data at this time. Please try again later.";
    }
  }

  /// Get information about the current user
  Future<String> getCurrentUserInfo() async {
    try {
      // Fetch current user data
      final userData = await _dataService.getCurrentUserInfo();

      // Convert data to JSON string
      final dataJson = jsonEncode(userData);

      // Create prompt for the AI
      final prompt = '''
You are an AI assistant for a Society Management app. I will provide you with data about the current user, and I need you to summarize it.

Here is the user data:
$dataJson

Based on this data, please provide a summary of the user's information in a clear, friendly format. Include their name, role, line number, villa number, and any other relevant details.
''';

      // Get AI response
      final response = await _aiService.generateResponse(prompt);
      return response;
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return "Sorry, I couldn't retrieve your information at this time. Please try again later.";
    }
  }

  /// Get information about pending maintenance payments
  Future<String> getPendingPaymentsInfo() async {
    try {
      // Fetch pending payments data
      final paymentsData = await _dataService.getUserPendingPayments();
      final userData = await _dataService.getCurrentUserInfo();

      // Convert data to JSON string
      final dataJson = jsonEncode({
        'user': userData,
        'pendingPayments': paymentsData,
      });

      // Create prompt for the AI
      final prompt = '''
You are an AI assistant for a Society Management app. I will provide you with data about the user's pending maintenance payments, and I need you to summarize it.

Here is the data:
$dataJson

Based on this data, please provide a summary of the pending payments in a clear, organized format. Include:
1. Total amount due
2. List of pending payments with period names, amounts, and due dates
3. Recommendations for payment

If there are no pending payments, please mention that the user is up to date with all payments.
''';

      // Get AI response
      final response = await _aiService.generateResponse(prompt);
      return response;
    } catch (e) {
      debugPrint('Error getting pending payments info: $e');
      return "Sorry, I couldn't retrieve information about your pending payments at this time. Please try again later.";
    }
  }

  /// Get information about society statistics
  Future<String> getSocietyStatsInfo() async {
    try {
      // Fetch society stats data
      final statsData = await _dataService.getSocietyStats();

      // Convert data to JSON string
      final dataJson = jsonEncode(statsData);

      // Create prompt for the AI
      final prompt = '''
You are an AI assistant for a Society Management app. I will provide you with statistics about the society, and I need you to summarize it.

Here is the data:
$dataJson

Based on this data, please provide a summary of the society's statistics in a clear, organized format. Include:
1. Total number of members
2. Total expenses
3. Maintenance collected and pending
4. Number of active maintenance periods
5. Any other relevant insights

Format your response in a friendly, informative manner.
''';

      // Get AI response
      final response = await _aiService.generateResponse(prompt);
      return response;
    } catch (e) {
      debugPrint('Error getting society stats info: $e');
      return "Sorry, I couldn't retrieve society statistics at this time. Please try again later.";
    }
  }
}
