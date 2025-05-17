import 'package:society_management/chat/service/ai_service.dart';

/// A mock implementation of [AIService] for testing purposes.
class MockAIService extends AIService {
  @override
  Future<String> generateResponse(String prompt) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return a mock response based on the prompt
    if (prompt.toLowerCase().contains('maintenance')) {
      return 'Maintenance payments are collected monthly. You can view your payment status in the Maintenance section of the app. If you have any pending payments, please contact your line head.';
    } else if (prompt.toLowerCase().contains('complaint')) {
      return 'You can submit a complaint through the app by going to the Complaints section. Your complaint will be reviewed by the society admin and appropriate action will be taken.';
    } else if (prompt.toLowerCase().contains('event')) {
      return 'Society events are posted in the Events section of the app. You can view upcoming events and their details there.';
    } else if (prompt.toLowerCase().contains('hello') || prompt.toLowerCase().contains('hi')) {
      return 'Hello! I\'m your Society Management Assistant. How can I help you today?';
    } else {
      return 'I\'m here to help with questions about maintenance payments, society events, complaints, and other features of the app. How can I assist you today?';
    }
  }
}
